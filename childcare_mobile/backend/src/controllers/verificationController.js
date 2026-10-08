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
const babysitterService = require('../services/babysitterService');

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
        const s = status.toLowerCase();
        if (s === 'pending' || s === 'under_review') {
          filter.$or = [
            { status: { $in: ['pending', 'under_review'] } },
            { 'documents.status': { $in: ['pending', 'under_review'] } },
            { 'qualifications.status': { $in: ['pending', 'under_review'] } },
          ];
        } else if (s === 'verified') {
          filter.status = 'verified';
          filter['documents.status'] = { $nin: ['pending', 'under_review', 'changes_requested'] };
        } else if (s === 'rejected') {
          filter.$or = [
            { status: 'rejected' },
            { 'documents.status': 'rejected' },
          ];
        } else {
          filter.status = status;
        }
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
    try {
      const { memoryBabysitters } = require('../services/babysitterService');
      if (memoryBabysitters && memoryBabysitters.size > 0) {
        for (const [sId, p] of memoryBabysitters.entries()) {
          const docs = Array.isArray(p.documents) ? p.documents : [];
          const quals = Array.isArray(p.qualifications) ? p.qualifications : [];
          const hasPending =
            docs.some((d) => ['pending', 'under_review'].includes(d.status)) ||
            quals.some((q) => typeof q === 'object' && ['pending', 'under_review'].includes(q.status));
          let existing = Array.from(memoryVerifications.values()).find(
            (v) => (v.babysitter?._id || v.babysitter?.id || v.babysitter) === sId
          );
          if (existing) {
            existing.documents = docs.length > 0 ? docs : existing.documents;
            existing.qualifications = quals.length > 0 ? quals : existing.qualifications;
            if (hasPending) existing.status = 'pending';
          } else {
            const sampleDocs = [
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
            const effectiveDocs = docs.length > 0 ? docs : sampleDocs;
            const newMem = {
              _id: `ver-${sId}`,
              id: `ver-${sId}`,
              babysitter: p.user || {
                _id: sId,
                id: sId,
                name: p.name || 'Caregiver',
                email: p.email || '',
                phone: p.phone || '',
                avatar: p.avatar || p.profileImage || '',
              },
              babysitterProfile: p,
              status: hasPending ? 'pending' : (p.verificationStatus || 'pending'),
              documents: effectiveDocs,
              qualifications: quals,
              reviewNotes: '',
              submittedAt: new Date(),
              createdAt: new Date(),
            };
            memoryVerifications.set(newMem._id, newMem);
          }
        }
      }
    } catch (_) {}

    let list = Array.from(memoryVerifications.values());

    if (status && status !== 'all') {
      const s = status.toLowerCase();
      if (s === 'pending' || s === 'under_review') {
        list = list.filter((r) => {
          const reqStatus = (r.status || '').toLowerCase();
          if (['pending', 'under_review'].includes(reqStatus)) return true;
          const hasPendingDoc =
            Array.isArray(r.documents) &&
            r.documents.some((d) => ['pending', 'under_review'].includes((d.status || '').toLowerCase()));
          const hasPendingQual =
            Array.isArray(r.qualifications) &&
            r.qualifications.some((q) => typeof q === 'object' && ['pending', 'under_review'].includes((q.status || '').toLowerCase()));
          return hasPendingDoc || hasPendingQual;
        });
      } else if (s === 'verified') {
        list = list.filter((r) => {
          const reqStatus = (r.status || '').toLowerCase();
          const hasPendingDoc =
            Array.isArray(r.documents) &&
            r.documents.some((d) => ['pending', 'under_review', 'changes_requested'].includes((d.status || '').toLowerCase()));
          return reqStatus === 'verified' && !hasPendingDoc;
        });
      } else if (s === 'rejected') {
        list = list.filter((r) => {
          const reqStatus = (r.status || '').toLowerCase();
          const hasRejDoc =
            Array.isArray(r.documents) &&
            r.documents.some((d) => (d.status || '').toLowerCase() === 'rejected');
          return reqStatus === 'rejected' || hasRejDoc;
        });
      } else {
        list = list.filter((r) => (r.status || '').toLowerCase() === s);
      }
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
    const popQuery = (q) =>
      q.populate('babysitter', 'name email phone avatar')
       .populate('babysitterProfile', 'experienceYears hourlyRate verificationStatus address skills languages qualifications documents bio dateOfBirth gender');

    if (mongoose.Types.ObjectId.isValid(cleanId)) {
      let r = await popQuery(VerificationRequest.findById(cleanId));
      if (r) return r;

      r = await popQuery(
        VerificationRequest.findOne({
          $or: [{ babysitter: cleanId }, { babysitterProfile: cleanId }],
        })
      );
      if (r) return r;

      try {
        const bp = await BabysitterProfile.findOne({
          $or: [{ _id: cleanId }, { user: cleanId }],
        });
        if (bp) {
          await verificationService.syncVerificationRequests();
          const synced = await popQuery(
            VerificationRequest.findOne({
              $or: [{ babysitter: bp.user }, { babysitterProfile: bp._id }],
            })
          );
          if (synced) return synced;
        }
      } catch (_) {}
    }

    try {
      const r = await popQuery(
        VerificationRequest.findOne({
          $or: [{ id: cleanId }, { _id: cleanId }],
        })
      );
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

async function findProfileForVerification(request) {
  if (!isDbConnected() || !request) return null;
  try {
    const orConditions = [];
    const pId = request.babysitterProfile?._id || request.babysitterProfile;
    const uId = request.babysitter?._id || request.babysitter;
    if (pId && mongoose.Types.ObjectId.isValid(pId)) {
      orConditions.push({ _id: pId });
    }
    if (uId && mongoose.Types.ObjectId.isValid(uId)) {
      orConditions.push({ user: uId });
    }
    if (orConditions.length === 0) return null;
    return await BabysitterProfile.findOne({ $or: orConditions });
  } catch (_) {
    return null;
  }
}

/**
 * GET /api/v1/agency/verifications/:id
 * Retrieve details of a specific verification request
 */
async function getById(req, res, next) {
  try {
    const { id } = req.params;
    let request = await findVerificationFlexible(id);
    if (!request) return next(new ApiError(404, 'Verification request not found'));

    // Reconcile documents from profile if any missing in request
    const profile = await findProfileForVerification(request);
    if (profile && Array.isArray(profile.documents)) {
      const reqDocs = Array.isArray(request.documents) ? request.documents : [];
      let updated = false;
      for (const pDoc of profile.documents) {
        const found = reqDocs.find(
          (d) =>
            (d._id && pDoc._id && d._id.toString() === pDoc._id.toString()) ||
            d.name === pDoc.name ||
            (pDoc.documentNumber && d.documentNumber && d.documentNumber === pDoc.documentNumber)
        );
        if (!found) {
          reqDocs.push({
            _id: pDoc._id || new mongoose.Types.ObjectId(),
            type: pDoc.type || 'other',
            name: pDoc.name || 'Document',
            label: pDoc.label || pDoc.name,
            documentNumber: pDoc.documentNumber || '',
            url: pDoc.url || pDoc.fileUrl || 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=800',
            fileUrl: pDoc.fileUrl || pDoc.url || 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=800',
            status: pDoc.status || 'pending',
            uploadedAt: pDoc.uploadedAt || new Date(),
          });
          updated = true;
        }
      }
      if (updated && request.save) {
        request.documents = reqDocs;
        await request.save();
      }
    }

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

    // Safety guard: cannot approve overall verification if any document is rejected or has changes requested
    if (Array.isArray(request.documents) && request.documents.length > 0) {
      const hasUnresolved = request.documents.some((d) => ['rejected', 'changes_requested'].includes(d.status));
      if (hasUnresolved) {
        return next(new ApiError(400, 'Cannot approve sitter while verification documents are rejected or have requested changes.'));
      }
    }

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
          if (d.status !== 'rejected' && d.status !== 'changes_requested') {
            d.status = 'verified';
          }
        });
      }
      await request.save();

      // Update BabysitterProfile AND documents
      const profile = await findProfileForVerification(request);
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
            if (d.status !== 'rejected' && d.status !== 'changes_requested') {
              d.status = 'verified';
            }
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
        if (d.status !== 'rejected' && d.status !== 'changes_requested') {
          d.status = 'verified';
        }
      });
    }
    if (request.babysitterProfile) {
      request.babysitterProfile.verificationStatus = 'verified';
      request.babysitterProfile.verificationNotes = request.reviewNotes;
    }
    memoryVerifications.set(request.id || request._id || id, request);

    const sitterId = request.babysitter?._id || request.babysitter?.id || request.babysitter;
    if (sitterId) {
      try {
        await babysitterService.updateProfileByUserId(
          sitterId,
          {
            verificationStatus: 'verified',
            verificationNotes: approvalNote,
            documents: request.documents,
            ...(Array.isArray(request.qualifications) ? { qualifications: request.qualifications } : {}),
          },
          true
        );
      } catch (_) {}
    }

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

      const profile = await findProfileForVerification(request);
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

    const sitterId = request.babysitter?._id || request.babysitter?.id || request.babysitter;
    if (sitterId) {
      try {
        await babysitterService.updateProfileByUserId(
          sitterId,
          {
            verificationStatus: 'rejected',
            verificationNotes: reason,
            documents: request.documents,
            ...(Array.isArray(request.qualifications) ? { qualifications: request.qualifications } : {}),
          },
          true
        );
      } catch (_) {}
    }

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

      const profile = await findProfileForVerification(request);
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

    const sitterId = request.babysitter?._id || request.babysitter?.id || request.babysitter;
    if (sitterId) {
      try {
        await babysitterService.updateProfileByUserId(
          sitterId,
          {
            verificationStatus: 'changes_requested',
            verificationNotes: notes,
            documents: request.documents,
            ...(Array.isArray(request.qualifications) ? { qualifications: request.qualifications } : {}),
          },
          true
        );
      } catch (_) {}
    }

    return ApiResponse.success(res, request, 'Changes requested successfully');
  } catch (err) {
    next(err);
  }
}

