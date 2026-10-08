const ApiError = require('../utils/ApiError');

function notFoundMiddleware(req, res, next) {
  next(new ApiError(404, `Route not found: ${req.method} ${req.originalUrl}`));
}

function errorMiddleware(error, req, res, next) {
  let statusCode = error.statusCode || 500;
  let message = error.message || 'Internal server error';
  let details = error.details;

  // 1. Mongoose validation error
  if (error.name === 'ValidationError') {
    statusCode = 400;
    const errors = Object.values(error.errors || {}).map((e) => e.message);
    message = errors.join(', ') || 'Validation error';
    details = errors;
  }

  // 2. Mongoose bad ObjectId / CastError
  else if (error.name === 'CastError') {
    statusCode = 400;
    message = `Invalid resource identifier for ${error.path || 'id'}`;
  }

  // 3. MongoDB duplicate key error
  else if (error.code === 11000) {
    statusCode = 409;
    const field = Object.keys(error.keyValue || {})[0] || 'field';
    message = `Duplicate value entered for ${field}. Please use another value.`;
  }

  // 4. JWT invalid token
  else if (error.name === 'JsonWebTokenError') {
    statusCode = 401;
    message = 'Invalid authentication token';
  }

  // 5. JWT expired token
  else if (error.name === 'TokenExpiredError') {
    statusCode = 401;
    message = 'Authentication token expired';
  }

  if (statusCode >= 500) {
    console.error('[UnhandledServerError]', error);
  }

  const payload = {
    success: false,
    message: message || 'Internal server error',
  };

  if (details !== undefined) {
    payload.details = details;
  }

  res.status(statusCode).json(payload);
}

module.exports = { notFoundMiddleware, errorMiddleware };
