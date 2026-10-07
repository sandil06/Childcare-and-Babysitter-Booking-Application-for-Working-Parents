const mongoose = require('mongoose');

const schema = new mongoose.Schema(
  {
    booking: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', index: true },
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
    sharingEnabled: { type: Boolean, default: true },
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true },
    heading: { type: Number, default: 0 },
    speed: { type: Number, default: 0 },
    status: {
      type: String,
      enum: ['travelling', 'arrived', 'in_progress', 'completed', 'idle'],
      default: 'travelling',
    },
    recordedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

schema.index({ booking: 1, recordedAt: -1 });

module.exports = mongoose.models.TrackingLocation || mongoose.model('TrackingLocation', schema);
