const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const BabysitterProfile = require('../models/BabysitterProfile');
const VerificationRequest = require('../models/VerificationRequest');
const Notification = require('../models/Notification');
const ROLES = require('../constants/roles');
const ApiError = require('../utils/ApiError');

// Memory store fallback if DB is not connected
const memoryBabysitters = new Map();

function isDbConnected() {
  return mongoose.connection.readyState === 1;
}

function isValidObjectId(id) {
  if (!id) return false;
  return mongoose.Types.ObjectId.isValid(id) && String(new mongoose.Types.ObjectId(id)) === String(id);
}

async function getProfileByUserId(userId) {
  if (isDbConnected() && isValidObjectId(userId)) {
    try {
      let profile = await BabysitterProfile.findOne({ user: userId }).populate(
        'user',
        'name email phone avatar'
      );
      if (!profile) {
        // Auto-create a profile ONLY if user exists and has babysitter role
        const user = await User.findById(userId);
        if (user && user.role === ROLES.BABYSITTER) {
          profile = await BabysitterProfile.create({
            user: user._id,
            phone: user.phone || '',
            hourlyRate: 1500.0,
            experienceYears: 1,
            skills: ['Child Care', 'First Aid & CPR'],
            languages: ['English', 'Sinhala'],
            qualifications: [],
            averageRating: 0.0,
            totalReviews: 0,
            totalCompletedBookings: 0,
            verificationStatus: 'pending',
            isAvailable: true,
          });
          await profile.populate('user', 'name email phone avatar');
        }
      }
      if (profile) {
        if (!profile.phone && profile.user?.phone) {
          profile.phone = profile.user.phone;
        }
        if (profile.totalReviews === 0) {
          profile.averageRating = 0.0;
        }
        return profile;
      }
    } catch (_) {}
  }

  // Memory fallback
  let mem = memoryBabysitters.get(userId.toString());
  if (!mem) {
    let name = 'Caregiver';
    let email = '';
    if (isDbConnected()) {
      try {
        const u = await User.findById(userId);
        if (u) {
          name = u.name || name;
          email = u.email || email;
        }
      } catch (_) {}
    }
    mem = {
      id: userId.toString(),
      _id: userId.toString(),
      user: {
        id: userId.toString(),
        _id: userId.toString(),
        name,
        email,
      },
      phone: '',
      address: '',
      bio: '',
      hourlyRate: 1500.0,
      experienceYears: 1,
      skills: ['Child Care', 'First Aid & CPR'],
      languages: ['English', 'Sinhala'],
      qualifications: [],
      documents: [],
      verificationStatus: 'verified',
      averageRating: 0.0,
      totalReviews: 0,
      totalCompletedBookings: 0,
      isAvailable: true,
    };
    memoryBabysitters.set(userId.toString(), mem);
  }
  return mem;
}

async function updateProfileByUserId(userId, updateData, isSystemOrAdmin = false) {
  // Prevent manual overriding of system-controlled fields unless admin/system
  const safeUpdate = { ...updateData };
  if (!isSystemOrAdmin) {
    const hasPendingDocs =
      Array.isArray(safeUpdate.documents) &&
      safeUpdate.documents.some((d) => ['pending', 'under_review'].includes(d.status));
    const hasPendingQuals =
      Array.isArray(safeUpdate.qualifications) &&
      safeUpdate.qualifications.some((q) => typeof q === 'object' && ['pending', 'under_review'].includes(q.status));

    if (hasPendingDocs || hasPendingQuals) {
      safeUpdate.verificationStatus = 'under_review';
    } else {
      delete safeUpdate.verificationStatus;
    }
    delete safeUpdate.averageRating;
    delete safeUpdate.totalReviews;
    delete safeUpdate.totalCompletedBookings;
    delete safeUpdate.user;
    delete safeUpdate._id;
  }

  if (isDbConnected() && isValidObjectId(userId)) {
    try {
      if (safeUpdate.phone !== undefined) {
        await User.findByIdAndUpdate(userId, { phone: safeUpdate.phone });
      }
      if (safeUpdate.name !== undefined) {
        await User.findByIdAndUpdate(userId, { name: safeUpdate.name });
      }
      if (safeUpdate.profileImage !== undefined || safeUpdate.avatar !== undefined) {
        const img = safeUpdate.profileImage || safeUpdate.avatar;
        safeUpdate.profileImage = img;
        safeUpdate.avatar = img;
        await User.findByIdAndUpdate(userId, { avatar: img, profileImage: img });
      }
      let profile = await BabysitterProfile.findOne({ user: userId });
      if (!profile) {
        profile = await getProfileByUserId(userId);
      }
      if (profile && profile._id) {
        profile = await BabysitterProfile.findOneAndUpdate(
          { user: userId },
          { $set: safeUpdate },
          { new: true, runValidators: true }
        ).populate('user', 'name email phone avatar profileImage');
        if (profile) {
          memoryBabysitters.set(userId.toString(), profile.toObject ? profile.toObject() : profile);
          return profile;
        }
      }
    } catch (_) {}
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
      hourlyRate: hourlyRate || 1500.0,
      experienceYears: experienceYears || 1,
      skills: skills || [],
      languages: languages || ['Sinhala', 'English'],
      qualifications: qualifications || [],
      ageGroups: ageGroups || [],
      verificationStatus: 'pending',
    });

    // Auto-create initial VerificationRequest so Agency Console immediately reflects pending verification
    try {
      const defaultDocs = [
        {
          type: 'id',
          name: 'National Identity Card (NIC)',
          url: 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=800',
          status: 'pending',
          uploadedAt: new Date(),
        },
        {
          type: 'police_check',
          name: 'Police Clearance Certificate',
          url: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=800',
          status: 'pending',
          uploadedAt: new Date(),
        },
        {
          type: 'certificate',
          name: 'First Aid & CPR Certificate',
          url: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=800',
          status: 'pending',
          uploadedAt: new Date(),
        },
      ];

      await VerificationRequest.create({
        babysitter: user._id,
        babysitterProfile: profile._id,
        status: 'pending',
        documents: defaultDocs,
        submittedAt: new Date(),
      });

      profile.documents = defaultDocs;
      await profile.save();

      // Notify Agency Admin users
      const agencyAdmins = await User.find({ role: { $in: [ROLES.AGENCY, ROLES.ADMIN] } }).select('_id');
      for (const admin of agencyAdmins) {
        await Notification.create({
          user: admin._id,
          title: 'New Verification Request',
          message: `${fullName} has submitted credentials for administrative verification.`,
          type: 'system',
          data: { babysitterId: user._id },
        });
      }
    } catch (e) {
      console.error('[BabysitterService] Error creating initial verification request:', e.message);
    }

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
    hourlyRate: hourlyRate || 1500.0,
    experienceYears: experienceYears || 1,
    skills: skills || [],
    languages: languages || ['Sinhala', 'English'],
    qualifications: qualifications || [],
    ageGroups: ageGroups || [],
    verificationStatus: 'pending',
    averageRating: 0.0,
    totalReviews: 0,
    totalCompletedBookings: 0,
    isAvailable: true,
  };
  memoryBabysitters.set(mockUserId, mockProfile);
  return { user: mockUser, profile: mockProfile };
}

