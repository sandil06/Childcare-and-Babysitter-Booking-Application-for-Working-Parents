const mongoose = require('mongoose');

const childSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    age: { type: String, default: '' },
    notes: { type: String, default: '' },
    birthDate: { type: Date },
  },
  { _id: true }
);

const parentProfileSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },
    phone: { type: String, default: '', trim: true },
    address: { type: String, default: '', trim: true },
    emergencyContact: { type: String, default: '', trim: true },
    avatar: { type: String, default: null },
    profileImage: { type: String, default: null },
    isNicVerified: { type: Boolean, default: false },
    children: [childSchema],
  },
  { timestamps: true }
);

module.exports =
  mongoose.models.ParentProfile ||
  mongoose.model('ParentProfile', parentProfileSchema);
