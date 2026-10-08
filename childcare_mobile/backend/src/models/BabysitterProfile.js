const mongoose = require('mongoose');

const documentSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: ['id', 'national_id', 'passport', 'police_check', 'qualification', 'photo', 'certificate', 'other'],
      required: true,
    },
    name: { type: String, required: true },
    label: { type: String },
    documentNumber: { type: String, default: '' },
    url: { type: String },
    fileUrl: { type: String },
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

const babysitterProfileSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },
    bio: {
      type: String,
      default: '',
      trim: true,
    },
    dateOfBirth: { type: Date },
    gender: { type: String, enum: ['Female', 'Male', 'Other', 'Prefer not to say'] },
    address: { type: String, default: '', trim: true },
    phone: { type: String, default: '', trim: true },
    profileImage: { type: String, default: null },
    avatar: { type: String, default: null },

    hourlyRate: {
      type: Number,
      required: true,
      min: 0,
      default: 1500.0,
    },
    experienceYears: {
      type: Number,
      required: true,
      min: 0,
      default: 1,
    },

    skills: {
      type: [String],
      default: [],
    },
    languages: {
      type: [String],
      default: ['Sinhala', 'English'],
    },
    qualifications: {
      type: [mongoose.Schema.Types.Mixed],
      default: [],
    },
    ageGroups: {
      type: [String],
      default: [],
    },
    documents: {
      type: [documentSchema],
      default: [],
    },

    verificationStatus: {
      type: String,
      enum: ['pending', 'under_review', 'verified', 'rejected', 'changes_requested'],
      default: 'pending',
    },
    verificationNotes: {
      type: String,
      default: '',
    },
    verificationReviewedAt: {
      type: Date,
      default: null,
    },
    verificationReviewedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    averageRating: {
      type: Number,
      min: 0,
      max: 5,
      default: 0.0,
    },
    totalReviews: {
      type: Number,
      default: 0,
    },
    totalCompletedBookings: {
      type: Number,
      default: 0,
    },
    isAvailable: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

module.exports =
  mongoose.models.BabysitterProfile ||
  mongoose.model('BabysitterProfile', babysitterProfileSchema);
