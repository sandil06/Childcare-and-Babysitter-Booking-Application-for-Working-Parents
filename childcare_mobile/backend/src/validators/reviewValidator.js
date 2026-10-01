const { body } = require('express-validator');

const reviewValidator = [body('rating').isInt({ min: 1, max: 5 }), body('comment').optional().trim().isLength({ max: 1000 })];

module.exports = { reviewValidator };
