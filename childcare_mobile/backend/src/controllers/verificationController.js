const mongoose = require('mongoose');
const VerificationRequest = require('../models/VerificationRequest');
const BabysitterProfile = require('../models/BabysitterProfile');
const User = require('../models/User');
const AuditLog = require('../models/AuditLog');
const Notification = require('../models/Notification');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');
const pagination = require('../utils/pagination');
const verificationService = require('../services/verificationService');

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
      await verificationService.syncVerificationRequests();
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

async function findVerificationFlexible(id) {
  if (!id) return null;
  const cleanId = id.toString().trim();

  if (isDbConnected()) {
    if (mongoose.Types.ObjectId.isValid(cleanId)) {
      let r = await VerificationRequest.findById(cleanId);
      if (r) return r;

      r = await VerificationRequest.findOne({
        $or: [{ babysitter: cleanId }, { babysitterProfile: cleanId }],
      });
      if (r) return r;

      try {
        const bp = await BabysitterProfile.findOne({
          $or: [{ _id: cleanId }, { user: cleanId }],
        });
        if (bp) {
          await verificationService.syncVerificationRequests();
          const synced = await VerificationRequest.findOne({
            $or: [{ babysitter: bp.user }, { babysitterProfile: bp._id }],
          });
          if (synced) return synced;
        }
      } catch (_) {}
    }

    try {
      const r = await VerificationRequest.findOne({
        $or: [{ id: cleanId }, { _id: cleanId }],
      });
      if (r) return r;
    } catch (_) {}
  }

  initSampleVerifications();
  let mem = memoryVerifications.get(cleanId);
  if (!mem) {
    const lower = cleanId.toLowerCase();
    mem = Array.from(memoryVerifications.values()).find(
      (v) =>
        v._id === cleanId ||
        v.id === cleanId ||
        v.babysitter?._id === cleanId ||
        v.babysitter?.id === cleanId ||
        v.babysitter?.email?.toLowerCase() === lower ||
        v.babysitter?.phone === cleanId
    );
  }
  return mem || null;
}

/**
 * GET /api/v1/agency/verifications/:id
 * Retrieve details of a specific verification request
 */
