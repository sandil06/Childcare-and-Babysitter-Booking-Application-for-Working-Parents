const { body } = require('express-validator');
const validationMiddleware = require('../middleware/validationMiddleware');

const validateRegister = [
  body('firstName').trim().notEmpty().withMessage('First name is required'),
  body('lastName').trim().notEmpty().withMessage('Last name is required'),
  body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters long'),
  body('hourlyRate')
    .optional()
    .isFloat({ min: 0.1 })
    .withMessage('Hourly rate must be greater than 0'),
  body('experienceYears')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Experience years must be 0 or greater'),
  validationMiddleware,
];

const validateUpdate = [
  body('hourlyRate')
    .optional()
    .isFloat({ min: 0.1 })
    .withMessage('Hourly rate must be greater than 0'),
  body('experienceYears')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Experience years must be 0 or greater'),
  body('isAvailable')
    .optional()
    .isBoolean()
    .withMessage('isAvailable must be a boolean'),
  validationMiddleware,
];

module.exports = {
  validateRegister,
  validateUpdate,
};
