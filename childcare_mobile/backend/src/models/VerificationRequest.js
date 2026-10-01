const mongoose = require('mongoose');
const schema = new mongoose.Schema({ sitter: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, agency: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, documents: [String], status: { type: String, default: 'pending' } }, { timestamps: true });
module.exports = mongoose.models.VerificationRequest || mongoose.model('VerificationRequest', schema);
