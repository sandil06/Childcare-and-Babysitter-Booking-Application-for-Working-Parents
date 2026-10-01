const mongoose = require('mongoose');
const schema = new mongoose.Schema({ user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', unique: true }, name: { type: String, required: true }, verified: { type: Boolean, default: false } }, { timestamps: true });
module.exports = mongoose.models.AgencyProfile || mongoose.model('AgencyProfile', schema);
