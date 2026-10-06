const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    phone: { type: String, default: '', trim: true },
    passwordHash: { type: String, required: true },
    googleId: { type: String, sparse: true, unique: true },
    role: {
      type: String,
      enum: ['parent', 'babysitter', 'agency', 'admin'],
      default: 'parent',
    },
    isEmailVerified: { type: Boolean, default: false },
    isActive: { type: Boolean, default: true },
    accountStatus: {
      type: String,
      enum: ['active', 'suspended', 'disabled'],
      default: 'active',
    },
    suspensionReason: { type: String, default: null },
    suspendedAt: { type: Date, default: null },
    suspendedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  },
  { timestamps: true }
);

userSchema.index({ email: 1 });
userSchema.index({ role: 1, accountStatus: 1 });
userSchema.index({ isActive: 1 });

module.exports = mongoose.models.User || mongoose.model('User', userSchema);