async function listBabysitters(filter = {}) {
  const page = Math.max(1, Number.parseInt(filter.page, 10) || 1);
  const limit = Math.min(50, Math.max(1, Number.parseInt(filter.limit, 10) || 20));
  const skip = (page - 1) * limit;
  const query = {};
  const search = typeof filter.search === 'string' ? filter.search.trim() : '';
  if (filter.verificationStatus) {
    query.verificationStatus = filter.verificationStatus;
  } else if (filter.status) {
    query.verificationStatus = filter.status;
  } else {
    // Default to verified babysitters only in public catalog (Requirement 16)
    query.verificationStatus = 'verified';
  }
  if (filter.isAvailable !== undefined) query.isAvailable = filter.isAvailable === 'true' || filter.isAvailable === true;
  if (filter.minHourlyRate != null) query.hourlyRate = { $gte: Number(filter.minHourlyRate) };
  if (filter.maxHourlyRate != null) query.hourlyRate = { ...query.hourlyRate, $lte: Number(filter.maxHourlyRate) };
  if (filter.minExperience != null) query.experienceYears = { $gte: Number(filter.minExperience) };
  if (filter.minRating != null) query.averageRating = { $gte: Number(filter.minRating) };
  if (filter.skill) query.skills = { $in: [filter.skill] };
  if (filter.language) query.languages = { $in: [filter.language] };

  if (isDbConnected()) {
    if (search) {
      const matchingUsers = await User.find({
        role: ROLES.BABYSITTER,
        $or: [
          { name: { $regex: search, $options: 'i' } },
          { email: { $regex: search, $options: 'i' } },
        ],
      }).select('_id').lean();
      query.user = { $in: matchingUsers.map((user) => user._id) };
    }
    return BabysitterProfile.find(query)
      .populate('user', 'name email phone avatar')
      .sort({ averageRating: -1, createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean();
  }
  if (memoryBabysitters.size === 0) {
    const defaultSitter = {
      id: 'sitter-1',
      _id: 'sitter-1',
      name: 'Kavindi Perera',
      user: {
        id: 'sitter-1',
        _id: 'sitter-1',
        name: 'Kavindi Perera',
        email: 'kavindi.perera@example.com',
      },
      bio: 'Professional early childhood educator with 4 years experience across Colombo.',
      hourlyRate: 1500.0,
      experienceYears: 4,
      skills: ['Infant care', 'First aid & CPR', 'Toddler care'],
      languages: ['Sinhala', 'English', 'Tamil'],
      qualifications: ['CPR & First Aid Certified (SL Red Cross)'],
      verificationStatus: 'verified',
      averageRating: 4.95,
      totalReviews: 32,
      totalCompletedBookings: 48,
      isAvailable: true,
    };
    memoryBabysitters.set('sitter-1', defaultSitter);
  }
  return Array.from(memoryBabysitters.values()).slice(skip, skip + limit);
}

async function getProfileById(id) {
  if (isDbConnected() && isValidObjectId(id)) {
    const profile = await BabysitterProfile.findById(id).populate('user', 'name email phone avatar');
    if (profile) return profile;
  }
  return getProfileByUserId(id);
}

module.exports = {
  getProfileByUserId,
  updateProfileByUserId,
  registerBabysitter,
  listBabysitters,
  getProfileById,
  memoryBabysitters,
};
