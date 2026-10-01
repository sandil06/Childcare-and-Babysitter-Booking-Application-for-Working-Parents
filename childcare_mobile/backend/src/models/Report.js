const mongoose = require('mongoose');
const schema = new mongoose.Schema({ reporter: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, subject: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, reason: String, status: { type: String, default: 'open' } }, { timestamps: true });
module.exports = mongoose.models.Report || mongoose.model('Report', schema);
