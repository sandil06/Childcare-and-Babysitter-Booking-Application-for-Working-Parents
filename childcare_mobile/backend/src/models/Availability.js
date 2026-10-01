const mongoose = require('mongoose');
const schema = new mongoose.Schema({ babysitter: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }, startAt: Date, endAt: Date, isAvailable: { type: Boolean, default: true } }, { timestamps: true });
module.exports = mongoose.models.Availability || mongoose.model('Availability', schema);
