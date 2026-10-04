const nodemailer = require('nodemailer');
const mongoose = require('mongoose');
const EmailVerification = require('../models/EmailVerification');
const logger = require('../utils/logger');

// In-memory fallback map for offline / dev mode
const memoryStore = new Map();

/**
 * Create nodemailer transporter
 */
function createTransporter() {
  const user = process.env.GMAIL_USER || process.env.EMAIL_USER || process.env.SMTP_USER;
  const pass = process.env.GMAIL_APP_PASSWORD || process.env.EMAIL_PASS || process.env.SMTP_PASS;

  if (user && pass) {
    return nodemailer.createTransport({
      service: 'gmail',
      auth: { user, pass },
    });
  }

  // Check custom host/port if provided
  if (process.env.SMTP_HOST && user && pass) {
    return nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: Number(process.env.SMTP_PORT) || 587,
      secure: Number(process.env.SMTP_PORT) === 465,
      auth: { user, pass },
    });
  }

  return null;
}

function normalizeEmailAddress(email) {
  if (!email || typeof email !== 'string') return '';
  const trimmed = email.trim().toLowerCase();
  const atIndex = trimmed.lastIndexOf('@');
  if (atIndex === -1) return trimmed;
  const local = trimmed.substring(0, atIndex);
  const domain = trimmed.substring(atIndex + 1);
  if (domain === 'gmail.com' || domain === 'googlemail.com') {
    const cleanLocal = local.replace(/\./g, '').split('+')[0];
    return `${cleanLocal}@gmail.com`;
  }
  return trimmed;
}

/**
 * Generate 6-digit numeric verification code
 */
function generateVerificationCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

/**
 * Send Gmail verification code to user
 * @param {string} email
 * @param {string} name
 * @returns {Promise<{ success: boolean, code?: string, mode: string }>}
 */
