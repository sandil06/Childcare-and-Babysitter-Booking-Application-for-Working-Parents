const mongoose = require('mongoose');
const Booking = require('../models/Booking');
const Notification = require('../models/Notification');
const BabysitterProfile = require('../models/BabysitterProfile');
const VerificationRequest = require('../models/VerificationRequest');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');
const generateToken = require('../utils/generateToken');
const babysitterService = require('../services/babysitterService');
const ROLES = require('../constants/roles');
const { memoryVerifications } = require('./verificationController');

function isDbConnected() {
  return mongoose.connection.readyState === 1;
}

function getUserId(req) {
  return req.user?.id || req.user?._id || req.user?.sub;
}

async function register(req, res, next) {
  try {
    const { user, profile } = await babysitterService.registerBabysitter(req.body);
    const token = generateToken({ sub: user._id || user.id, role: ROLES.BABYSITTER });
    return ApiResponse.success(
      res,
      { profile, user, token },
      'Babysitter registration submitted successfully',
      201
    );
  } catch (err) {
    next(err);
  }
}

async function getMe(req, res, next) {
  try {
    const userId = getUserId(req);
    const profile = await babysitterService.getProfileByUserId(userId);
    return ApiResponse.success(res, profile, 'Profile retrieved');
  } catch (err) {
    next(err);
  }
}

async function syncVerificationForSitter(userId, profile) {
  if (!userId || !profile) return;
  const docs = Array.isArray(profile.documents) ? profile.documents : [];
  const quals = Array.isArray(profile.qualifications) ? profile.qualifications : [];

  const hasPending =
    docs.some((d) => (d.status || '').toLowerCase() === 'pending') ||
    quals.some((q) => typeof q === 'object' && (q.status || '').toLowerCase() === 'pending');

  const hasUnderReview =
    docs.some((d) => (d.status || '').toLowerCase() === 'under_review') ||
    quals.some((q) => typeof q === 'object' && (q.status || '').toLowerCase() === 'under_review');

  const overallStatus = hasPending
    ? 'pending'
    : (hasUnderReview ? 'under_review' : (profile.verificationStatus || 'pending'));

  const preparedDocs = docs.map((d) => ({
    ...d,
    _id: d._id || new mongoose.Types.ObjectId(),
    type: d.type || 'other',
    name: d.name || d.label || 'Document',
    label: d.label || d.name || 'Document',
    documentNumber: d.documentNumber || '',
    url: d.url || d.fileUrl || 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=800',
    fileUrl: d.fileUrl || d.url || 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=800',
    status: d.status || 'pending',
    uploadedAt: d.uploadedAt || new Date(),
  }));

  if (isDbConnected() && mongoose.Types.ObjectId.isValid(userId)) {
    try {
      try {
        await User.findByIdAndUpdate(userId, { role: ROLES.BABYSITTER });
      } catch (_) {}

      let vReq = await VerificationRequest.findOne({
        $or: [{ babysitter: userId }, { babysitterProfile: profile._id || profile.id }],
      });
      if (vReq) {
        vReq.documents = preparedDocs;
        vReq.qualifications = quals;
        vReq.status = overallStatus;
        if (!vReq.babysitterProfile) vReq.babysitterProfile = profile._id || profile.id;
        if (!vReq.babysitter) vReq.babysitter = userId;
        if (overallStatus === 'pending') vReq.submittedAt = new Date();
        await vReq.save();
      } else {
        await VerificationRequest.create({
          babysitter: userId,
          babysitterProfile: profile._id || profile.id,
          status: overallStatus,
          documents: preparedDocs,
          qualifications: quals,
          submittedAt: new Date(),
        });
      }
    } catch (err) {
      console.error('[BabysitterController] syncVerificationForSitter error:', err.message);
    }
  }

  // Memory fallback
  const memKey = userId.toString();
  let memReq = Array.from(memoryVerifications.values()).find(
    (v) => (v.babysitter?._id || v.babysitter?.id || v.babysitter) === memKey
  );
  if (memReq) {
    memReq.documents = preparedDocs;
    memReq.qualifications = quals;
    memReq.status = overallStatus;
    if (memReq.babysitterProfile) {
      memReq.babysitterProfile.documents = preparedDocs;
      memReq.babysitterProfile.qualifications = quals;
      memReq.babysitterProfile.verificationStatus = overallStatus;
    }
    memoryVerifications.set(memReq.id || memReq._id, memReq);
  } else {
    const newMemReq = {
      _id: `ver-${Date.now()}`,
      id: `ver-${Date.now()}`,
      babysitter: profile.user || {
        _id: memKey,
        id: memKey,
        name: profile.name || 'Caregiver',
        email: profile.email || '',
        phone: profile.phone || '',
        avatar: profile.avatar || profile.profileImage || '',
      },
      babysitterProfile: profile,
      status: overallStatus,
      documents: preparedDocs,
      qualifications: quals,
      reviewNotes: '',
      submittedAt: new Date(),
      createdAt: new Date(),
    };
    memoryVerifications.set(newMemReq._id, newMemReq);
  }
}