async function getById(req, res, next) {
  try {
    const { id } = req.params;
    const request = await findVerificationFlexible(id);
    if (!request) return next(new ApiError(404, 'Verification request not found'));

    if (request.toObject) {
      return ApiResponse.success(res, request.toObject(), 'Verification details retrieved');
    }
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

    const request = await findVerificationFlexible(id);
    if (!request) return next(new ApiError(404, 'Verification request not found'));

    const approvalNote = notes || request.reviewNotes || 'Approved by agency';
    const now = new Date();

    if (request.save) {
      request.status = 'verified';
      request.reviewNotes = approvalNote;
      request.reviewedAt = now;
      if (adminUser?._id && mongoose.Types.ObjectId.isValid(adminUser._id)) {
        request.reviewedBy = adminUser._id;
      }
      if (Array.isArray(request.documents)) {
        request.documents.forEach((d) => {
          d.status = 'verified';
        });
      }
      await request.save();

      // Update BabysitterProfile AND documents
      const profile = await BabysitterProfile.findOne({
        $or: [{ _id: request.babysitterProfile }, { user: request.babysitter }],
      });
      if (profile) {
        profile.verificationStatus = 'verified';
        profile.verificationReviewedAt = now;
        profile.verificationReviewedBy =
          adminUser?._id && mongoose.Types.ObjectId.isValid(adminUser._id)
            ? adminUser._id
            : null;
        profile.verificationNotes = approvalNote;
        if (Array.isArray(profile.documents)) {
          profile.documents.forEach((d) => {
            d.status = 'verified';
          });
        }
        await profile.save();
      }

      // Create AuditLog
      try {
        await AuditLog.create({
          actor:
            adminUser?._id && mongoose.Types.ObjectId.isValid(adminUser._id)
              ? adminUser._id
              : null,
          adminName: adminUser?.name || 'Agency Administrator',
          adminEmail: adminUser?.email || '',
          action: 'approve_verification',
          targetType: 'VerificationRequest',
          targetId: request._id ? request._id.toString() : id,
          notes: approvalNote,
          metadata: { babysitterId: request.babysitter },
        });
      } catch (logErr) {}

      // Notify Babysitter
      try {
        await Notification.create({
          user: request.babysitter,
          title: 'Profile Approved & Verified',
          message: 'Your babysitter profile has been approved! Parents can now find and book you in the catalog.',
          type: 'verification_approved',
          data: { verificationId: request._id ? request._id.toString() : id },
        });
      } catch (notifErr) {}

      return ApiResponse.success(res, request, 'Verification request approved successfully');
    }

    // In-memory fallback
    request.status = 'verified';
    request.reviewNotes = approvalNote;
    request.reviewedAt = now;
    request.reviewedBy = adminUser?.name || 'Agency Admin';
    if (Array.isArray(request.documents)) {
      request.documents.forEach((d) => {
        d.status = 'verified';
      });
    }
    if (request.babysitterProfile) {
      request.babysitterProfile.verificationStatus = 'verified';
      request.babysitterProfile.verificationNotes = request.reviewNotes;
    }
    memoryVerifications.set(request.id || request._id || id, request);

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
    const reason = (req.body.reason || req.body.notes || '').trim();
    const adminUser = req.user;

    if (!reason) {
      return next(new ApiError(400, 'Rejection reason is required'));
    }

    const request = await findVerificationFlexible(id);
    if (!request) return next(new ApiError(404, 'Verification request not found'));

    const now = new Date();

    if (request.save) {
      request.status = 'rejected';
      request.reviewNotes = reason;
      request.reviewedAt = now;
      if (adminUser?._id && mongoose.Types.ObjectId.isValid(adminUser._id)) {
        request.reviewedBy = adminUser._id;
      }
      if (Array.isArray(request.documents)) {
        request.documents.forEach((d) => {
          d.status = 'rejected';
        });
      }
      await request.save();

      const profile = await BabysitterProfile.findOne({
        $or: [{ _id: request.babysitterProfile }, { user: request.babysitter }],
      });
      if (profile) {
        profile.verificationStatus = 'rejected';
        profile.verificationReviewedAt = now;
        profile.verificationReviewedBy =
          adminUser?._id && mongoose.Types.ObjectId.isValid(adminUser._id)
            ? adminUser._id
            : null;
        profile.verificationNotes = reason;
        if (Array.isArray(profile.documents)) {
          profile.documents.forEach((d) => {
            d.status = 'rejected';
          });
        }
        await profile.save();
      }

      try {
        await AuditLog.create({
          actor:
            adminUser?._id && mongoose.Types.ObjectId.isValid(adminUser._id)
              ? adminUser._id
              : null,
          adminName: adminUser?.name || 'Agency Administrator',
          adminEmail: adminUser?.email || '',
          action: 'reject_verification',
          targetType: 'VerificationRequest',
          targetId: request._id ? request._id.toString() : id,
          notes: reason,
          metadata: { babysitterId: request.babysitter },
        });
      } catch (logErr) {}

      try {
        await Notification.create({
          user: request.babysitter,
          title: 'Verification Request Rejected',
          message: `Your verification request was rejected. Reason: ${reason}`,
          type: 'verification_rejected',
          data: { verificationId: request._id ? request._id.toString() : id, reason },
        });
      } catch (notifErr) {}

      return ApiResponse.success(res, request, 'Verification request rejected');
    }

    // In-memory fallback
    request.status = 'rejected';
    request.reviewNotes = reason;
    request.reviewedAt = now;
    request.reviewedBy = adminUser?.name || 'Agency Admin';
    if (Array.isArray(request.documents)) {
      request.documents.forEach((d) => { d.status = 'rejected'; });
    }
    if (request.babysitterProfile) {
      request.babysitterProfile.verificationStatus = 'rejected';
      request.babysitterProfile.verificationNotes = reason;
      if (Array.isArray(request.babysitterProfile.documents)) {
        request.babysitterProfile.documents.forEach((d) => { d.status = 'rejected'; });
      }
    }
    memoryVerifications.set(request.id || request._id || id, request);

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
    const notes = (req.body.notes || req.body.reason || '').trim();
    const adminUser = req.user;

    if (!notes) {
      return next(new ApiError(400, 'Instructions / notes for required changes are required'));
    }

    const request = await findVerificationFlexible(id);
    if (!request) return next(new ApiError(404, 'Verification request not found'));

    const now = new Date();

    if (request.save) {
      request.status = 'changes_requested';
      request.reviewNotes = notes;
      request.reviewedAt = now;
      if (adminUser?._id && mongoose.Types.ObjectId.isValid(adminUser._id)) {
        request.reviewedBy = adminUser._id;
      }
      if (Array.isArray(request.documents)) {
        request.documents.forEach((d) => {
          d.status = 'changes_requested';
        });
      }
      await request.save();

      const profile = await BabysitterProfile.findOne({
        $or: [{ _id: request.babysitterProfile }, { user: request.babysitter }],
      });
      if (profile) {
        profile.verificationStatus = 'changes_requested';
        profile.verificationReviewedAt = now;
        profile.verificationReviewedBy =
          adminUser?._id && mongoose.Types.ObjectId.isValid(adminUser._id)
            ? adminUser._id
            : null;
        profile.verificationNotes = notes;
        if (Array.isArray(profile.documents)) {
          profile.documents.forEach((d) => {
            d.status = 'changes_requested';
          });
        }
        await profile.save();
      }

      try {
        await AuditLog.create({
          actor:
            adminUser?._id && mongoose.Types.ObjectId.isValid(adminUser._id)
              ? adminUser._id
              : null,
          adminName: adminUser?.name || 'Agency Administrator',
          adminEmail: adminUser?.email || '',
          action: 'request_changes_verification',
          targetType: 'VerificationRequest',
          targetId: request._id ? request._id.toString() : id,
          notes,
          metadata: { babysitterId: request.babysitter },
        });
      } catch (logErr) {}

      try {
        await Notification.create({
          user: request.babysitter,
          title: 'Verification Changes Requested',
          message: `The agency has requested additional information or updated documents: ${notes}`,
          type: 'verification_changes_requested',
          data: { verificationId: request._id ? request._id.toString() : id, notes },
        });
      } catch (notifErr) {}

      return ApiResponse.success(res, request, 'Changes requested successfully');
    }

    // In-memory fallback
    request.status = 'changes_requested';
    request.reviewNotes = notes;
    request.reviewedAt = now;
    request.reviewedBy = adminUser?.name || 'Agency Admin';
    if (Array.isArray(request.documents)) {
      request.documents.forEach((d) => { d.status = 'changes_requested'; });
    }
    if (request.babysitterProfile) {
      request.babysitterProfile.verificationStatus = 'changes_requested';
      request.babysitterProfile.verificationNotes = notes;
      if (Array.isArray(request.babysitterProfile.documents)) {
        request.babysitterProfile.documents.forEach((d) => { d.status = 'changes_requested'; });
      }
    }
    memoryVerifications.set(request.id || request._id || id, request);

    return ApiResponse.success(res, request, 'Changes requested successfully');
  } catch (err) {
    next(err);
  }
}

