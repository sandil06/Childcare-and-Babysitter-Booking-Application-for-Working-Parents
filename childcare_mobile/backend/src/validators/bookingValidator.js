const { body } = require('express-validator');

const bookingValidator = [body('babysitterId').isMongoId().withMessage('Valid babysitterId is required'), body('startAt').isISO8601().withMessage('Valid startAt is required'), body('endAt').isISO8601().withMessage('Valid endAt is required')];

module.exports = { bookingValidator };
