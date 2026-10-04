const mongoose = require('mongoose');

const schema = new mongoose.Schema(
	{
		booking: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking' },
		user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
		sharingEnabled: { type: Boolean, default: false },
		latitude: Number,
		longitude: Number,
		recordedAt: { type: Date, default: Date.now },
	},
	{ timestamps: true }
);

module.exports = mongoose.models.TrackingLocation || mongoose.model('TrackingLocation', schema);
