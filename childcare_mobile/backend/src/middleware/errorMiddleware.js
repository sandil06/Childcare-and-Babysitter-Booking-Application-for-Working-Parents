const ApiError = require('../utils/ApiError');

function notFoundMiddleware(req, res, next) {
  next(new ApiError(404, `Route not found: ${req.method} ${req.originalUrl}`));
}

function errorMiddleware(error, req, res, next) {
  const statusCode = error.statusCode || (error.name === 'CastError' ? 400 : 500);
  const message = error.name === 'CastError' ? 'Invalid resource identifier' : error.message;
  if (statusCode >= 500) console.error(error);
  res.status(statusCode).json({ success: false, message: message || 'Internal server error', ...(error.details ? { details: error.details } : {}) });
}

module.exports = { notFoundMiddleware, errorMiddleware };