async function updateMe(req, res, next) {
  try {
    const userId = getUserId(req);

    // Rule 3: Babysitters cannot directly manipulate verification state
    if (req.body.verificationStatus !== undefined) {
      return next(new ApiError(403, 'Babysitters are not authorized to modify verificationStatus directly.'));
    }
    if (req.body.status !== undefined && typeof req.body.status === 'string') {
      return next(new ApiError(403, 'Babysitters are not authorized to modify status directly.'));
    }
    if (req.body.reviewedBy !== undefined || req.body.reviewedAt !== undefined || req.body.reviewNotes !== undefined) {
      return next(new ApiError(403, 'Babysitters are not authorized to modify administrative review fields.'));
    }

    const existingProfile = await babysitterService.getProfileByUserId(userId);
    const existingDocs = Array.isArray(existingProfile?.documents) ? existingProfile.documents : [];
    const existingQuals = Array.isArray(existingProfile?.qualifications) ? existingProfile.qualifications : [];

    if (Array.isArray(req.body.documents)) {
      for (const d of req.body.documents) {
        if (d && (d.status === 'verified' || d.verificationStatus === 'verified')) {
          const wasAlreadyVerified = existingDocs.some(
            (ed) =>
              (ed._id?.toString() === d._id?.toString() || ed.name === d.name) &&
              ed.status === 'verified' &&
              (ed.url === d.url || ed.fileUrl === d.fileUrl || (!d.url && !d.fileUrl))
          );
          if (!wasAlreadyVerified) {
            return next(new ApiError(403, 'Babysitters cannot mark documents as verified.'));
          }
        } else if (d && typeof d === 'object') {
          d.status = 'pending';
          d.reviewNotes = null;
          d.reviewedBy = null;
          d.reviewedAt = null;
        }
      }
    }
    if (Array.isArray(req.body.qualifications)) {
      for (const q of req.body.qualifications) {
        if (q && typeof q === 'object' && (q.status === 'verified' || q.verificationStatus === 'verified')) {
          const wasAlreadyVerified = existingQuals.some(
            (eq) =>
              typeof eq === 'object' &&
              (eq._id?.toString() === q._id?.toString() || eq.title === q.title) &&
              eq.status === 'verified'
          );
          if (!wasAlreadyVerified) {
            return next(new ApiError(403, 'Babysitters cannot mark qualifications as verified.'));
          }
        } else if (q && typeof q === 'object') {
          q.status = 'pending';
          q.reviewNotes = null;
          q.reviewedBy = null;
          q.reviewedAt = null;
        }
      }
    }

    const updated = await babysitterService.updateProfileByUserId(userId, req.body);
    if (Array.isArray(req.body.documents) || Array.isArray(req.body.qualifications)) {
      await syncVerificationForSitter(userId, updated);
    }
    return ApiResponse.success(res, updated, 'Profile updated successfully');
  } catch (err) {
    next(err);
  }
}

