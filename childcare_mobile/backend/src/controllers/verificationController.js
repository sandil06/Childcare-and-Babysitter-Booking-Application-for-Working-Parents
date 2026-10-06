const mongoose = require('mongoose');
const VerificationRequest = require('../models/VerificationRequest');
const BabysitterProfile = require('../models/BabysitterProfile');
const User = require('../models/User');
const AuditLog = require('../models/AuditLog');
const Notification = require('../models/Notification');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');
const pagination = require('../utils/pagination');

function isDbConnected() {
  return mongoose.connection.readyState === 1;
}

// In-memory verification storage for offline / unit test use
const memoryVerifications = new Map();

function initSampleVerifications() {
  if (memoryVerifications.size > 0) return;

  const samples = [
    {
      _id: 'ver-101',
      id: 'ver-101',
      babysitter: {
        _id: 'sitter-1',
        id: 'sitter-1',
        name: 'Amaya Fernando',
        email: 'amaya.fernando@example.com',
        phone: '+94 77 123 4567',
        avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      },
      babysitterProfile: {
        experienceYears: 4,
        hourlyRate: 1500,
        address: 'Colombo 03, Sri Lanka',
        bio: 'Certified early childhood educator with 4 years experience caring for infants and toddlers.',
        skills: ['First Aid & CPR', 'Infant Care', 'Creative Play'],
        languages: ['English', 'Sinhala'],
        qualifications: ['Diploma in Early Childhood Education', 'Red Cross First Aid'],
        ageGroups: ['Infants (0-1 yr)', 'Toddlers (1-3 yrs)'],
        verificationStatus: 'pending',
      },
      status: 'pending',
      documents: [
        {
          type: 'id',
          name: 'National Identity Card',
          url: 'https://picsum.photos/seed/nic/800/600',
          status: 'pending',
          uploadedAt: new Date(Date.now() - 86400000 * 2),
        },
        {
          type: 'police_check',
          name: 'Police Clearance Certificate',
          url: 'https://picsum.photos/seed/police/800/600',
          status: 'pending',
          uploadedAt: new Date(Date.now() - 86400000 * 2),
        },
        {
          type: 'certificate',
          name: 'First Aid Certificate',
          url: 'https://picsum.photos/seed/cert/800/600',
          status: 'pending',
          uploadedAt: new Date(Date.now() - 86400000 * 2),
        },
      ],
      reviewNotes: '',
      submittedAt: new Date(Date.now() - 86400000 * 2),
      createdAt: new Date(Date.now() - 86400000 * 2),
    },
    {
      _id: 'ver-102',
      id: 'ver-102',
      babysitter: {
        _id: 'sitter-2',
        id: 'sitter-2',
        name: 'Kavindi Perera',
        email: 'kavindi.perera@example.com',
        phone: '+94 71 987 6543',
        avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
      },
      babysitterProfile: {
        experienceYears: 3,
        hourlyRate: 1350,
        address: 'Nugegoda, Sri Lanka',
        bio: 'Passionate and caring childcare provider specializing in toddlers and primary school children.',
        skills: ['Homework Assistance', 'Meal Preparation'],
        languages: ['English', 'Sinhala'],
        qualifications: ['NVQ Level 4 Childcare'],
        ageGroups: ['Toddlers (1-3 yrs)', 'Primary (4-8 yrs)'],
        verificationStatus: 'under_review',
      },
      status: 'under_review',
      documents: [
        {
          type: 'id',
          name: 'Passport Copy',
          url: 'https://picsum.photos/seed/nic2/800/600',
          status: 'under_review',
          uploadedAt: new Date(Date.now() - 86400000 * 4),
        },
      ],
      reviewNotes: 'Initial document check passed, awaiting background check confirmation',
      submittedAt: new Date(Date.now() - 86400000 * 4),
      createdAt: new Date(Date.now() - 86400000 * 4),
    },
    {
      _id: 'ver-103',
      id: 'ver-103',
      babysitter: {
        _id: 'sitter-3',
        id: 'sitter-3',
        name: 'Sanduni Jayawardena',
        email: 'sanduni.j@example.com',
        phone: '+94 76 555 8899',
        avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      },
      babysitterProfile: {
        experienceYears: 5,
        hourlyRate: 1800,
        address: 'Dehiwala, Sri Lanka',
        bio: 'Experienced caregiver with preschool teaching background.',
        skills: ['Special Needs Care', 'Infant Care'],
        languages: ['English', 'Sinhala', 'Tamil'],
        qualifications: ['Montessori Teacher Diploma'],
        ageGroups: ['All Age Groups'],
        verificationStatus: 'verified',
      },
      status: 'verified',
      documents: [
        {
          type: 'id',
          name: 'NIC Copy',
          url: 'https://picsum.photos/seed/nic3/800/600',
          status: 'verified',
          uploadedAt: new Date(Date.now() - 86400000 * 10),
        },
      ],
      reviewNotes: 'All background documents fully verified',
      reviewedAt: new Date(Date.now() - 86400000 * 5),
      submittedAt: new Date(Date.now() - 86400000 * 10),
      createdAt: new Date(Date.now() - 86400000 * 10),
    },
  ];

  for (const s of samples) {
    memoryVerifications.set(s._id, s);
  }
}

