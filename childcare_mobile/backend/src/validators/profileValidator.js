const { body } = require('express-validator');

const profileValidator = [body('name').optional().trim().notEmpty(), body('phone').optional().trim().isLength({ min: 7 })];

module.exports = { profileValidator };