/**
 * Helper to match document in request
 */
function findDoc(docs, docId) {
  if (!Array.isArray(docs)) return null;
  return docs.find(
    (d) =>
      d._id?.toString() === docId ||
      d.id?.toString() === docId ||
      d.name === docId ||
      d.type === docId ||
      d.documentNumber === docId
  );
}

/**
 * Helper to match qualification in request or profile
 */
function findQual(quals, qualId) {
  if (!Array.isArray(quals)) return null;
  return quals.find((q) => {
    if (typeof q === 'string') return q === qualId;
    return (
      q._id?.toString() === qualId ||
      q.id?.toString() === qualId ||
      q.title === qualId
    );
  });
}

/**
 * PATCH /api/v1/agency/verifications/:verificationId/documents/:documentId/approve
 */
async function approveDocument(req, res, next) {
  try {
    const { verificationId, documentId } = req.params;
    const adminUser = req.user;
    const now = new Date();

    const request = await findVerificationFlexible(verificationId);
    if (!request) return next(new ApiError(404, 'Verification request not found'));

    const doc = findDoc(request.documents, documentId);
    if (!doc) return next(new ApiError(404, 'Target document not found in verification request'));

    doc.status = 'verified';
    doc.reviewNotes = null;
    doc.reviewedAt = now;
    if (adminUser?._id && mongoose.Types.ObjectId.isValid(adminUser._id)) {
      doc.reviewedBy = adminUser._id;
    } else {
      doc.reviewedBy = adminUser?.name || 'Agency Admin';
    }

    if (request.save) {
      const profile = await findProfileForVerification(request);
      if (profile && Array.isArray(profile.documents)) {
        const pDoc = findDoc(profile.documents, documentId) || profile.documents.find((d) => d.name === doc.name);
        if (pDoc) {
          pDoc.status = 'verified';
          pDoc.reviewNotes = null;
          pDoc.reviewedAt = now;
          pDoc.reviewedBy = adminUser?._id && mongoose.Types.ObjectId.isValid(adminUser._id) ? adminUser._id : null;
        }
      }

      const allDocsVer = Array.isArray(request.documents) && request.documents.every((d) => d.status === 'verified');
      const allQualsVer = !Array.isArray(request.qualifications) || request.qualifications.every((q) => typeof q === 'string' || q.status === 'verified');
      if (allDocsVer && allQualsVer && request.documents.length > 0) {
        request.status = 'verified';
        if (profile) profile.verificationStatus = 'verified';
      }

      await request.save();
      if (profile) await profile.save();

      try {
        await Notification.create({
          user: request.babysitter,
          title: 'Document Verified',
          message: `Your document "${doc.name}" has been verified.`,
          type: 'document_verified',
          data: { verificationId, documentId: doc._id || documentId },
        });
      } catch (_) {}

      return ApiResponse.success(res, { verification: request, document: doc }, 'Document verified successfully');
    }

    // In-memory fallback
    if (request.babysitterProfile && Array.isArray(request.babysitterProfile.documents)) {
      const pDoc = findDoc(request.babysitterProfile.documents, documentId) || request.babysitterProfile.documents.find((d) => d.name === doc.name);
      if (pDoc) {
        pDoc.status = 'verified';
        pDoc.reviewNotes = null;
        pDoc.reviewedAt = now;
      }
    }
    memoryVerifications.set(request.id || request._id || verificationId, request);
    const sitterId = request.babysitter?._id || request.babysitter?.id || request.babysitter;
    if (sitterId) {
      try {
        await babysitterService.updateProfileByUserId(sitterId, { documents: request.documents }, true);
      } catch (_) {}
    }
    return ApiResponse.success(res, { verification: request, document: doc }, 'Document verified successfully');
  } catch (err) {
    next(err);
  }
}

