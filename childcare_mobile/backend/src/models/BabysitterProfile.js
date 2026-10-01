const mongoose = require('mongoose');
const schema = new mongoose.Schema({ user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', unique: true }, bio: String, hourlyRate: Number, certifications: [String], verified: { type: Boolean, default: false } }, { timestamps: true });
module.exports = mongoose.models.BabysitterProfile || mongoose.model('BabysitterProfile', schema);
