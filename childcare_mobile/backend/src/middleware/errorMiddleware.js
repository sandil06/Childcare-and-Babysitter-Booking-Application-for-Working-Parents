const ApiError = require('../utils/ApiError');

function notFoundMiddleware(req, res, next) {
  next(new ApiError(404, `Route not found: ${req.method} ${req.originalUrl}`));
}

function errorMiddleware(error, req, res, next) {
  const statusCode = error.statusCode || 500;
  if (statusCode >= 500) console.error(error);
  res.status(statusCode).json({ success: false, message: error.message || 'Internal server error', ...(error.details ? { details: error.details } : {}) });
}

module.exports = { notFoundMiddleware, errorMiddleware };
