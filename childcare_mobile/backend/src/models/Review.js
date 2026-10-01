const mongoose = require('mongoose');
const schema = new mongoose.Schema({ booking: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking' }, author: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, subject: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, rating: { type: Number, min: 1, max: 5 }, comment: String }, { timestamps: true });
module.exports = mongoose.models.Review || mongoose.model('Review', schema);