async function sendVerificationCode(email, name = 'there') {
  const cleanEmail = normalizeEmailAddress(email);
  const code = generateVerificationCode();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

  // 1. Store in memory fallback
  memoryStore.set(cleanEmail, { code, expiresAt, verified: false });

  // 2. Store in MongoDB if connected
  if (mongoose.connection.readyState === 1) {
    try {
      // Upsert verification record for this email
      await EmailVerification.deleteMany({ email: cleanEmail });
      await EmailVerification.create({
        email: cleanEmail,
        code,
        expiresAt,
        verified: false,
      });
    } catch (err) {
      logger.error('Failed to store verification code in MongoDB:', err);
    }
  }

  // 3. Send email via Gmail transporter if credentials configured
  const transporter = createTransporter();
  let emailSent = false;

  const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>LittleHands Verification Code</title>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #F8F5F0; margin: 0; padding: 24px; color: #1E293B; }
        .card { max-width: 520px; margin: 0 auto; background: #ffffff; border-radius: 20px; overflow: hidden; box-shadow: 0 4px 16px rgba(0,0,0,0.06); }
        .header { background: linear-gradient(135deg, #005B60 0%, #00828A 100%); padding: 32px 24px; text-align: center; color: #ffffff; }
        .brand { font-size: 26px; font-weight: 800; letter-spacing: -0.5px; margin: 0; }
        .brand-accent { color: #A7F3D0; }
        .sub { font-size: 13px; color: #E6F5F2; margin-top: 6px; }
        .content { padding: 32px 28px; }
        .greeting { font-size: 18px; font-weight: 700; color: #0F172A; margin-bottom: 12px; }
        .lead { font-size: 14.5px; color: #64748B; line-height: 1.6; margin-bottom: 24px; }
        .otp-container { background: #F0FDF4; border: 2px dashed #10B981; border-radius: 16px; padding: 20px; text-align: center; margin: 24px 0; }
        .otp-label { font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: 1px; color: #047857; margin-bottom: 8px; }
        .otp-code { font-size: 38px; font-weight: 800; letter-spacing: 8px; color: #065F46; font-family: 'Courier New', monospace; }
        .expiry-note { font-size: 12px; color: #64748B; margin-top: 8px; }
        .security-badge { display: flex; align-items: center; background: #FFFBEB; border: 1px solid #FDE68A; border-radius: 12px; padding: 12px 16px; margin: 20px 0; font-size: 12.5px; color: #92400E; }
        .footer { background: #F8FAFC; border-top: 1px solid #E2E8F0; padding: 20px 28px; text-align: center; font-size: 12px; color: #94A3B8; }
      </style>
    </head>
    <body>
      <div class="card">
        <div class="header">
          <h1 class="brand">LittleHands<span class="brand-accent">•</span></h1>
          <p class="sub">Verified Childcare & Babysitting • Sri Lanka</p>
        </div>
        <div class="content">
          <div class="greeting">Hello ${name},</div>
          <p class="lead">
            Thank you for creating an account with LittleHands! Please enter the 6-digit Gmail verification code below to verify your email address and activate your account.
          </p>

          <div class="otp-container">
            <div class="otp-label">Your Verification Code</div>
            <div class="otp-code">${code}</div>
            <div class="expiry-note">⏱️ Expires in 10 minutes</div>
          </div>

          <div class="security-badge">
            🔒 <strong>Security Notice:</strong> Never share this code with anyone. LittleHands team members will never ask for your verification code.
          </div>
        </div>
        <div class="footer">
          <p style="margin: 0 0 6px 0;">LittleHands Sri Lanka • Colombo, Western Province</p>
          <p style="margin: 0;">Empowering working parents with safe, verified care.</p>
        </div>
      </div>
    </body>
    </html>
  `;

  if (transporter) {
    try {
      const sender = process.env.GMAIL_USER || 'no-reply@littlehands.lk';
      await transporter.sendMail({
        from: `"LittleHands Childcare" <${sender}>`,
        to: cleanEmail,
        subject: `LittleHands Verification Code: ${code}`,
        text: `Your LittleHands verification code is ${code}. It expires in 10 minutes.`,
        html: htmlContent,
      });
      emailSent = true;
      logger.info(`[EmailService] Verification code email sent to ${cleanEmail}`);
    } catch (err) {
      logger.error(`[EmailService] Failed to send email via SMTP to ${cleanEmail}:`, err.message);
    }
  }

  // Always log visibly in server output so testing/development works immediately
  console.log('============================================================');
  console.log(`📧 [LITTLEHANDS GMAIL VERIFICATION CODE]`);
  console.log(`   To: ${cleanEmail}`);
  console.log(`   Code: ${code}`);
  console.log(`   Expires: 10 minutes (${expiresAt.toLocaleTimeString()})`);
  console.log(`   SMTP Sent: ${emailSent ? 'YES (via Gmail)' : 'NO (logged to console / dev response)'}`);
  console.log('============================================================');

  return {
    success: true,
    code, // Provided for dev environment convenience
    emailSent,
    mode: emailSent ? 'smtp' : 'dev_logged',
    expiresInMinutes: 10,
  };
}

/**
 * Verify submitted code
 * @param {string} email
 * @param {string} code
 * @returns {Promise<{ valid: boolean, message?: string }>}
 */
async function verifyCode(email, code) {
  const cleanEmail = normalizeEmailAddress(email);
  const cleanCode = (code || '').toString().trim();

  if (!cleanCode || cleanCode.length !== 6) {
    return { valid: false, message: 'Verification code must be 6 digits' };
  }

  const now = new Date();

  // 1. Check MongoDB if connected
  if (mongoose.connection.readyState === 1) {
    try {
      const record = await EmailVerification.findOne({ email: cleanEmail }).sort({ createdAt: -1 });
      if (record) {
        if (record.expiresAt < now) {
          return { valid: false, message: 'Verification code has expired. Please request a new code.' };
        }
        if (record.code === cleanCode) {
          record.verified = true;
          await record.save();
          return { valid: true };
        }
        return { valid: false, message: 'Incorrect verification code. Please check your Gmail.' };
      }
    } catch (err) {
      logger.error('Failed to verify code in MongoDB:', err);
    }
  }

  // 2. Check memory store
  const memRecord = memoryStore.get(cleanEmail);
  if (memRecord) {
    if (memRecord.expiresAt < now) {
      return { valid: false, message: 'Verification code has expired. Please request a new code.' };
    }
    if (memRecord.code === cleanCode) {
      memRecord.verified = true;
      return { valid: true };
    }
    return { valid: false, message: 'Incorrect verification code. Please check your Gmail.' };
  }

  return { valid: false, message: 'No verification code was sent for this email. Please request a code.' };
}

/**
 * Check if email was already verified
 * @param {string} email
 * @returns {Promise<boolean>}
 */
async function isEmailVerified(email) {
  const cleanEmail = normalizeEmailAddress(email);
  if (mongoose.connection.readyState === 1) {
    try {
      const record = await EmailVerification.findOne({ email: cleanEmail, verified: true });
      if (record) return true;
    } catch (_) {}
  }
  const memRecord = memoryStore.get(cleanEmail);
  return memRecord?.verified === true;
}

module.exports = {
  sendVerificationCode,
  verifyCode,
  isEmailVerified,
};
