const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    phone: { type: String, default: '', trim: true },
    passwordHash: { type: String, required: true },
    secondaryPasswordHash: { type: String, default: null },
    googleId: { type: String, sparse: true, unique: true },
    role: { type: String, enum: ['parent', 'babysitter', 'agency', 'admin'], default: 'parent' },
    avatar: { type: String, default: null },
    profileImage: { type: String, default: null },
    accountStatus: { type: String, enum: ['active', 'suspended'], default: 'active' },
    isActive: { type: Boolean, default: true },
    suspensionReason: { type: String, default: null },
    suspendedAt: { type: Date, default: null },
    isEmailVerified: { type: Boolean, default: false },
  },
  { timestamps: true }
);

userSchema.index({ role: 1, createdAt: -1 });

module.exports = mongoose.models.User || mongoose.model('User', userSchema);
