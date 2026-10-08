const mongoose = require('mongoose');

const childSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    age: { type: Number, required: true },
    gender: { type: String },
    notes: { type: String },
  },
  { _id: false }
);

const bookingSchema = new mongoose.Schema(
  {
    bookingId: {
      type: String,
      unique: true,
      sparse: true,
    },
    parent: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
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
    },
    endTime: {
      type: String,
      required: true,
    },
    startAt: { type: Date },
    endAt: { type: Date },
    durationHours: {
      type: Number,
      required: true,
      default: 4.0,
    },
    hourlyRate: {
      type: Number,
      required: true,
      default: 1500.0,
    },
    total: {
      type: Number,
      min: 0,
      default: 6000.0,
    },
    subtotal: {
      type: Number,
      default: 0,
    },
    serviceFee: {
      type: Number,
      default: 0,
    },
    totalAmount: {
      type: Number,
      default: 0,
    },
    location: {
      type: String,
      required: true,
      trim: true,
      default: 'Colombo, Sri Lanka',
    },
    latitude: {
      type: Number,
      default: 6.9271,
    },
    longitude: {
      type: Number,
      default: 79.8612,
    },
    children: {
      type: [childSchema],
      default: [],
    },
    specialNotes: {
      type: String,
      default: '',
      trim: true,
    },
    status: {
      type: String,
      enum: [
        'pending',
        'accepted',
        'confirmed',
        'travelling',
        'arrived',
        'in_progress',
        'completed',
        'cancelled',
        'rejected',
      ],
      default: 'pending',
    },
    paymentStatus: {
      type: String,
      enum: ['pending', 'processing', 'succeeded', 'paid', 'failed', 'refunded'],
      default: 'pending',
    },
    paymentIntentId: {
      type: String,
      default: null,
    },
    cancellationReason: {
      type: String,
      default: null,
    },
    cancelledBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    cancelledAt: {
      type: Date,
      default: null,
    },
    rejectionReason: {
      type: String,
      default: null,
    },
    rescheduleHistory: {
      type: [
        {
          oldDate: { type: Date },
          oldStartTime: { type: String },
          oldEndTime: { type: String },
          newDate: { type: Date },
          newStartTime: { type: String },
          newEndTime: { type: String },
          requestedAt: { type: Date, default: Date.now },
        },
      ],
      default: [],
    },
  },
  { timestamps: true }
);

function parseTimeObj(str) {
  if (!str) return { hour: 0, min: 0 };
  const clean = str.trim();
  const match = clean.match(/^(\d{1,2}):(\d{2})(?:\s*([AP]M))?$/i);
  if (!match) {
    const parts = clean.split(':').map(Number);
    return { hour: parts[0] || 0, min: parts[1] || 0 };
  }
  let hour = Number.parseInt(match[1], 10);
  const min = Number.parseInt(match[2], 10);
  const period = match[3] ? match[3].toUpperCase() : null;
  if (period === 'PM' && hour < 12) hour += 12;
  if (period === 'AM' && hour === 12) hour = 0;
  return { hour, min };
}

// Auto-generate reference bookingId before saving
bookingSchema.pre('save', function (next) {
  if (!this.bookingId) {
    this.bookingId = `#BK-${Math.floor(1000 + Math.random() * 9000)}`;
  }
  if (this.date && this.startTime && this.endTime) {
    const base = new Date(this.date);
    const startObj = parseTimeObj(this.startTime);
    const endObj = parseTimeObj(this.endTime);
    this.startAt = new Date(base.getFullYear(), base.getMonth(), base.getDate(), startObj.hour, startObj.min);
    this.endAt = new Date(base.getFullYear(), base.getMonth(), base.getDate(), endObj.hour, endObj.min);
    const startM = startObj.hour * 60 + startObj.min;
    const endM = endObj.hour * 60 + endObj.min;
    if (endM > startM) {
      this.durationHours = Math.max(0.5, Math.round(((endM - startM) / 60) * 10) / 10);
    }
  }
  if (!this.durationHours || this.durationHours <= 0) {
    this.durationHours = 4.0;
  }
  if (!this.hourlyRate || this.hourlyRate <= 0) {
    this.hourlyRate = 1500.0;
  }
  this.subtotal = Math.round(this.hourlyRate * this.durationHours);
  this.total = this.subtotal + (this.serviceFee || 0);
  this.totalAmount = this.total;
  next();
});

bookingSchema.index({ babysitter: 1, status: 1, date: -1 });
bookingSchema.index({ parent: 1, status: 1, date: -1 });

module.exports =
  mongoose.models.Booking || mongoose.model('Booking', bookingSchema);
