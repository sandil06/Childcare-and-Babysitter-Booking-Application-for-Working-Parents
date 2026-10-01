const mongoose = require('mongoose');
const schema = new mongoose.Schema({ booking: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', required: true }, amount: Number, status: { type: String, default: 'pending' }, providerReference: String }, { timestamps: true });
module.exports = mongoose.models.Payment || mongoose.model('Payment', schema);
