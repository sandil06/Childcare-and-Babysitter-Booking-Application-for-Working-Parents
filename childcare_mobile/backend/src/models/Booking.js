const mongoose = require('mongoose');
const bookingSchema = new mongoose.Schema({ parent: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }, babysitter: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }, startAt: { type: Date, required: true }, endAt: { type: Date, required: true }, status: { type: String, default: 'pending' }, total: { type: Number, min: 0, default: 0 } }, { timestamps: true });
module.exports = mongoose.models.Booking || mongoose.model('Booking', bookingSchema);