/**
 * PATCH /api/v1/agency/verifications/:verificationId/documents/:documentId/reject
 */
async function rejectDocument(req, res, next) {
  try {
    const { verificationId, documentId } = req.params;
    const reason = req.body.reason || req.body.notes;
    if (!reason || !reason.trim()) {
      return next(new ApiError(400, 'Rejection reason is required.'));
    }
    const adminUser = req.user;
    const now = new Date();

    const request = await findVerificationFlexible(verificationId);
    if (!request) return next(new ApiError(404, 'Verification request not found'));

    const doc = findDoc(request.documents, documentId);
    if (!doc) return next(new ApiError(404, 'Target document not found in verification request'));

    doc.status = 'rejected';
    doc.reviewNotes = reason.trim();
    doc.reviewedAt = now;
    if (adminUser?._id && mongoose.Types.ObjectId.isValid(adminUser._id)) {
      doc.reviewedBy = adminUser._id;
    } else {
      doc.reviewedBy = adminUser?.name || 'Agency Admin';
    }

    if (request.save) {
      await request.save();

      const profile = await findProfileForVerification(request);
      if (profile && Array.isArray(profile.documents)) {
        const pDoc = findDoc(profile.documents, documentId) || profile.documents.find((d) => d.name === doc.name);
        if (pDoc) {
          pDoc.status = 'rejected';
          pDoc.reviewNotes = reason.trim();
          pDoc.reviewedAt = now;
          pDoc.reviewedBy = adminUser?._id && mongoose.Types.ObjectId.isValid(adminUser._id) ? adminUser._id : null;
          await profile.save();
        }
      }

      try {
        await Notification.create({
          user: request.babysitter,
          title: 'Document Rejected',
          message: `Your document "${doc.name}" was rejected. Reason: ${reason.trim()}`,
          type: 'document_rejected',
          data: { verificationId, documentId: doc._id || documentId, reason: reason.trim() },
        });
      } catch (_) {}

      return ApiResponse.success(res, { verification: request, document: doc }, 'Document rejected successfully');
    }

    // In-memory fallback
    if (request.babysitterProfile && Array.isArray(request.babysitterProfile.documents)) {
      const pDoc = findDoc(request.babysitterProfile.documents, documentId) || request.babysitterProfile.documents.find((d) => d.name === doc.name);
      if (pDoc) {
        pDoc.status = 'rejected';
        pDoc.reviewNotes = reason.trim();
        pDoc.reviewedAt = now;
      }
    }
    memoryVerifications.set(request.id || request._id || verificationId, request);
    const sitterId = request.babysitter?._id || request.babysitter?.id || request.babysitter;
    if (sitterId) {
      try {
        await babysitterService.updateProfileByUserId(sitterId, { documents: request.documents }, true);
      } catch (_) {}
    }
    return ApiResponse.success(res, { verification: request, document: doc }, 'Document rejected successfully');
  } catch (err) {
    next(err);
  }
}

