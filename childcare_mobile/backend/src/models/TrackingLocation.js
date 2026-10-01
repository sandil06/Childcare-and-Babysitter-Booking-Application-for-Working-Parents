const mongoose = require('mongoose');
const schema = new mongoose.Schema({ booking: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking' }, latitude: Number, longitude: Number, recordedAt: { type: Date, default: Date.now } }, { timestamps: true });
module.exports = mongoose.models.TrackingLocation || mongoose.model('TrackingLocation', schema);
