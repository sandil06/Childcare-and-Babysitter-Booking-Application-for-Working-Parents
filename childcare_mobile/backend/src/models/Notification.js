const mongoose = require('mongoose');
const schema = new mongoose.Schema({ user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, title: String, body: String, readAt: Date }, { timestamps: true });
module.exports = mongoose.models.Notification || mongoose.model('Notification', schema);
