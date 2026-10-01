const ApiError = require('../utils/ApiError');

function roleMiddleware(...roles) {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) return next(new ApiError(403, 'Insufficient permissions'));
    next();
  };
}

module.exports = roleMiddleware;
