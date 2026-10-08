const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const ApiError = require('../utils/ApiError');
const env = require('../config/env');
const User = require('../models/User');

async function authMiddleware(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return next(new ApiError(401, 'Authentication required: Bearer token missing'));
  }

  const token = header.slice(7).trim();
  if (!token) {
    return next(new ApiError(401, 'Authentication required: Bearer token is empty'));
  }

  try {
    const decoded = jwt.verify(token, env.jwtSecret);

    // Check if decoded token flags suspended user
    if (decoded.accountStatus === 'suspended' || decoded.isActive === false) {
      return next(new ApiError(403, 'Your account has been suspended by administration'));
    }

    // Check live database user if connected
    if (mongoose.connection.readyState === 1 && (decoded.id || decoded._id)) {
      try {
        const userId = decoded.id || decoded._id;
        const liveUser = await User.findById(userId).select('accountStatus isActive role email name isVerified');
        if (liveUser) {
          if (liveUser.accountStatus === 'suspended' || liveUser.isActive === false) {
            return next(new ApiError(403, 'Your account has been suspended by administration'));
          }
          decoded.role = liveUser.role || decoded.role;
          decoded.accountStatus = liveUser.accountStatus || 'active';
        }
      } catch (dbErr) {
        // Fall back to decoded token payload
      }
    }

    req.user = decoded;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return next(new ApiError(401, 'Authentication token has expired. Please log in again.'));
    }
    return next(new ApiError(401, 'Invalid authentication token'));
  }
}

module.exports = authMiddleware;
