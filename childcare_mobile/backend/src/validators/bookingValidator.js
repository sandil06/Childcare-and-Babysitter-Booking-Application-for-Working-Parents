const { body } = require('express-validator');

const bookingValidator = [
  body().custom((value) => {
    if (!value.babysitterId && !value.babysitter) {
      throw new Error('Valid babysitterId or babysitter is required');
    }
    const hasIso = value.startAt && value.endAt;
    const hasTimes = (value.date || value.startAt) && (value.startTime || value.startAt) && (value.endTime || value.endAt);
    if (!hasIso && !hasTimes) {
      throw new Error('Valid booking schedule (date, startTime, endTime or startAt, endAt) is required');
    }
    return true;
  }),
];

module.exports = { bookingValidator };

