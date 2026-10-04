const { body } = require('express-validator');

const registerValidator = [body('name').trim().notEmpty().withMessage('Name is required'), body('email').isEmail().normalizeEmail(), body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters')];
const loginValidator = [
	body('email')
		.custom((value) => typeof value === 'string' && (value.includes('@') || /\d/.test(value)))
		.withMessage('A valid email or mobile number is required'),
	body('password').notEmpty(),
];

module.exports = { registerValidator, loginValidator };
