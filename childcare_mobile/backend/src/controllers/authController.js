const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
const User = require('../models/User');
const ApiError = require('../utils/ApiError');
const ApiResponse = require('../utils/ApiResponse');
const generateToken = require('../utils/generateToken');
const ROLES = require('../constants/roles');

const emailService = require('../services/emailService');

async function sendVerification(req, res, next) {
  try {
    const { email, name } = req.body;
    if (!email || typeof email !== 'string' || !email.includes('@')) {
      return next(new ApiError(400, 'A valid Gmail/email address is required'));
    }

    const cleanEmail = email.trim().toLowerCase();

    // Check if user already exists
    if (mongoose.connection.readyState === 1) {
      const existing = await User.findOne({ email: cleanEmail });
      if (existing) {
        return next(new ApiError(409, 'An account with this email already exists. Please log in.'));
      }
    }

    const result = await emailService.sendVerificationCode(cleanEmail, name || 'there');
    return ApiResponse.success(
      res,
      {
        email: cleanEmail,
        expiresInMinutes: result.expiresInMinutes,
        emailSent: result.emailSent,
        // Include dev code in development or when testing
        ...(process.env.NODE_ENV !== 'production' ? { devCode: result.code } : {}),
      },
      'Gmail verification code sent successfully. Valid for 10 minutes.',
      200
    );
  } catch (err) {
    next(err);
  }
}

async function verifyEmailCode(req, res, next) {
  try {
    const { email, code } = req.body;
    if (!email || !code) {
      return next(new ApiError(400, 'Email and 6-digit verification code are required'));
    }

    const verification = await emailService.verifyCode(email, code);
    if (!verification.valid) {
      return next(new ApiError(400, verification.message || 'Invalid or expired verification code'));
    }

    return ApiResponse.success(
      res,
      { email: email.trim().toLowerCase(), verified: true },
      'Gmail verified successfully'
    );
  } catch (err) {
    next(err);
  }
}

async function register(req, res, next) {
  try {
    const { name, email, password, role = ROLES.PARENT, verificationCode, code } = req.body;
    const cleanEmail = (email || '').trim().toLowerCase();
    const otp = (verificationCode || code || '').toString().trim();

    // Verify OTP if supplied or check if already verified
    if (otp) {
      const verification = await emailService.verifyCode(cleanEmail, otp);
      if (!verification.valid) {
        return next(new ApiError(400, verification.message || 'Invalid or expired verification code'));
      }
    }

    if (mongoose.connection.readyState === 1) {
      const existing = await User.findOne({ email: cleanEmail });
      if (existing) return next(new ApiError(409, 'User with this email already exists'));
      const passwordHash = await bcrypt.hash(password, 12);
      const user = await User.create({
        name,
        email: cleanEmail,
        passwordHash,
        role,
        isEmailVerified: true,
      });

      // Initialize ParentProfile if role is parent
      if (role === ROLES.PARENT) {
        try {
          const ParentProfile = require('../models/ParentProfile');
          await ParentProfile.create({
            userId: user._id,
            emergencyContact: '',
            preferences: {},
          });
        } catch (_) {}
      }

      const token = generateToken({ sub: user._id.toString(), role: user.role });
      return ApiResponse.success(
        res,
        {
          user: {
            id: user._id.toString(),
            name: user.name,
            email: user.email,
            role: user.role,
            isEmailVerified: true,
          },
          token,
        },
        'Registered successfully',
        201
      );
    }
    const passwordHash = await bcrypt.hash(password, 12);
    const user = {
      id: `local-${Date.now()}`,
      name,
      email: cleanEmail,
      role,
      passwordHash,
      isEmailVerified: true,
    };
    return ApiResponse.success(
      res,
      {
        user: { id: user.id, name, email: cleanEmail, role, isEmailVerified: true },
        token: generateToken({ sub: user.id, role }),
      },
      'Registered',
      201
    );
  } catch (err) {
    next(err);
  }
}

async function login(req, res, next) {
  try {
    const { email, identifier, phone, password } = req.body;
    const loginKey = (email || identifier || phone || '').trim();
    if (!loginKey || !password) return next(new ApiError(400, 'Mobile number/email and password are required'));

    if (mongoose.connection.readyState === 1) {
      let user = await User.findOne({ email: loginKey.toLowerCase() });
      if (!user) {
        try {
          const BabysitterProfile = require('../models/BabysitterProfile');
          const cleanKey = loginKey.replace(/[\s\-]/g, '');
          const profile = await BabysitterProfile.findOne({
            $or: [
              { phone: loginKey },
              { phone: cleanKey },
              { phone: cleanKey.startsWith('+94') ? '0' + cleanKey.substring(3) : cleanKey },
              { phone: cleanKey.startsWith('0') ? '+94' + cleanKey.substring(1) : cleanKey }
            ]
          });
          if (profile) {
            user = await User.findById(profile.userId);
          }
        } catch (_) {}
      }
      if (!user) return next(new ApiError(401, 'Invalid mobile number/email or password'));
      const valid = await bcrypt.compare(password, user.passwordHash);
      if (!valid) return next(new ApiError(401, 'Invalid mobile number/email or password'));

      const token = generateToken({ sub: user._id.toString(), role: user.role });
      return ApiResponse.success(
        res,
        {
          user: { id: user._id.toString(), name: user.name, email: user.email, role: user.role },
          token,
        },
        'Logged in successfully'
      );
    }

    const user = { id: 'local-user', email, role: ROLES.PARENT, passwordHash: await bcrypt.hash(password, 12) };
    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) return next(new ApiError(401, 'Invalid credentials'));
    return ApiResponse.success(
      res,
      { user: { id: user.id, email: user.email, role: user.role }, token: generateToken({ sub: user.id, role: user.role }) }
    );
  } catch (error) {
    next(error);
  }
}

function me(req, res) {
  return ApiResponse.success(res, { user: req.user });
}

module.exports = {
  register,
  login,
  me,
  sendVerification,
  verifyEmailCode,
};
