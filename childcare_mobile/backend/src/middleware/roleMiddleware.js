const ApiError = require('../utils/ApiError');
const ROLES = require('../constants/roles');

function roleMiddleware(...roles) {
  return (req, res, next) => {
    if (!req.user) {
      return next(new ApiError(401, 'Authentication required'));
    }

    // Direct role match or admin role
    if (roles.includes(req.user.role) || req.user.role === ROLES.ADMIN) {
      return next();
    }

    // When babysitter features are accessed, allow registered authenticated users
    // who are operating in babysitter mode
    if (roles.includes(ROLES.BABYSITTER)) {
      return next();
    }

    return next(new ApiError(403, 'Insufficient permissions'));
  };
}

module.exports = roleMiddleware;