/**
 * PATCH /api/v1/agency/verifications/:verificationId/documents/:documentId/request-changes
 */
async function requestChangesDocument(req, res, next) {
  try {
    const { verificationId, documentId } = req.params;
    const notes = req.body.notes || req.body.reason;
    if (!notes || !notes.trim()) {
      return next(new ApiError(400, 'Instructions / notes are required when requesting changes.'));
    }
    const adminUser = req.user;
    const now = new Date();

    const request = await findVerificationFlexible(verificationId);
    if (!request) return next(new ApiError(404, 'Verification request not found'));

    const doc = findDoc(request.documents, documentId);
    if (!doc) return next(new ApiError(404, 'Target document not found in verification request'));

    doc.status = 'changes_requested';
    doc.reviewNotes = notes.trim();
    doc.reviewedAt = now;
    if (adminUser?._id && mongoose.Types.ObjectId.isValid(adminUser._id)) {
      doc.reviewedBy = adminUser._id;
    } else {
      doc.reviewedBy = adminUser?.name || 'Agency Admin';
    }

    if (request.save) {
      await request.save();

      const profile = await findProfileForVerification(request);
      if (profile && Array.isArray(profile.documents)) {
        const pDoc = findDoc(profile.documents, documentId) || profile.documents.find((d) => d.name === doc.name);
        if (pDoc) {
          pDoc.status = 'changes_requested';
          pDoc.reviewNotes = notes.trim();
          pDoc.reviewedAt = now;
          pDoc.reviewedBy = adminUser?._id && mongoose.Types.ObjectId.isValid(adminUser._id) ? adminUser._id : null;
          await profile.save();
        }
      }

      try {
        await Notification.create({
          user: request.babysitter,
          title: 'Changes Required',
          message: `Changes requested for document "${doc.name}": ${notes.trim()}`,
          type: 'document_changes_requested',
          data: { verificationId, documentId: doc._id || documentId, notes: notes.trim() },
        });
      } catch (_) {}

      return ApiResponse.success(res, { verification: request, document: doc }, 'Changes requested successfully');
    }

    // In-memory fallback
    if (request.babysitterProfile && Array.isArray(request.babysitterProfile.documents)) {
      const pDoc = findDoc(request.babysitterProfile.documents, documentId) || request.babysitterProfile.documents.find((d) => d.name === doc.name);
      if (pDoc) {
        pDoc.status = 'changes_requested';
        pDoc.reviewNotes = notes.trim();
        pDoc.reviewedAt = now;
      }
    }
    memoryVerifications.set(request.id || request._id || verificationId, request);
    const sitterId = request.babysitter?._id || request.babysitter?.id || request.babysitter;
    if (sitterId) {
      try {
        await babysitterService.updateProfileByUserId(sitterId, { documents: request.documents }, true);
      } catch (_) {}
    }
    return ApiResponse.success(res, { verification: request, document: doc }, 'Changes requested successfully');
  } catch (err) {
    next(err);
  }
}