initSampleVerifications();

/**
 * GET /api/v1/agency/verifications
 * Paginated list of babysitter verification requests with filters
 */
async function list(req, res, next) {
  try {
    const { status, search } = req.query;
    const { page, limit, skip } = pagination(req.query);

    if (isDbConnected()) {
      const filter = {};
      if (status && status !== 'all') {
        filter.status = status;
      }

      let requests = await VerificationRequest.find(filter)
        .populate('babysitter', 'name email phone avatar')
        .populate('babysitterProfile', 'experienceYears hourlyRate verificationStatus address skills languages qualifications documents')
        .sort({ submittedAt: -1, createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean();

      if (search && search.trim()) {
        const query = search.trim().toLowerCase();
        requests = requests.filter(
          (r) =>
            r.babysitter?.name?.toLowerCase().includes(query) ||
            r.babysitter?.email?.toLowerCase().includes(query)
        );
      }

      const total = await VerificationRequest.countDocuments(filter);

      res.set('X-Page', String(page));
      res.set('X-Limit', String(limit));
      res.set('X-Total', String(total));
      res.set('X-Has-More', String(skip + limit < total));

      return ApiResponse.success(res, requests, 'Verification requests retrieved');
    }

    // Memory Fallback
    initSampleVerifications();
    let list = Array.from(memoryVerifications.values());

    if (status && status !== 'all') {
      list = list.filter((r) => r.status.toLowerCase() === status.toLowerCase());
    }

    if (search && search.trim()) {
      const query = search.trim().toLowerCase();
      list = list.filter(
        (r) =>
          r.babysitter?.name?.toLowerCase().includes(query) ||
          r.babysitter?.email?.toLowerCase().includes(query)
      );
    }

    const total = list.length;
    const paged = list.slice(skip, skip + limit);

    res.set('X-Page', String(page));
    res.set('X-Limit', String(limit));
    res.set('X-Total', String(total));
    res.set('X-Has-More', String(skip + limit < total));

    return ApiResponse.success(res, paged, 'Verification requests retrieved');
  } catch (err) {
    next(err);
  }
}

/**
 * GET /api/v1/agency/verifications/:id
 * Retrieve details of a specific verification request
 */
async function getById(req, res, next) {
  try {
    const { id } = req.params;

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(id)) {
      const request = await VerificationRequest.findById(id)
        .populate('babysitter', 'name email phone avatar')
        .populate('babysitterProfile')
        .populate('reviewedBy', 'name email role')
        .lean();

      if (!request) return next(new ApiError(404, 'Verification request not found'));
      return ApiResponse.success(res, request, 'Verification details retrieved');
    }

    initSampleVerifications();
    const request = memoryVerifications.get(id);
    if (!request) return next(new ApiError(404, 'Verification request not found'));

    return ApiResponse.success(res, request, 'Verification details retrieved');
  } catch (err) {
    next(err);
  }
}

/**
 * PATCH /api/v1/agency/verifications/:id/approve
 * Approve babysitter verification request
 */
async function approve(req, res, next) {
  try {
    const { id } = req.params;
    const { notes } = req.body;
    const adminUser = req.user;

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(id)) {
      const request = await VerificationRequest.findById(id);
      if (!request) return next(new ApiError(404, 'Verification request not found'));

      request.status = 'verified';
      request.reviewNotes = notes || request.reviewNotes || 'Approved by agency';
      request.reviewedBy = adminUser?._id;
      request.reviewedAt = new Date();
      await request.save();

      // Update BabysitterProfile
      if (request.babysitterProfile) {
        await BabysitterProfile.findByIdAndUpdate(request.babysitterProfile, {
          verificationStatus: 'verified',
        });
      }

      // Create AuditLog
      try {
        await AuditLog.create({
          actor: adminUser?._id,
          action: 'approve_verification',
          targetType: 'VerificationRequest',
          targetId: id,
          notes: notes || 'Babysitter profile verified and approved',
          metadata: { babysitterId: request.babysitter },
        });
      } catch (logErr) {
        // continue
      }

      // Notify Babysitter
      try {
        await Notification.create({
          user: request.babysitter,
          title: 'Profile Approved & Verified',
          message: 'Your babysitter profile has been approved! Parents can now find and book you.',
          type: 'verification_approved',
          data: { verificationId: id },
        });
      } catch (notifErr) {
        // continue
      }

      return ApiResponse.success(res, request, 'Verification request approved successfully');
    }

    // Memory Fallback
    initSampleVerifications();
    const request = memoryVerifications.get(id);
    if (!request) return next(new ApiError(404, 'Verification request not found'));

    request.status = 'verified';
    request.reviewNotes = notes || 'Approved by agency';
    request.reviewedAt = new Date();
    request.reviewedBy = adminUser?.name || 'Agency Admin';
    if (request.babysitterProfile) {
      request.babysitterProfile.verificationStatus = 'verified';
    }
    memoryVerifications.set(id, request);

    return ApiResponse.success(res, request, 'Verification request approved successfully');
  } catch (err) {
    next(err);
  }
}

