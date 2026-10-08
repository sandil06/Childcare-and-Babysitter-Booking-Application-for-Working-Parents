const mongoose = require('mongoose');

const verificationDocumentSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: ['id', 'national_id', 'passport', 'police_check', 'qualification', 'photo', 'certificate', 'other'],
      required: true,
    },
    name: { type: String, required: true },
    label: { type: String },
    documentNumber: { type: String, default: '' },
    url: { type: String, default: '' },
    fileUrl: { type: String, default: '' },
    status: {
      type: String,
      enum: ['pending', 'under_review', 'verified', 'rejected', 'changes_requested'],
      default: 'pending',
    },
    reviewNotes: { type: String, default: null },
    reviewedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    reviewedAt: { type: Date, default: null },
    uploadedAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now },
  },
  { _id: true }
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
    qualifications: {
      type: [mongoose.Schema.Types.Mixed],
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
