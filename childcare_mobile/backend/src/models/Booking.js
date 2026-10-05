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

// Auto-generate reference bookingId before saving
bookingSchema.pre('save', function (next) {
  if (!this.bookingId) {
    this.bookingId = `#BK-${Math.floor(1000 + Math.random() * 9000)}`;
  }
  if (this.date && this.startTime && this.endTime) {
    const base = new Date(this.date);
    const [sH, sM] = this.startTime.split(':').map(Number);
    const [eH, eM] = this.endTime.split(':').map(Number);
    this.startAt = new Date(base.getFullYear(), base.getMonth(), base.getDate(), sH, sM);
    this.endAt = new Date(base.getFullYear(), base.getMonth(), base.getDate(), eH, eM);
    if (!this.durationHours || this.durationHours <= 0) {
      const diffMs = this.endAt - this.startAt;
      this.durationHours = Math.max(0.5, Math.round((diffMs / (1000 * 60 * 60)) * 10) / 10);
    }
  }
  if (!this.subtotal && this.hourlyRate && this.durationHours) {
    this.subtotal = Math.round(this.hourlyRate * this.durationHours);
  }
  if (!this.total && this.subtotal) {
    this.total = this.subtotal + (this.serviceFee || 0);
  }
  if (!this.totalAmount) {
    this.totalAmount = this.total || 0;
  }
  next();
});

bookingSchema.index({ babysitter: 1, status: 1, date: -1 });
bookingSchema.index({ parent: 1, status: 1, date: -1 });

module.exports =
  mongoose.models.Booking || mongoose.model('Booking', bookingSchema);
