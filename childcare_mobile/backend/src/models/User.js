const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    phone: { type: String, default: '', trim: true },
    passwordHash: { type: String, required: true },
    googleId: { type: String, sparse: true, unique: true },
    role: { type: String, enum: ['parent', 'babysitter', 'agency', 'admin'], default: 'parent' },
    isEmailVerified: { type: Boolean, default: false },
  },
  { timestamps: true }
);
module.exports = mongoose.models.User || mongoose.model('User', userSchema);