async function getDashboard(req, res, next) {
  try {
    const userId = getUserId(req);
    const profile = await babysitterService.getProfileByUserId(userId);

    let totalEarnings = 0;
    let completedBookingsCount = 0;
    let upcomingBooking = null;
    let newRequests = [];
    let unreadCount = 0;

    if (isDbConnected()) {
      const sitterIds = [userId];
      if (profile?._id) sitterIds.push(profile._id);

      const completed = await Booking.find({ babysitter: { $in: sitterIds }, status: 'completed' });
      totalEarnings = completed.reduce(
        (sum, b) => sum + (b.total || (b.hourlyRate * b.durationHours)),
        0
      );
      completedBookingsCount = completed.length;

      upcomingBooking = await Booking.findOne({
        babysitter: { $in: sitterIds },
        status: { $in: ['accepted', 'confirmed', 'travelling', 'arrived', 'in_progress'] },
      })
        .populate('parent', 'name email phone avatar')
        .sort({ date: 1, startTime: 1 });

      newRequests = await Booking.find({
        babysitter: { $in: sitterIds },
        status: 'pending',
      })
        .populate('parent', 'name email phone avatar')
        .sort({ date: 1, startTime: 1 });

      unreadCount = await Notification.countDocuments({ user: userId, isRead: false });
    }

    const stats = {
      totalEarnings: Number(totalEarnings.toFixed(2)),
      rating: profile?.averageRating != null ? profile.averageRating : 0.0,
      completedBookings: completedBookingsCount || (profile?.totalCompletedBookings ?? 0),
    };

    return ApiResponse.success(
      res,
      {
        profile,
        stats,
        isAvailable: profile?.isAvailable ?? true,
        upcomingBooking,
        newRequests,
        unreadNotificationsCount: unreadCount,
      },
      'Dashboard data retrieved'
    );
  } catch (err) {
    next(err);
  }
}

async function list(req, res, next) {
  try {
    const sitters = await babysitterService.listBabysitters(req.query);
    return ApiResponse.success(res, sitters, 'Babysitters retrieved');
  } catch (err) {
    next(err);
  }
}

async function getById(req, res, next) {
  try {
    const profile = await babysitterService.getProfileById(req.params.id);
    return ApiResponse.success(res, profile, 'Profile retrieved');
  } catch (err) {
    next(err);
  }
}

/**
 * POST /api/v1/babysitters/me/verification-documents
 * Babysitter uploads a verification document
 */
async function addDocument(req, res, next) {
  try {
    const userId = getUserId(req);

    // Security: Babysitter cannot set status or review fields
    if (req.body.status !== undefined || req.body.verificationStatus !== undefined) {
      return next(new ApiError(403, 'Babysitters cannot specify document verification status.'));
    }
    if (req.body.reviewedBy !== undefined || req.body.reviewedAt !== undefined || req.body.reviewNotes !== undefined) {
      return next(new ApiError(403, 'Babysitters cannot specify administrative review fields.'));
    }

    const { type, name, label, documentNumber, url, fileUrl } = req.body;
    if (!name || (!url && !fileUrl)) {
      return next(new ApiError(400, 'Document name and file URL are required.'));
    }

    const newDoc = {
      _id: new mongoose.Types.ObjectId(),
      type: type || 'id',
      name: name.trim(),
      label: label ? label.trim() : name.trim(),
      documentNumber: documentNumber ? documentNumber.trim() : '',
      url: url || fileUrl,
      fileUrl: fileUrl || url,
      status: 'pending',
      reviewNotes: null,
      reviewedBy: null,
      reviewedAt: null,
      uploadedAt: new Date(),
    };

    let profile = await babysitterService.getProfileByUserId(userId);
    const docs = Array.isArray(profile.documents) ? [...profile.documents, newDoc] : [newDoc];

    const updated = await babysitterService.updateProfileByUserId(userId, { documents: docs });
    await syncVerificationForSitter(userId, updated);

    return ApiResponse.success(res, { profile: updated, document: newDoc }, 'Document uploaded successfully', 201);
  } catch (err) {
    next(err);
  }
}

