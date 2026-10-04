const mongoose = require('mongoose');

const emailVerificationSchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: true,
      lowercase: true,
      trim: true,
      index: true,
    },
    code: {
      type: String,
      required: true,
    },
    verified: {
      type: Boolean,
      default: false,
    },
    expiresAt: {
      type: Date,
      required: true,
    },
  },
  { timestamps: true }
);

// TTL index to automatically remove expired documents after 15 minutes
emailVerificationSchema.index({ createdAt: 1 }, { expireAfterSeconds: 900 });

module.exports =
  mongoose.models.EmailVerification ||
  mongoose.model('EmailVerification', emailVerificationSchema);
