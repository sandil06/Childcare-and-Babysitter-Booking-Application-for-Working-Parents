const mongoose = require('mongoose');
const schema = new mongoose.Schema({ participants: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }], lastMessage: String }, { timestamps: true });
module.exports = mongoose.models.Conversation || mongoose.model('Conversation', schema);