/**
 * POST /api/v1/verifications/submit
 * Babysitter submits documents for verification
 */
async function submitVerification(req, res, next) {
  try {
    const userId = req.user?.id || req.user?._id;
    const { documents } = req.body;

    if (!Array.isArray(documents) || documents.length === 0) {
      return next(new ApiError(400, 'At least one verification document is required'));
    }

    const validDocs = documents.every((d) => d && d.url && d.name);
    if (!validDocs) {
      return next(new ApiError(400, 'Each document must have a valid name and URL'));
    }

    if (isDbConnected()) {
      const docItems = documents.map((d) => ({
        type: d.type || 'certificate',
        name: d.name,
        url: d.url,
        status: 'pending',
        uploadedAt: new Date(),
      }));

      let request = await VerificationRequest.findOne({ babysitter: userId });
      if (request) {
        request.documents = docItems;
        request.status = 'pending';
        request.reviewNotes = '';
        request.submittedAt = new Date();
        await request.save();
      } else {
        const sitterProfile = await BabysitterProfile.findOne({ user: userId });
        request = await VerificationRequest.create({
          babysitter: userId,
          babysitterProfile: sitterProfile?._id,
          status: 'pending',
          documents: docItems,
          submittedAt: new Date(),
        });
      }

      await BabysitterProfile.findOneAndUpdate(
        { user: userId },
        {
          verificationStatus: 'pending',
          verificationNotes: '',
          documents: docItems,
        }
      );

      // Notify agency admins
      try {
        await Notification.create({
          user: userId,
          title: 'Verification Documents Received',
          message: 'Your verification submission has been received and is queued for administrative review.',
          type: 'system',
          data: { verificationId: request._id },
        });
      } catch (e) {
        // continue
      }

      return ApiResponse.success(res, request, 'Verification documents submitted successfully', 201);
    }

    // Memory Fallback
    initSampleVerifications();
    let existing = Array.from(memoryVerifications.values()).find(
      (v) => (v.babysitter?._id || v.babysitter?.id) === userId
    );

    const docItems = documents.map((d) => ({
      type: d.type || 'certificate',
      name: d.name,
      url: d.url,
      status: 'pending',
      uploadedAt: new Date(),
    }));

    if (existing) {
      existing.documents = docItems;
      existing.status = 'pending';
      existing.reviewNotes = '';
      existing.submittedAt = new Date();
      memoryVerifications.set(existing._id, existing);
    } else {
      const newId = `ver-${Date.now()}`;
      existing = {
        _id: newId,
        id: newId,
        babysitter: {
          _id: userId,
          id: userId,
          name: req.user?.name || 'Babysitter',
          email: req.user?.email || 'sitter@example.com',
        },
        babysitterProfile: {
          verificationStatus: 'pending',
        },
        status: 'pending',
        documents: docItems,
        submittedAt: new Date(),
        createdAt: new Date(),
      };
      memoryVerifications.set(newId, existing);
    }

    return ApiResponse.success(res, existing, 'Verification documents submitted successfully', 201);
  } catch (err) {
    next(err);
  }
}

