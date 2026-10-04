const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const BabysitterProfile = require('../models/BabysitterProfile');
const Notification = require('../models/Notification');
const ROLES = require('../constants/roles');
const ApiError = require('../utils/ApiError');

// Memory store fallback if DB is not connected
const memoryBabysitters = new Map();

function isDbConnected() {
  return mongoose.connection.readyState === 1;
}

async function getProfileByUserId(userId) {
  if (isDbConnected()) {
    let profile = await BabysitterProfile.findOne({ user: userId }).populate(
      'user',
      'name email phone avatar'
    );
    if (!profile) {
      // Auto-create a profile if user is a babysitter
      const user = await User.findById(userId);
      if (user && user.role === ROLES.BABYSITTER) {
        profile = await BabysitterProfile.create({
          user: user._id,
          hourlyRate: 25.0,
          experienceYears: 2,
          verificationStatus: 'verified',
        });
        await profile.populate('user', 'name email phone avatar');
      }
    }
    return profile;
  }

  // Memory fallback
  return (
    memoryBabysitters.get(userId.toString()) || {
      id: userId.toString(),
      user: {
        id: userId.toString(),
        name: 'Maya Johnson',
        email: 'maya.johnson@example.com',
      },
      bio: 'Professional early childhood educator with 4 years experience.',
      hourlyRate: 28.0,
      experienceYears: 4,
      skills: ['Infant care', 'First aid & CPR', 'Toddler care'],
      languages: ['English', 'Spanish'],
      qualifications: ['CPR & First Aid Certified'],
      verificationStatus: 'verified',
      averageRating: 4.95,
      totalReviews: 32,
      totalCompletedBookings: 48,
      isAvailable: true,
    }
  );
}

async function updateProfileByUserId(userId, updateData) {
  // Prevent manual overriding of system-controlled fields
  const safeUpdate = { ...updateData };
  delete safeUpdate.verificationStatus;
  delete safeUpdate.averageRating;
  delete safeUpdate.totalReviews;
  delete safeUpdate.totalCompletedBookings;
  delete safeUpdate.user;
  delete safeUpdate._id;

  if (isDbConnected()) {
    const profile = await BabysitterProfile.findOneAndUpdate(
      { user: userId },
      { $set: safeUpdate },
      { new: true, runValidators: true }
    ).populate('user', 'name email phone avatar');
    if (!profile) throw new ApiError(404, 'Babysitter profile not found');
    return profile;
  }

  const existing = await getProfileByUserId(userId);
  const updated = { ...existing, ...safeUpdate, updatedAt: new Date() };
  memoryBabysitters.set(userId.toString(), updated);
  return updated;
}

async function registerBabysitter(data) {
  const {
    firstName,
    lastName,
    email,
    password,
    phone,
    address,
    dateOfBirth,
    gender,
    bio,
    hourlyRate,
    experienceYears,
    skills,
    languages,
    qualifications,
    ageGroups,
  } = data;

  const fullName = `${firstName} ${lastName}`.trim();
  const passwordHash = await bcrypt.hash(password, 12);

  if (isDbConnected()) {
    const existing = await User.findOne({ email });
    if (existing) throw new ApiError(409, 'User with this email already exists');

    const user = await User.create({
      name: fullName,
      email,
      passwordHash,
      role: ROLES.BABYSITTER,
    });

    const profile = await BabysitterProfile.create({
      user: user._id,
      bio: bio || '',
      phone: phone || '',
      address: address || '',
      dateOfBirth: dateOfBirth ? new Date(dateOfBirth) : undefined,
      gender: gender || 'Other',
      hourlyRate: hourlyRate || 25.0,
      experienceYears: experienceYears || 1,
      skills: skills || [],
      languages: languages || ['English'],
      qualifications: qualifications || [],
      ageGroups: ageGroups || [],
      verificationStatus: 'pending',
    });

    await profile.populate('user', 'name email phone avatar');

    await Notification.create({
      user: user._id,
      title: 'Registration Received',
      message: 'Your babysitter application has been submitted and is currently pending review.',
      type: 'system',
      isRead: false,
    });

    return { user, profile };
  }

  // Memory fallback
  const mockUserId = `sitter-${Date.now()}`;
  const mockUser = {
    id: mockUserId,
    name: fullName,
    email,
    role: ROLES.BABYSITTER,
  };
  const mockProfile = {
    id: `profile-${Date.now()}`,
    user: mockUser,
    bio: bio || '',
    phone: phone || '',
    address: address || '',
    hourlyRate: hourlyRate || 25.0,
    experienceYears: experienceYears || 1,
    skills: skills || [],
    languages: languages || ['English'],
    qualifications: qualifications || [],
    ageGroups: ageGroups || [],
    verificationStatus: 'pending',
    averageRating: 5.0,
    totalReviews: 0,
    totalCompletedBookings: 0,
    isAvailable: true,
  };
  memoryBabysitters.set(mockUserId, mockProfile);
  return { user: mockUser, profile: mockProfile };
}

async function listBabysitters(filter = {}) {
  if (isDbConnected()) {
    return BabysitterProfile.find({
      verificationStatus: 'verified',
      ...filter,
    }).populate('user', 'name email phone avatar');
  }
  if (memoryBabysitters.size === 0) {
    const defaultSitter = {
      id: 'sitter-1',
      _id: 'sitter-1',
      name: 'Maya Johnson',
      user: {
        id: 'sitter-1',
        _id: 'sitter-1',
        name: 'Maya Johnson',
        email: 'maya.johnson@example.com',
      },
      bio: 'Professional early childhood educator with 4 years experience.',
      hourlyRate: 28.0,
      experienceYears: 4,
      skills: ['Infant care', 'First aid & CPR', 'Toddler care'],
      languages: ['English', 'Spanish'],
      qualifications: ['CPR & First Aid Certified'],
      verificationStatus: 'verified',
      averageRating: 4.95,
      totalReviews: 32,
      totalCompletedBookings: 48,
      isAvailable: true,
    };
    memoryBabysitters.set('sitter-1', defaultSitter);
  }
  return Array.from(memoryBabysitters.values());
}

module.exports = {
  getProfileByUserId,
  updateProfileByUserId,
  registerBabysitter,
  listBabysitters,
};