/**
 * PATCH /api/v1/babysitters/me/verification-documents/:id
 * Babysitter edits/replaces a document
 */
async function updateDocument(req, res, next) {
  try {
    const userId = getUserId(req);
    const { id } = req.params;

    // Security: Babysitter cannot set status or review fields
    if (req.body.status !== undefined || req.body.verificationStatus !== undefined) {
      return next(new ApiError(403, 'Babysitters cannot modify document status directly.'));
    }
    if (req.body.reviewedBy !== undefined || req.body.reviewedAt !== undefined || req.body.reviewNotes !== undefined) {
      return next(new ApiError(403, 'Babysitters cannot modify administrative review fields.'));
    }

    const profile = await babysitterService.getProfileByUserId(userId);
    let docs = Array.isArray(profile.documents) ? [...profile.documents] : [];

    let docIndex = docs.findIndex(
      (d) => d._id?.toString() === id || d.id?.toString() === id || d.name === id
    );

    // If not found in profile.documents, check active VerificationRequest or memory store
    let activeVReq = null;
    if (isDbConnected()) {
      try {
        activeVReq = await VerificationRequest.findOne({ babysitter: userId });
      } catch (_) {}
    } else {
      activeVReq = Array.from(memoryVerifications.values()).find(
        (v) => (v.babysitter?._id || v.babysitter?.id) === userId
      );
    }

    if (docIndex === -1 && activeVReq && Array.isArray(activeVReq.documents)) {
      const vDocIndex = activeVReq.documents.findIndex(
        (d) => d._id?.toString() === id || d.id?.toString() === id || d.name === id
      );
      if (vDocIndex !== -1) {
        docs.push(activeVReq.documents[vDocIndex]);
        docIndex = docs.length - 1;
      }
    }

    if (docIndex === -1) {
      return next(new ApiError(404, 'Document not found.'));
    }

    const existingDoc = docs[docIndex];
    const wasVerified = existingDoc.status === 'verified';
    const wasRequired = ['id', 'national_id', 'police_check'].includes(existingDoc.type);

    const updatedDoc = {
      ...existingDoc,
      _id: existingDoc._id || id,
      id: existingDoc.id || id,
      name: req.body.name !== undefined ? req.body.name.trim() : existingDoc.name,
      label: req.body.label !== undefined ? req.body.label.trim() : (existingDoc.label || existingDoc.name),
      documentNumber: req.body.documentNumber !== undefined ? req.body.documentNumber.trim() : (existingDoc.documentNumber || ''),
      url: req.body.url || req.body.fileUrl || existingDoc.url,
      fileUrl: req.body.fileUrl || req.body.url || existingDoc.fileUrl,
      // Resubmission always resets to pending
      status: 'pending',
      reviewNotes: null,
      reviewedBy: null,
      reviewedAt: null,
      updatedAt: new Date(),
    };

    docs[docIndex] = updatedDoc;

    const payload = { documents: docs };
    if (wasVerified && wasRequired) {
      payload.verificationStatus = 'under_review';
    }

    const updated = await babysitterService.updateProfileByUserId(userId, payload);

    // Sync with active VerificationRequest
    if (activeVReq) {
      if (activeVReq.save) {
        const vIndex = activeVReq.documents.findIndex(
          (d) => d._id?.toString() === id || d.id?.toString() === id || d.name === existingDoc.name
        );
        if (vIndex !== -1) {
          activeVReq.documents[vIndex] = updatedDoc;
          activeVReq.status = 'pending';
          await activeVReq.save();
        }
      } else {
        // In-memory fallback
        if (Array.isArray(activeVReq.documents)) {
          const vIndex = activeVReq.documents.findIndex(
            (d) => d._id?.toString() === id || d.id?.toString() === id || d.name === existingDoc.name
          );
          if (vIndex !== -1) {
            activeVReq.documents[vIndex] = updatedDoc;
            activeVReq.status = 'pending';
            memoryVerifications.set(activeVReq.id || activeVReq._id, activeVReq);
          }
        }
      }
    }
    await syncVerificationForSitter(userId, updated);

    return ApiResponse.success(
      res,
      { ...updatedDoc, profile: updated, document: updatedDoc },
      'Document updated and queued for review'
    );
  } catch (err) {
    next(err);
  }
}