/**
 * PATCH /api/v1/agency/verifications/:id/reject
 * Reject babysitter verification request
 */
async function reject(req, res, next) {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const adminUser = req.user;

    if (!reason || !reason.trim()) {
      return next(new ApiError(400, 'Rejection reason is required'));
    }

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(id)) {
      const request = await VerificationRequest.findById(id);
      if (!request) return next(new ApiError(404, 'Verification request not found'));

      request.status = 'rejected';
      request.reviewNotes = reason.trim();
      request.reviewedBy = adminUser?._id;
      request.reviewedAt = new Date();
      await request.save();

      if (request.babysitterProfile) {
        await BabysitterProfile.findByIdAndUpdate(request.babysitterProfile, {
          verificationStatus: 'rejected',
        });
      }

      try {
        await AuditLog.create({
          actor: adminUser?._id,
          action: 'reject_verification',
          targetType: 'VerificationRequest',
          targetId: id,
          notes: reason.trim(),
          metadata: { babysitterId: request.babysitter },
        });
      } catch (logErr) {
        // continue
      }

      try {
        await Notification.create({
          user: request.babysitter,
          title: 'Verification Request Rejected',
          message: `Your verification request was rejected. Reason: ${reason.trim()}`,
          type: 'verification_rejected',
          data: { verificationId: id, reason: reason.trim() },
        });
      } catch (notifErr) {
        // continue
      }

      return ApiResponse.success(res, request, 'Verification request rejected');
    }

    // Memory Fallback
    initSampleVerifications();
    const request = memoryVerifications.get(id);
    if (!request) return next(new ApiError(404, 'Verification request not found'));

    request.status = 'rejected';
    request.reviewNotes = reason.trim();
    request.reviewedAt = new Date();
    request.reviewedBy = adminUser?.name || 'Agency Admin';
    if (request.babysitterProfile) {
      request.babysitterProfile.verificationStatus = 'rejected';
    }
    memoryVerifications.set(id, request);

    return ApiResponse.success(res, request, 'Verification request rejected');
  } catch (err) {
    next(err);
  }
}

/**
 * PATCH /api/v1/agency/verifications/:id/request-changes
 * Request changes for babysitter verification request
 */
async function requestChanges(req, res, next) {
  try {
    const { id } = req.params;
    const { notes } = req.body;
    const adminUser = req.user;

    if (!notes || !notes.trim()) {
      return next(new ApiError(400, 'Instructions / notes for required changes are required'));
    }

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(id)) {
      const request = await VerificationRequest.findById(id);
      if (!request) return next(new ApiError(404, 'Verification request not found'));

      request.status = 'changes_requested';
      request.reviewNotes = notes.trim();
      request.reviewedBy = adminUser?._id;
      request.reviewedAt = new Date();
      await request.save();

      if (request.babysitterProfile) {
        await BabysitterProfile.findByIdAndUpdate(request.babysitterProfile, {
          verificationStatus: 'changes_requested',
        });
      }

      try {
        await AuditLog.create({
          actor: adminUser?._id,
          action: 'request_changes_verification',
          targetType: 'VerificationRequest',
          targetId: id,
          notes: notes.trim(),
          metadata: { babysitterId: request.babysitter },
        });
      } catch (logErr) {
        // continue
      }

      try {
        await Notification.create({
          user: request.babysitter,
          title: 'Verification Changes Requested',
          message: `The agency has requested additional information or updated documents: ${notes.trim()}`,
          type: 'system',
          data: { verificationId: id, notes: notes.trim() },
        });
      } catch (notifErr) {
        // continue
      }

      return ApiResponse.success(res, request, 'Changes requested successfully');
    }

    // Memory Fallback
    initSampleVerifications();
    const request = memoryVerifications.get(id);
    if (!request) return next(new ApiError(404, 'Verification request not found'));

    request.status = 'changes_requested';
    request.reviewNotes = notes.trim();
    request.reviewedAt = new Date();
    request.reviewedBy = adminUser?.name || 'Agency Admin';
    if (request.babysitterProfile) {
      request.babysitterProfile.verificationStatus = 'changes_requested';
    }
    memoryVerifications.set(id, request);

    return ApiResponse.success(res, request, 'Changes requested successfully');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  list,
  getById,
  approve,
  reject,
  requestChanges,
  memoryVerifications,
};
