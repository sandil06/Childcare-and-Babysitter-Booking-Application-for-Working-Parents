const ApiError = require('../utils/ApiError');
const ROLES = require('../constants/roles');

function roleMiddleware(...rolesInput) {
  const roles = rolesInput.flat();

  return (req, res, next) => {
    if (!req.user) {
      return next(new ApiError(401, 'Authentication required'));
    }

    const userRole = (req.user.role || '').toLowerCase();

    // 1. Direct match or Super Admin override
    if (roles.includes(userRole) || userRole === ROLES.ADMIN) {
      return next();
    }

    // 2. Babysitter specific endpoints allow registered users operating as babysitters
    if (roles.includes(ROLES.BABYSITTER) && !roles.includes(ROLES.AGENCY)) {
      return next();
    }

    return next(new ApiError(403, 'Insufficient permissions: Agency/Administrative role required'));
  };
}

module.exports = roleMiddleware;
module.exports.roleMiddleware = roleMiddleware;
module.exports.authorizeRoles = roleMiddleware;
module.exports.requireRole = roleMiddleware;
