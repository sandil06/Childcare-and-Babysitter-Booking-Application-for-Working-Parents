const mongoose = require('mongoose');

const availabilitySchema = new mongoose.Schema(
  {
    babysitter: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    date: {
      type: Date,
      required: true,
    },
    startTime: {
      type: String,
      required: true,
      trim: true,
    },
    endTime: {
      type: String,
      required: true,
      trim: true,
    },
    startAt: { type: Date },
    endAt: { type: Date },
    available: {
      type: Boolean,
      default: true,
    },
    isAvailable: {
      type: Boolean,
      default: true,
    },
    isRecurring: {
      type: Boolean,
      default: false,
    },
    repeatDays: {
      type: [Number],
      default: [],
    },
  },
  { timestamps: true }
);

// Pre-save hook to populate startAt and endAt dates for indexed querying
availabilitySchema.pre('save', function (next) {
  if (this.date && this.startTime && this.endTime) {
    const base = new Date(this.date);
    const [sH, sM] = this.startTime.split(':').map(Number);
    const [eH, eM] = this.endTime.split(':').map(Number);

    this.startAt = new Date(base.getFullYear(), base.getMonth(), base.getDate(), sH, sM);
    this.endAt = new Date(base.getFullYear(), base.getMonth(), base.getDate(), eH, eM);
    this.isAvailable = this.available;
  }
  next();
});

availabilitySchema.index({ babysitter: 1, date: 1, startTime: 1 });

module.exports =
  mongoose.models.Availability ||
  mongoose.model('Availability', availabilitySchema);
