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
      const valid = await bcrypt.compare(password, user.passwordHash);
      if (!valid) return next(new ApiError(401, 'Invalid mobile number/email or password'));

      const token = generateToken({
        sub: user._id.toString(),
        role: user.role,
        name: user.name,
        email: user.email,
        phone: user.phone || '',
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
          },
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
      {
        user: { id: user.id, email: user.email, role: user.role },
        token: generateToken({ sub: user.id, role: user.role, email: user.email, name: 'Parent' }),
      }
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
