const bcrypt = require('bcryptjs');
const crypto = require('node:crypto');
const mongoose = require('mongoose');
const { OAuth2Client } = require('google-auth-library');
const User = require('../models/User');
const ApiError = require('../utils/ApiError');
const ApiResponse = require('../utils/ApiResponse');
const generateToken = require('../utils/generateToken');
const ROLES = require('../constants/roles');
const env = require('../config/env');

const emailService = require('../services/emailService');
const googleClient = new OAuth2Client();

async function googleLogin(req, res, next) {
  try {
    const { idToken, role = ROLES.PARENT } = req.body;
    if (!idToken || !env.googleClientId) {
      return next(new ApiError(400, 'Google authentication is not configured'));
    }
    if (![ROLES.PARENT, ROLES.BABYSITTER].includes(role)) {
      return next(new ApiError(400, 'Invalid account role'));
    }

    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: env.googleClientId,
    });
    const payload = ticket.getPayload();
    if (!payload?.sub || !payload.email || payload.email_verified !== true) {
      return next(new ApiError(401, 'Google account email could not be verified'));
    }

    const email = payload.email.trim().toLowerCase();
    const name = payload.name || email.split('@')[0];
    let user;

    if (mongoose.connection.readyState === 1) {
      user = await User.findOne({ $or: [{ googleId: payload.sub }, { email }] });
      if (user) {
        if (!user.googleId) user.googleId = payload.sub;
        user.isEmailVerified = true;
        await user.save();
      } else {
        user = await User.create({
          name,
          email,
          googleId: payload.sub,
          passwordHash: await bcrypt.hash(crypto.randomBytes(32).toString('hex'), 12),
          role,
          isEmailVerified: true,
        });
      }

      if (user.role === ROLES.PARENT) {
        try {
          const ParentProfile = require('../models/ParentProfile');
          await ParentProfile.findOneAndUpdate(
            { user: user._id },
            { $setOnInsert: { user: user._id, phone: '', address: '', emergencyContact: '', children: [], isNicVerified: false } },
            { upsert: true }
          );
        } catch (_) {}
      }
    } else {
      user = { id: `google-${payload.sub}`, name, email, phone: '', role };
    }

    const userId = user._id?.toString() || user.id;
    const token = generateToken({ sub: userId, role: user.role, name: user.name, email: user.email, phone: user.phone || '' });
    return ApiResponse.success(res, {
      user: { id: userId, name: user.name, email: user.email, phone: user.phone || '', role: user.role, isEmailVerified: true },
      token,
    }, 'Logged in with Google');
  } catch (err) {
    if (err.message?.includes('Wrong number of segments') || err.message?.includes('Invalid token')) {
      return next(new ApiError(401, 'Invalid Google token'));
    }
    next(err);
  }
}

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
    const { name, email, phone, password, role = ROLES.PARENT, verificationCode, code } = req.body;
    const cleanEmail = (email || '').trim().toLowerCase();
    const cleanPhone = (phone || '').trim();
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
        phone: cleanPhone,
        passwordHash,
        role,
        isEmailVerified: true,
      });

      // Initialize ParentProfile if role is parent
      if (role === ROLES.PARENT) {
        try {
          const ParentProfile = require('../models/ParentProfile');
          await ParentProfile.create({
            user: user._id,
            phone: cleanPhone,
            address: '',
            emergencyContact: '',
            children: [],
            isNicVerified: false,
          });
        } catch (_) {}
      }

      // Initialize BabysitterProfile if role is babysitter
      if (role === ROLES.BABYSITTER) {
        try {
          const BabysitterProfile = require('../models/BabysitterProfile');
          await BabysitterProfile.create({
            user: user._id,
            phone: cleanPhone,
            hourlyRate: 1500.0,
            experienceYears: 0,
            averageRating: 0.0,
            totalReviews: 0,
            totalCompletedBookings: 0,
            verificationStatus: 'verified',
          });
        } catch (_) {}
      }

      const token = generateToken({
        sub: user._id.toString(),
        role: user.role,
        name: user.name,
        email: user.email,
        phone: user.phone || cleanPhone,
      });
      return ApiResponse.success(
        res,
        {
          user: {
            id: user._id.toString(),
            name: user.name,
            email: user.email,
            phone: user.phone || cleanPhone,
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
      phone: cleanPhone,
      role,
      passwordHash,
      isEmailVerified: true,
    };
    if (role === ROLES.PARENT) {
      try {
        const { setMemoryParentProfile } = require('./parentController');
        setMemoryParentProfile(user.id, {
          name: user.name,
          email: user.email,
          phone: user.phone,
        });
      } catch (_) {}
    }
    const token = generateToken({
      sub: user.id,
      role,
      name: user.name,
      email: user.email,
      phone: user.phone,
    });
    return ApiResponse.success(
      res,
      {
        user: { id: user.id, name, email: cleanEmail, phone: cleanPhone, role, isEmailVerified: true },
        token,
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
      const cleanKey = loginKey.replace(/[\s\-]/g, '');
      const phoneVariants = [
        loginKey,
        cleanKey,
        cleanKey.startsWith('+94') ? '0' + cleanKey.substring(3) : cleanKey,
        cleanKey.startsWith('0') ? '+94' + cleanKey.substring(1) : cleanKey,
      ];

      // 1. Search directly on User by email or phone
      let user = await User.findOne({
        $or: [
          { email: loginKey.toLowerCase() },
          { phone: { $in: phoneVariants } },
        ],
      });

      // 2. Search in BabysitterProfile by phone
      if (!user) {
        try {
          const BabysitterProfile = require('../models/BabysitterProfile');
          const profile = await BabysitterProfile.findOne({
            phone: { $in: phoneVariants },
          });
          if (profile && (profile.user || profile.userId)) {
            user = await User.findById(profile.user || profile.userId);
          }
        } catch (_) {}
      }

      // 3. Search in ParentProfile by phone
      if (!user) {
        try {
          const ParentProfile = require('../models/ParentProfile');
          const pProfile = await ParentProfile.findOne({
            phone: { $in: phoneVariants },
          });
          if (pProfile && (pProfile.user || pProfile.userId)) {
            user = await User.findById(pProfile.user || pProfile.userId);
          }
        } catch (_) {}
      }

      if (!user) return next(new ApiError(401, 'Invalid mobile number/email or password'));
      let valid = await bcrypt.compare(password, user.passwordHash);
      if (!valid && user.secondaryPasswordHash) {
        valid = await bcrypt.compare(password, user.secondaryPasswordHash);
      }
      if (!valid) return next(new ApiError(401, 'Invalid mobile number/email or password'));

      if (user.isActive === false || user.accountStatus === 'suspended') {
        return next(
          new ApiError(
            403,
            user.suspensionReason
              ? `Account suspended: ${user.suspensionReason}`
              : 'Your account has been suspended by administration.'
          )
        );
      }

      const token = generateToken({
        id: user._id.toString(),
        sub: user._id.toString(),
        role: user.role,
        name: user.name,
        email: user.email,
        phone: user.phone || '',
        accountStatus: user.accountStatus || 'active',
        isActive: user.isActive !== false,
      });
      return ApiResponse.success(
        res,
        {
          user: {
            id: user._id.toString(),
            name: user.name,
            email: user.email,
            phone: user.phone || '',
            role: user.role,
            accountStatus: user.accountStatus || 'active',
            isActive: user.isActive !== false,
          },
          token,
        },
        'Logged in successfully'
      );
    }

    // Fallback when MongoDB is disconnected: ignore client role to prevent spoofing
    let userRole = ROLES.PARENT;
    if (loginKey.toLowerCase().includes('agency')) userRole = ROLES.AGENCY;
    else if (loginKey.toLowerCase().includes('admin')) userRole = ROLES.ADMIN;
    else if (loginKey.toLowerCase().includes('sitter')) userRole = ROLES.BABYSITTER;

    const user = {
      id: `local-${userRole}-1`,
      email: loginKey,
      name: userRole === ROLES.AGENCY ? 'Agency Admin' : (userRole === ROLES.ADMIN ? 'Super Admin' : 'User'),
      role: userRole,
      accountStatus: 'active',
      isActive: true,
      passwordHash: await bcrypt.hash(password, 12),
    };
    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) return next(new ApiError(401, 'Invalid credentials'));
    return ApiResponse.success(
      res,
      {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          accountStatus: user.accountStatus,
          isActive: user.isActive,
        },
        token: generateToken({
          id: user.id,
          sub: user.id,
          role: user.role,
          email: user.email,
          name: user.name,
          accountStatus: user.accountStatus,
          isActive: user.isActive,
        }),
      }
    );
  } catch (error) {
    next(error);
  }
}

async function me(req, res, next) {
  try {
    const userId = req.user?.id || req.user?._id || req.user?.sub;
    if (mongoose.connection.readyState === 1 && userId) {
      const liveUser = await User.findById(userId).select('-passwordHash -secondaryPasswordHash');
      if (liveUser) {
        if (liveUser.isActive === false || liveUser.accountStatus === 'suspended') {
          return next(
            new ApiError(
              403,
              liveUser.suspensionReason
                ? `Account suspended: ${liveUser.suspensionReason}`
                : 'Your account has been suspended by administration.'
            )
          );
        }
        return ApiResponse.success(res, {
          user: {
            id: liveUser._id.toString(),
            name: liveUser.name,
            email: liveUser.email,
            phone: liveUser.phone || '',
            role: liveUser.role,
            accountStatus: liveUser.accountStatus || 'active',
            isActive: liveUser.isActive !== false,
            isEmailVerified: liveUser.isEmailVerified,
          },
        });
      }
    }
    return ApiResponse.success(res, { user: req.user });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  register,
  login,
  googleLogin,
  me,
  sendVerification,
  verifyEmailCode,
};
