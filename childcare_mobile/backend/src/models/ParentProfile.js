const mongoose = require('mongoose');
const schema = new mongoose.Schema({ user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', unique: true }, children: [{ name: String, birthDate: Date }] }, { timestamps: true });
module.exports = mongoose.models.ParentProfile || mongoose.model('ParentProfile', schema);
