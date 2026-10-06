const mongoose = require('mongoose');

const verificationDocumentSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: ['id', 'police_check', 'qualification', 'photo', 'certificate', 'other'],
      required: true,
    },
    name: { type: String, required: true },
    url: { type: String, required: true },
    status: {
      type: String,
      enum: ['pending', 'under_review', 'verified', 'rejected'],
      default: 'pending',
    },
    uploadedAt: { type: Date, default: Date.now },
  },
  { _id: false }
);

const verificationRequestSchema = new mongoose.Schema(
  {
    babysitter: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    babysitterProfile: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'BabysitterProfile',
    },
    agency: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    documents: {
      type: [verificationDocumentSchema],
      default: [],
    },
    status: {
      type: String,
      enum: ['pending', 'under_review', 'verified', 'rejected', 'changes_requested'],
      default: 'pending',
      index: true,
    },
    reviewNotes: {
      type: String,
      default: '',
    },
    reviewedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    reviewedAt: {
      type: Date,
      default: null,
    },
    submittedAt: {
      type: Date,
      default: Date.now,
      index: true,
    },
  },
  { timestamps: true }
);

verificationRequestSchema.index({ babysitter: 1, status: 1 });
verificationRequestSchema.index({ status: 1, submittedAt: -1 });

module.exports =
  mongoose.models.VerificationRequest ||
  mongoose.model('VerificationRequest', verificationRequestSchema);
