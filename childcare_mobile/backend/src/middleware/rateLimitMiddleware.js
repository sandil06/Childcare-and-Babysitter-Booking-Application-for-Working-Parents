const rateLimit = require('express-rate-limit');

const apiRateLimit = process.env.NODE_ENV === 'test'
  ? (req, res, next) => next()
  : rateLimit({ windowMs: 15 * 60 * 1000, limit: 300, standardHeaders: 'draft-8', legacyHeaders: false });

module.exports = apiRateLimit;