/**
 * GET /api/v1/verifications/my-status
 * Babysitter checks own verification submission status
 */
async function getMyVerificationStatus(req, res, next) {
  try {
    const userId = req.user?.id || req.user?._id;

    if (isDbConnected()) {
      let request = await VerificationRequest.findOne({ babysitter: userId }).lean();
      if (!request) {
        const profile = await BabysitterProfile.findOne({ user: userId }).lean();
        if (profile) {
          return ApiResponse.success(
            res,
            {
              status: profile.verificationStatus || 'pending',
              documents: profile.documents || [],
              reviewNotes: profile.verificationNotes || '',
              reviewedAt: profile.verificationReviewedAt,
            },
            'Verification status retrieved'
          );
        }
        return ApiResponse.success(
          res,
          { status: 'unverified', documents: [], reviewNotes: '' },
          'Verification status retrieved'
        );
      }
      return ApiResponse.success(res, request, 'Verification status retrieved');
    }

    initSampleVerifications();
    const existing = Array.from(memoryVerifications.values()).find(
      (v) => (v.babysitter?._id || v.babysitter?.id) === userId
    );

    if (!existing) {
      return ApiResponse.success(
        res,
        { status: 'unverified', documents: [], reviewNotes: '' },
        'Verification status retrieved (mock)'
      );
    }

    return ApiResponse.success(res, existing, 'Verification status retrieved (mock)');
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
  submitVerification,
  getMyVerificationStatus,
  memoryVerifications,
};
