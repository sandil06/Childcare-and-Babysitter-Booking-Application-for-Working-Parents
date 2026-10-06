const jwt = require('jsonwebtoken');
const ApiError = require('../utils/ApiError');
const env = require('../config/env');

function authMiddleware(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return next(new ApiError(401, 'Authentication required'));
  }
  try {
    const decoded = jwt.verify(header.slice(7), env.jwtSecret);
    if (decoded.accountStatus === 'suspended' || decoded.isActive === false) {
      return next(new ApiError(403, 'Your account has been suspended by administration'));
    }
    req.user = decoded;
    next();
  } catch {
    next(new ApiError(401, 'Invalid or expired token'));
  }
}

module.exports = authMiddleware;