/**
 * DELETE /api/v1/babysitters/me/verification-documents/:id
 * Babysitter removes a document
 */
async function deleteDocument(req, res, next) {
  try {
    const userId = getUserId(req);
    const { id } = req.params;

    const profile = await babysitterService.getProfileByUserId(userId);
    const docs = Array.isArray(profile.documents) ? [...profile.documents] : [];

    const doc = docs.find((d) => d._id?.toString() === id || d.id?.toString() === id || d.name === id);
    if (!doc) {
      return next(new ApiError(404, 'Document not found.'));
    }

    const filtered = docs.filter((d) => d._id?.toString() !== id && d.id?.toString() !== id && d.name !== id);
    const payload = { documents: filtered };
    if (doc.status === 'verified' && ['id', 'national_id', 'police_check'].includes(doc.type)) {
      payload.verificationStatus = 'under_review';
    }

    const updated = await babysitterService.updateProfileByUserId(userId, payload);
    await syncVerificationForSitter(userId, updated);
    return ApiResponse.success(res, updated, 'Document removed successfully');
  } catch (err) {
    next(err);
  }
}

/**
 * POST /api/v1/babysitters/me/qualifications
 * Babysitter adds a qualification
 */
async function addQualification(req, res, next) {
  try {
    const userId = getUserId(req);

    if (req.body.status !== undefined || req.body.verificationStatus !== undefined) {
      return next(new ApiError(403, 'Babysitters cannot specify qualification verification status.'));
    }

    const { title, institution, certificateUrl } = req.body;
    if (!title || !title.trim()) {
      return next(new ApiError(400, 'Qualification title is required.'));
    }

    const newQual = {
      _id: new mongoose.Types.ObjectId(),
      title: title.trim(),
      institution: institution ? institution.trim() : '',
      certificateUrl: certificateUrl || null,
      status: 'pending',
      reviewNotes: null,
      reviewedBy: null,
      reviewedAt: null,
    };

    const profile = await babysitterService.getProfileByUserId(userId);
    const quals = Array.isArray(profile.qualifications) ? [...profile.qualifications, newQual] : [newQual];

    const updated = await babysitterService.updateProfileByUserId(userId, { qualifications: quals });
    await syncVerificationForSitter(userId, updated);
    return ApiResponse.success(res, { profile: updated, qualification: newQual }, 'Qualification added successfully', 201);
  } catch (err) {
    next(err);
  }
}

/**
 * PATCH /api/v1/babysitters/me/qualifications/:id
 * Babysitter updates a qualification
 */