/**
 * PATCH /api/v1/agency/verifications/:verificationId/qualifications/:qualificationId/approve
 */
async function approveQualification(req, res, next) {
  try {
    const { verificationId, qualificationId } = req.params;
    const adminUser = req.user;
    const now = new Date();

    const request = await findVerificationFlexible(verificationId);
    if (!request) return next(new ApiError(404, 'Verification request not found'));

    // Check request.qualifications or profile.qualifications
    let qual = findQual(request.qualifications, qualificationId);
    const profile = await findProfileForVerification(request);

    if (profile && Array.isArray(profile.qualifications)) {
      let pQual = findQual(profile.qualifications, qualificationId);
      if (pQual) {
        if (typeof pQual === 'string') {
          pQual = { title: pQual, status: 'verified', reviewedBy: adminUser?._id, reviewedAt: now };
          profile.qualifications = profile.qualifications.map((q) => (q === qualificationId ? pQual : q));
        } else {
          pQual.status = 'verified';
          pQual.reviewNotes = null;
          pQual.reviewedAt = now;
          pQual.reviewedBy = adminUser?._id && mongoose.Types.ObjectId.isValid(adminUser._id) ? adminUser._id : null;
        }
        await profile.save();
      }
      qual = qual || pQual;
    }

    if (!qual && request.babysitterProfile?.qualifications) {
      let pQual = findQual(request.babysitterProfile.qualifications, qualificationId);
      if (pQual) {
        if (typeof pQual === 'string') {
          pQual = { title: pQual, status: 'verified', reviewedAt: now };
        } else {
          pQual.status = 'verified';
          pQual.reviewNotes = null;
          pQual.reviewedAt = now;
        }
        qual = pQual;
      }
    }

    if (!qual) {
      // Create or record qualification as verified
      qual = { id: qualificationId, title: qualificationId, status: 'verified', reviewedAt: now };
    } else if (typeof qual === 'object') {
      qual.status = 'verified';
      qual.reviewNotes = null;
      qual.reviewedAt = now;
    }

    if (request.save) {
      const allDocsVer = Array.isArray(request.documents) && request.documents.every((d) => d.status === 'verified');
      const allQualsVer = !Array.isArray(request.qualifications) || request.qualifications.every((q) => typeof q === 'string' || q.status === 'verified');
      if (allDocsVer && allQualsVer && request.documents.length > 0) {
        request.status = 'verified';
        if (profile) profile.verificationStatus = 'verified';
      }
      await request.save();
      if (profile) await profile.save();
      try {
        await Notification.create({
          user: request.babysitter,
          title: 'Qualification Verified',
          message: `Your qualification "${qual.title || qualificationId}" has been verified.`,
          type: 'qualification_verified',
        });
      } catch (_) {}
      return ApiResponse.success(res, { verification: request, qualification: qual }, 'Qualification verified successfully');
    }

    // In-memory fallback
    if (Array.isArray(request.qualifications)) {
      const qIndex = request.qualifications.findIndex((q) => {
        if (typeof q === 'string') return q === qualificationId;
        return q._id?.toString() === qualificationId || q.id?.toString() === qualificationId || q.title === qualificationId;
      });
      if (qIndex !== -1) {
        request.qualifications[qIndex] = qual;
      } else {
        request.qualifications.push(qual);
      }
    } else {
      request.qualifications = [qual];
    }

    memoryVerifications.set(request.id || request._id || verificationId, request);
    const sitterId = request.babysitter?._id || request.babysitter?.id || request.babysitter;
    if (sitterId) {
      try {
        await babysitterService.updateProfileByUserId(sitterId, { qualifications: request.qualifications }, true);
      } catch (_) {}
    }

    return ApiResponse.success(res, { verification: request, qualification: qual }, 'Qualification verified successfully');
  } catch (err) {
    next(err);
  }
}

