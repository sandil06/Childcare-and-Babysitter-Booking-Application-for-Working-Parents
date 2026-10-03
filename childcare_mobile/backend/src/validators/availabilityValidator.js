const { body } = require('express-validator');
const validationMiddleware = require('../middleware/validationMiddleware');

function parseMinutes(timeStr) {
  const [h, m] = timeStr.split(':').map(Number);
  return h * 60 + m;
}

const timeRegex = /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/;

const validateCreate = [
  body('date')
    .notEmpty()
    .withMessage('Date is required')
    .isISO8601()
    .withMessage('Invalid date format (must be ISO8601)'),
  body('startTime')
    .notEmpty()
    .withMessage('Start time is required')
    .matches(timeRegex)
    .withMessage('Start time must be in HH:mm format'),
  body('endTime')
    .notEmpty()
    .withMessage('End time is required')
    .matches(timeRegex)
    .withMessage('End time must be in HH:mm format')
    .custom((endTime, { req }) => {
      const startTime = req.body.startTime;
      if (startTime && timeRegex.test(startTime)) {
        if (parseMinutes(endTime) <= parseMinutes(startTime)) {
          throw new Error('End time must be strictly after start time');
        }
      }
      return true;
    }),
  body('available').optional().isBoolean(),
  body('isRecurring').optional().isBoolean(),
  validationMiddleware,
];

const validateUpdate = [
  body('startTime')
    .optional()
    .matches(timeRegex)
    .withMessage('Start time must be in HH:mm format'),
  body('endTime')
    .optional()
    .matches(timeRegex)
    .withMessage('End time must be in HH:mm format'),
  body('available').optional().isBoolean(),
  body('isRecurring').optional().isBoolean(),
  validationMiddleware,
];

module.exports = {
  validateCreate,
  validateUpdate,
  parseMinutes,
};