async function updateQualification(req, res, next) {
  try {
    const userId = getUserId(req);
    const { id } = req.params;

    if (req.body.status !== undefined || req.body.verificationStatus !== undefined) {
      return next(new ApiError(403, 'Babysitters cannot modify qualification status directly.'));
    }

    const profile = await babysitterService.getProfileByUserId(userId);
    const quals = Array.isArray(profile.qualifications) ? [...profile.qualifications] : [];

    let qualIndex = quals.findIndex((q) => {
      if (typeof q === 'string') return q === id;
      return q._id?.toString() === id || q.id?.toString() === id || q.title === id;
    });

    let activeVReq = null;
    if (isDbConnected()) {
      try {
        activeVReq = await VerificationRequest.findOne({ babysitter: userId });
      } catch (_) {}
    } else {
      activeVReq = Array.from(memoryVerifications.values()).find(
        (v) => (v.babysitter?._id || v.babysitter?.id) === userId
      );
    }

    if (qualIndex === -1 && activeVReq && Array.isArray(activeVReq.qualifications)) {
      const vQualIndex = activeVReq.qualifications.findIndex((q) => {
        if (typeof q === 'string') return q === id;
        return q._id?.toString() === id || q.id?.toString() === id || q.title === id;
      });
      if (vQualIndex !== -1) {
        quals.push(activeVReq.qualifications[vQualIndex]);
        qualIndex = quals.length - 1;
      }
    }

    if (qualIndex === -1) {
      return next(new ApiError(404, 'Qualification not found.'));
    }

    const existing = quals[qualIndex];
    const updatedQual = {
      _id: typeof existing === 'object' && existing._id ? existing._id : id,
      id: typeof existing === 'object' && (existing.id || existing._id) ? (existing.id || existing._id) : id,
      title: req.body.title !== undefined ? req.body.title.trim() : (typeof existing === 'string' ? existing : existing.title),
      institution: req.body.institution !== undefined ? req.body.institution.trim() : (typeof existing === 'object' ? (existing.institution || '') : ''),
      certificateUrl: req.body.certificateUrl !== undefined ? req.body.certificateUrl : (typeof existing === 'object' ? existing.certificateUrl : null),
      status: 'pending',
      reviewNotes: null,
      reviewedBy: null,
      reviewedAt: null,
    };

    quals[qualIndex] = updatedQual;
    const updated = await babysitterService.updateProfileByUserId(userId, { qualifications: quals });

    if (activeVReq) {
      if (activeVReq.save) {
        const vIndex = activeVReq.qualifications.findIndex((q) => {
          if (typeof q === 'string') return q === id;
          return q._id?.toString() === id || q.id?.toString() === id || q.title === updatedQual.title;
        });
        if (vIndex !== -1) {
          activeVReq.qualifications[vIndex] = updatedQual;
          await activeVReq.save();
        }
      } else if (Array.isArray(activeVReq.qualifications)) {
        const vIndex = activeVReq.qualifications.findIndex((q) => {
          if (typeof q === 'string') return q === id;
          return q._id?.toString() === id || q.id?.toString() === id || q.title === updatedQual.title;
        });
        if (vIndex !== -1) {
          activeVReq.qualifications[vIndex] = updatedQual;
          memoryVerifications.set(activeVReq.id || activeVReq._id, activeVReq);
        }
      }
    }

    await syncVerificationForSitter(userId, updated);

    return ApiResponse.success(
      res,
      { ...updatedQual, profile: updated, qualification: updatedQual },
      'Qualification updated and queued for review'
    );
  } catch (err) {
    next(err);
  }
}

/**
 * DELETE /api/v1/babysitters/me/qualifications/:id
 * Babysitter removes a qualification
 */
async function deleteQualification(req, res, next) {
  try {
    const userId = getUserId(req);
    const { id } = req.params;

    const profile = await babysitterService.getProfileByUserId(userId);
    const quals = Array.isArray(profile.qualifications) ? [...profile.qualifications] : [];

    const filtered = quals.filter((q) => {
      if (typeof q === 'string') return q !== id;
      return q._id?.toString() !== id && q.id?.toString() !== id && q.title !== id;
    });

    const updated = await babysitterService.updateProfileByUserId(userId, { qualifications: filtered });
    await syncVerificationForSitter(userId, updated);
    return ApiResponse.success(res, updated, 'Qualification removed successfully');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  register,
  getMe,
  updateMe,
  getDashboard,
  list,
  getById,
  addDocument,
  updateDocument,
  deleteDocument,
  addQualification,
  updateQualification,
  deleteQualification,
};