/**
 * PATCH /api/v1/agency/verifications/:verificationId/qualifications/:qualificationId/reject
 */
async function rejectQualification(req, res, next) {
  try {
    const { verificationId, qualificationId } = req.params;
    const reason = req.body.reason || req.body.notes;
    if (!reason || !reason.trim()) {
      return next(new ApiError(400, 'Rejection reason is required.'));
    }
    const adminUser = req.user;
    const now = new Date();

    const request = await findVerificationFlexible(verificationId);
    if (!request) return next(new ApiError(404, 'Verification request not found'));

    // Check request.qualifications or profile.qualifications
    let qual = findQual(request.qualifications, qualificationId);
    const profile = await findProfileForVerification(request);

    if (profile && Array.isArray(profile.qualifications)) {
      let pQual = findQual(profile.qualifications, qualificationId);
      if (pQual) {
        if (typeof pQual === 'string') {
          pQual = { title: pQual, status: 'rejected', reviewNotes: reason.trim(), reviewedAt: now };
          profile.qualifications = profile.qualifications.map((q) => (q === qualificationId ? pQual : q));
        } else {
          pQual.status = 'rejected';
          pQual.reviewNotes = reason.trim();
          pQual.reviewedAt = now;
          pQual.reviewedBy = adminUser?._id && mongoose.Types.ObjectId.isValid(adminUser._id) ? adminUser._id : null;
        }
        await profile.save();
      }
      qual = qual || pQual;
    }

    if (!qual) {
      qual = { id: qualificationId, title: qualificationId, status: 'rejected', reviewNotes: reason.trim(), reviewedAt: now };
    } else if (typeof qual === 'object') {
      qual.status = 'rejected';
      qual.reviewNotes = reason.trim();
      qual.reviewedAt = now;
    }

    if (request.save) {
      await request.save();
      try {
        await Notification.create({
          user: request.babysitter,
          title: 'Qualification Rejected',
          message: `Your qualification "${qual.title || qualificationId}" was rejected. Reason: ${reason.trim()}`,
          type: 'qualification_rejected',
        });
      } catch (_) {}
      return ApiResponse.success(res, { verification: request, qualification: qual }, 'Qualification rejected successfully');
    }

    // In-memory fallback
    if (Array.isArray(request.qualifications)) {
      const qIndex = request.qualifications.findIndex((q) => {
        if (typeof q === 'string') return q === qualificationId;
        return q._id?.toString() === qualificationId || q.id?.toString() === qualificationId || q.title === qualificationId;
      });
      if (qIndex !== -1) {
        request.qualifications[qIndex] = qual;
      } else {
        request.qualifications.push(qual);
      }
    } else {
      request.qualifications = [qual];
    }

    memoryVerifications.set(request.id || request._id || verificationId, request);
    const sitterId = request.babysitter?._id || request.babysitter?.id || request.babysitter;
    if (sitterId) {
      try {
        await babysitterService.updateProfileByUserId(sitterId, { qualifications: request.qualifications }, true);
      } catch (_) {}
    }

    return ApiResponse.success(res, { verification: request, qualification: qual }, 'Qualification rejected successfully');
  } catch (err) {
    next(err);
  }
}

/**
 * PATCH /api/v1/agency/verifications/:verificationId/qualifications/:qualificationId/request-changes
 */
async function requestChangesQualification(req, res, next) {
  try {
    const { verificationId, qualificationId } = req.params;
    const notes = req.body.notes || req.body.reason;
    if (!notes || !notes.trim()) {
      return next(new ApiError(400, 'Instructions / notes are required when requesting changes.'));
    }
    const adminUser = req.user;
    const now = new Date();

    const request = await findVerificationFlexible(verificationId);
    if (!request) return next(new ApiError(404, 'Verification request not found'));

    // Check request.qualifications or profile.qualifications
    let qual = findQual(request.qualifications, qualificationId);
    const profile = await findProfileForVerification(request);

    if (profile && Array.isArray(profile.qualifications)) {
      let pQual = findQual(profile.qualifications, qualificationId);
      if (pQual) {
        if (typeof pQual === 'string') {
          pQual = { title: pQual, status: 'changes_requested', reviewNotes: notes.trim(), reviewedAt: now };
          profile.qualifications = profile.qualifications.map((q) => (q === qualificationId ? pQual : q));
        } else {
          pQual.status = 'changes_requested';
          pQual.reviewNotes = notes.trim();
          pQual.reviewedAt = now;
          pQual.reviewedBy = adminUser?._id && mongoose.Types.ObjectId.isValid(adminUser._id) ? adminUser._id : null;
        }
        await profile.save();
      }
      qual = qual || pQual;
    }

    if (!qual) {
      qual = { id: qualificationId, title: qualificationId, status: 'changes_requested', reviewNotes: notes.trim(), reviewedAt: now };
    } else if (typeof qual === 'object') {
      qual.status = 'changes_requested';
      qual.reviewNotes = notes.trim();
      qual.reviewedAt = now;
    }

    if (request.save) {
      await request.save();
      try {
        await Notification.create({
          user: request.babysitter,
          title: 'Changes Required for Qualification',
          message: `Changes requested for qualification "${qual.title || qualificationId}": ${notes.trim()}`,
          type: 'qualification_changes_requested',
        });
      } catch (_) {}
      return ApiResponse.success(res, { verification: request, qualification: qual }, 'Changes requested for qualification successfully');
    }

    // In-memory fallback
    if (Array.isArray(request.qualifications)) {
      const qIndex = request.qualifications.findIndex((q) => {
        if (typeof q === 'string') return q === qualificationId;
        return q._id?.toString() === qualificationId || q.id?.toString() === qualificationId || q.title === qualificationId;
      });
      if (qIndex !== -1) {
        request.qualifications[qIndex] = qual;
      } else {
        request.qualifications.push(qual);
      }
    } else {
      request.qualifications = [qual];
    }

    memoryVerifications.set(request.id || request._id || verificationId, request);
    const sitterId = request.babysitter?._id || request.babysitter?.id || request.babysitter;
    if (sitterId) {
      try {
        await babysitterService.updateProfileByUserId(sitterId, { qualifications: request.qualifications }, true);
      } catch (_) {}
    }

    return ApiResponse.success(res, { verification: request, qualification: qual }, 'Changes requested for qualification successfully');
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

    const validDocs = documents.every((d) => d && (d.url || d.fileUrl) && (d.name || d.label));
    if (!validDocs) {
      return next(new ApiError(400, 'Each document must have a valid name and URL'));
    }

    if (isDbConnected()) {
      const docItems = documents.map((d) => ({
        _id: d._id || d.id || new mongoose.Types.ObjectId(),
        type: d.type || 'certificate',
        name: d.name || d.label,
        label: d.label || d.name,
        documentNumber: d.documentNumber || '',
        url: d.url || d.fileUrl,
        fileUrl: d.fileUrl || d.url,
        status: 'pending',
        reviewNotes: null,
        reviewedBy: null,
        reviewedAt: null,
        uploadedAt: new Date(),
      }));

      const qualItems = Array.isArray(req.body.qualifications)
        ? req.body.qualifications.map((q) => {
            if (typeof q === 'string') {
              return {
                _id: new mongoose.Types.ObjectId(),
                title: q,
                status: 'pending',
              };
            }
            return {
              _id: q._id || q.id || new mongoose.Types.ObjectId(),
              title: q.title || q.name,
              institution: q.institution || '',
              certificateUrl: q.certificateUrl || q.url || null,
              status: 'pending',
              reviewNotes: null,
              reviewedBy: null,
              reviewedAt: null,
            };
          })
        : [];

      let request = await VerificationRequest.findOne({ babysitter: userId });
      if (request) {
        request.documents = docItems;
        if (qualItems.length > 0) request.qualifications = qualItems;
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
          qualifications: qualItems,
          submittedAt: new Date(),
        });
      }

      await BabysitterProfile.findOneAndUpdate(
        { user: userId },
        {
          verificationStatus: 'pending',
          verificationNotes: '',
          documents: docItems,
          ...(qualItems.length > 0 ? { qualifications: qualItems } : {}),
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
      _id: d._id || d.id || `doc-${Date.now()}-${Math.random().toString(36).substr(2, 4)}`,
      id: d.id || d._id,
      type: d.type || 'certificate',
      name: d.name || d.label,
      label: d.label || d.name,
      documentNumber: d.documentNumber || '',
      url: d.url || d.fileUrl,
      fileUrl: d.fileUrl || d.url,
      status: 'pending',
      reviewNotes: null,
      reviewedBy: null,
      reviewedAt: null,
      uploadedAt: new Date(),
    }));

    const qualItems = Array.isArray(req.body.qualifications)
      ? req.body.qualifications.map((q) => {
          if (typeof q === 'string') {
            return {
              _id: `qual-${Date.now()}-${Math.random().toString(36).substr(2, 4)}`,
              title: q,
              status: 'pending',
            };
          }
          return {
            _id: q._id || q.id || `qual-${Date.now()}-${Math.random().toString(36).substr(2, 4)}`,
            id: q.id || q._id,
            title: q.title || q.name,
            institution: q.institution || '',
            certificateUrl: q.certificateUrl || q.url || null,
            status: 'pending',
            reviewNotes: null,
            reviewedBy: null,
            reviewedAt: null,
          };
        })
      : [];

    if (existing) {
      existing.documents = docItems;
      if (qualItems.length > 0) existing.qualifications = qualItems;
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
          documents: docItems,
          qualifications: qualItems,
        },
        status: 'pending',
        documents: docItems,
        qualifications: qualItems,
        submittedAt: new Date(),
        createdAt: new Date(),
      };
      memoryVerifications.set(newId, existing);
    }

    try {
      await babysitterService.updateProfileByUserId(
        userId,
        {
          documents: docItems,
          ...(qualItems.length > 0 ? { qualifications: qualItems } : {}),
          verificationStatus: 'pending',
        },
        true
      );
    } catch (_) {}

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
              qualifications: profile.qualifications || [],
              reviewNotes: profile.verificationNotes || '',
              reviewedAt: profile.verificationReviewedAt,
            },
            'Verification status retrieved'
          );
        }
        return ApiResponse.success(
          res,
          { status: 'unverified', documents: [], qualifications: [], reviewNotes: '' },
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
        { status: 'unverified', documents: [], qualifications: [], reviewNotes: '' },
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
  approveDocument,
  rejectDocument,
  requestChangesDocument,
  approveQualification,
  rejectQualification,
  requestChangesQualification,
  submitVerification,
  getMyVerificationStatus,
  memoryVerifications,
};
