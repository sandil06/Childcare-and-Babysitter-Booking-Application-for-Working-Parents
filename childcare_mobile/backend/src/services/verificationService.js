const mongoose = require('mongoose');
const User = require('../models/User');
const BabysitterProfile = require('../models/BabysitterProfile');
const VerificationRequest = require('../models/VerificationRequest');
const AuditLog = require('../models/AuditLog');
const Notification = require('../models/Notification');
const ApiError = require('../utils/ApiError');
const ROLES = require('../constants/roles');

function isDbConnected() {
  return mongoose.connection.readyState === 1;
}

const DEFAULT_DOCUMENTS = [
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

/**
 * Synchronize any babysitters in MongoDB whose BabysitterProfile exists
 * but lacks a VerificationRequest record.
 */
async function syncVerificationRequests() {
  if (!isDbConnected()) return;

  try {
    const sitters = await User.find({ role: ROLES.BABYSITTER }).select('_id name email phone').lean();
    if (!sitters || sitters.length === 0) return;

    for (const sitter of sitters) {
      const profile = await BabysitterProfile.findOne({ user: sitter._id });
      if (!profile) continue;

      let existingReq = await VerificationRequest.findOne({ babysitter: sitter._id });
      const profileDocs = Array.isArray(profile.documents) ? profile.documents : [];
      const profileQuals = Array.isArray(profile.qualifications) ? profile.qualifications : [];

      if (!existingReq) {
        const docs = profileDocs.length > 0
          ? profileDocs.map((d) => ({
              type: d.type || 'id',
              name: d.name || 'Identity Document',
              label: d.label || d.name,
              documentNumber: d.documentNumber || '',
              url: d.url || d.fileUrl || DEFAULT_DOCUMENTS[0].url,
              fileUrl: d.fileUrl || d.url || DEFAULT_DOCUMENTS[0].url,
              status: d.status || 'pending',
              reviewNotes: d.reviewNotes || null,
              reviewedAt: d.reviewedAt || null,
              reviewedBy: d.reviewedBy || null,
              uploadedAt: d.uploadedAt || profile.createdAt || new Date(),
            }))
          : DEFAULT_DOCUMENTS.map((d) => ({
              ...d,
              status: profile.verificationStatus === 'verified' ? 'verified' : 'pending',
              uploadedAt: profile.createdAt || new Date(),
            }));

        const hasPending =
          docs.some((d) => ['pending', 'under_review'].includes(d.status)) ||
          profileQuals.some((q) => typeof q === 'object' && ['pending', 'under_review'].includes(q.status));

        let initialStatus = profile.verificationStatus || 'pending';
        if (hasPending) {
          initialStatus = 'pending';
        }

        existingReq = await VerificationRequest.create({
          babysitter: sitter._id,
          babysitterProfile: profile._id,
          status: initialStatus,
          documents: docs,
          qualifications: profileQuals,
          reviewNotes: profile.verificationNotes || '',
          reviewedAt: profile.verificationReviewedAt || null,
          reviewedBy: profile.verificationReviewedBy || null,
          submittedAt: profile.createdAt || new Date(),
        });
      } else {
        // Bi-directional document and qualification synchronization
        let reqModified = false;
        let profileModified = false;

        if (!existingReq.babysitterProfile) {
          existingReq.babysitterProfile = profile._id;
          reqModified = true;
        }

        // 1. Sync documents from profile to request
        const reqDocs = Array.isArray(existingReq.documents) ? existingReq.documents : [];
        for (const pDoc of profileDocs) {
          const matchIndex = reqDocs.findIndex(
            (d) =>
              (d._id && pDoc._id && d._id.toString() === pDoc._id.toString()) ||
              d.name === pDoc.name ||
              (pDoc.documentNumber && d.documentNumber && d.documentNumber === pDoc.documentNumber)
          );
          if (matchIndex === -1) {
            reqDocs.push({
              _id: pDoc._id || new mongoose.Types.ObjectId(),
              type: pDoc.type || 'other',
              name: pDoc.name || 'Document',
              label: pDoc.label || pDoc.name,
              documentNumber: pDoc.documentNumber || '',
              url: pDoc.url || pDoc.fileUrl || DEFAULT_DOCUMENTS[0].url,
              fileUrl: pDoc.fileUrl || pDoc.url || DEFAULT_DOCUMENTS[0].url,
              status: pDoc.status || 'pending',
              reviewNotes: pDoc.reviewNotes || null,
              reviewedBy: pDoc.reviewedBy || null,
              reviewedAt: pDoc.reviewedAt || null,
              uploadedAt: pDoc.uploadedAt || new Date(),
            });
            reqModified = true;
          } else {
            const rDoc = reqDocs[matchIndex];
            // If admin reviewed in VerificationRequest, sync down to profile
            if (['verified', 'rejected', 'changes_requested'].includes(rDoc.status) && pDoc.status !== rDoc.status) {
              pDoc.status = rDoc.status;
              pDoc.reviewNotes = rDoc.reviewNotes;
              pDoc.reviewedBy = rDoc.reviewedBy;
              pDoc.reviewedAt = rDoc.reviewedAt;
              profileModified = true;
            } else if (pDoc.status === 'pending' && rDoc.status !== 'pending') {
              // Sitter re-uploaded / replaced as pending
              rDoc.status = 'pending';
              rDoc.url = pDoc.url || pDoc.fileUrl || rDoc.url || DEFAULT_DOCUMENTS[0].url;
              rDoc.fileUrl = pDoc.fileUrl || pDoc.url || rDoc.fileUrl || DEFAULT_DOCUMENTS[0].url;
              rDoc.reviewNotes = null;
              rDoc.reviewedBy = null;
              rDoc.reviewedAt = null;
              reqModified = true;
            }
          }
        }
        existingReq.documents = reqDocs;

        // 2. Sync qualifications
        if (profileQuals.length > 0) {
          const reqQuals = Array.isArray(existingReq.qualifications) ? existingReq.qualifications : [];
          for (const pQ of profileQuals) {
            const qTitle = typeof pQ === 'string' ? pQ : (pQ.title || pQ.name || '');
            const matchIndex = reqQuals.findIndex((q) => {
              if (typeof q === 'string') return q === qTitle;
              return q.title === qTitle || (pQ._id && q._id && q._id.toString() === pQ._id.toString());
            });
            if (matchIndex === -1) {
              reqQuals.push(typeof pQ === 'string' ? { title: pQ, status: 'pending' } : pQ);
              reqModified = true;
            } else if (typeof pQ === 'object' && reqQuals[matchIndex]) {
              const rQ = reqQuals[matchIndex];
              if (typeof rQ === 'object' && ['verified', 'rejected', 'changes_requested'].includes(rQ.status) && pQ.status !== rQ.status) {
                pQ.status = rQ.status;
                pQ.reviewNotes = rQ.reviewNotes;
                profileModified = true;
              }
            }
          }
          existingReq.qualifications = reqQuals;
        }

        // 3. Compute overall status accurately
        const hasPendingItems =
          existingReq.documents.some((d) => d.status === 'pending') ||
          (Array.isArray(existingReq.qualifications) &&
            existingReq.qualifications.some((q) => typeof q === 'object' && q.status === 'pending'));

        const hasUnderReviewItems =
          existingReq.documents.some((d) => d.status === 'under_review') ||
          (Array.isArray(existingReq.qualifications) &&
            existingReq.qualifications.some((q) => typeof q === 'object' && q.status === 'under_review'));

        const hasChangesRequested =
          existingReq.documents.some((d) => d.status === 'changes_requested') ||
          (Array.isArray(existingReq.qualifications) &&
            existingReq.qualifications.some((q) => typeof q === 'object' && q.status === 'changes_requested'));

        const hasRejected =
          existingReq.documents.some((d) => d.status === 'rejected') ||
          (Array.isArray(existingReq.qualifications) &&
            existingReq.qualifications.some((q) => typeof q === 'object' && q.status === 'rejected'));

        const allDocsVerified =
          existingReq.documents.length > 0 &&
          existingReq.documents.every((d) => d.status === 'verified') &&
          (!Array.isArray(existingReq.qualifications) ||
            existingReq.qualifications.every((q) => typeof q === 'string' || q.status === 'verified'));

        if (hasPendingItems) {
          if (existingReq.status !== 'pending') {
            existingReq.status = 'pending';
            reqModified = true;
          }
          if (profile.verificationStatus !== 'pending') {
            profile.verificationStatus = 'pending';
            profileModified = true;
          }
        } else if (hasUnderReviewItems) {
          if (existingReq.status !== 'under_review') {
            existingReq.status = 'under_review';
            reqModified = true;
          }
          if (profile.verificationStatus !== 'under_review') {
            profile.verificationStatus = 'under_review';
            profileModified = true;
          }
        } else if (hasChangesRequested) {
          if (existingReq.status !== 'changes_requested') {
            existingReq.status = 'changes_requested';
            reqModified = true;
          }
          if (profile.verificationStatus !== 'changes_requested') {
            profile.verificationStatus = 'changes_requested';
            profileModified = true;
          }
        } else if (hasRejected) {
          if (existingReq.status !== 'rejected') {
            existingReq.status = 'rejected';
            reqModified = true;
          }
          if (profile.verificationStatus !== 'rejected') {
            profile.verificationStatus = 'rejected';
            profileModified = true;
          }
        } else if (allDocsVerified) {
          if (existingReq.status !== 'verified') {
            existingReq.status = 'verified';
            reqModified = true;
          }
          if (profile.verificationStatus !== 'verified') {
            profile.verificationStatus = 'verified';
            profileModified = true;
          }
        }

        if (reqModified) await existingReq.save();
        if (profileModified) await profile.save();
      }
    }
  } catch (err) {
    console.error('[VerificationService] syncVerificationRequests error:', err.message);
  }
}

/**
 * Babysitter submits documents for verification
 */
async function submitVerification(userId, documents) {
  if (!Array.isArray(documents) || documents.length === 0) {
    throw new ApiError(400, 'At least one verification document is required');
  }

  const validDocs = documents.every((d) => d && d.url && d.name);
  if (!validDocs) {
    throw new ApiError(400, 'Each document must have a valid name and URL');
  }

  const docItems = documents.map((d) => ({
    type: d.type || 'certificate',
    name: d.name,
    url: d.url,
    status: 'pending',
    uploadedAt: new Date(),
  }));

  if (isDbConnected()) {
    let profile = await BabysitterProfile.findOne({ user: userId });
    if (!profile) {
      profile = await BabysitterProfile.create({
        user: userId,
        verificationStatus: 'pending',
        documents: docItems,
      });
    } else {
      profile.verificationStatus = 'pending';
      profile.verificationNotes = '';
      profile.documents = docItems;
      await profile.save();
    }

    let request = await VerificationRequest.findOne({ babysitter: userId });
    if (request) {
      request.documents = docItems;
      request.status = 'pending';
      request.reviewNotes = '';
      request.submittedAt = new Date();
      request.babysitterProfile = profile._id;
      await request.save();
    } else {
      request = await VerificationRequest.create({
        babysitter: userId,
        babysitterProfile: profile._id,
        status: 'pending',
        documents: docItems,
        submittedAt: new Date(),
      });
    }

    // Notify agency admins
    try {
      const agencyAdmins = await User.find({ role: { $in: [ROLES.AGENCY, ROLES.ADMIN] } }).select('_id');
      for (const admin of agencyAdmins) {
        await Notification.create({
          user: admin._id,
          title: 'New Verification Request',
          message: 'A babysitter has submitted verification credentials for review.',
          type: 'system',
          data: { verificationId: request._id, babysitterId: userId },
        });
      }
    } catch (_) {}

    return request;
  }

  throw new ApiError(500, 'Database not connected');
}

/**
 * Agency / Admin approves a verification request
 */
async function approveVerification(id, adminUser, notes = '') {
  if (!isDbConnected()) {
    throw new ApiError(400, 'Database not connected');
  }

  let request = null;
  const cleanId = id ? id.toString().trim() : '';
  if (mongoose.Types.ObjectId.isValid(cleanId)) {
    request = await VerificationRequest.findById(cleanId);
    if (!request) {
      request = await VerificationRequest.findOne({
        $or: [{ babysitter: cleanId }, { babysitterProfile: cleanId }],
      });
    }
  }

  if (!request) {
    const profile = await BabysitterProfile.findOne({
      $or: [{ _id: cleanId }, { user: cleanId }],
    });
    if (profile) {
      await syncVerificationRequests();
      request = await VerificationRequest.findOne({
        $or: [{ babysitter: profile.user }, { babysitterProfile: profile._id }],
      });
    }
  }

  if (!request) throw new ApiError(404, 'Verification request not found');

  const approvalNote = notes || request.reviewNotes || 'Approved by agency';
  const now = new Date();

  request.status = 'verified';
  request.reviewNotes = approvalNote;
  if (adminUser?._id && mongoose.Types.ObjectId.isValid(adminUser._id)) {
    request.reviewedBy = adminUser._id;
  }
  request.reviewedAt = now;
  if (Array.isArray(request.documents)) {
    request.documents.forEach((d) => {
      d.status = 'verified';
    });
  }
  await request.save();

  // Synchronize BabysitterProfile AND documents
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
      actor: adminUser?._id,
      action: 'approve_verification',
      targetType: 'VerificationRequest',
      targetId: id,
      notes: approvalNote,
      metadata: { babysitterId: request.babysitter },
    });
  } catch (_) {}

  // Notify Babysitter
  try {
    await Notification.create({
      user: request.babysitter,
      title: 'Verification Approved',
      message: 'Your babysitter profile has been verified and is now visible to parents in the search catalog.',
      type: 'verification_approved',
      data: { verificationId: id },
    });
  } catch (_) {}

  return request;
}

/**
 * Agency / Admin rejects a verification request
 */
async function rejectVerification(id, adminUser, reason) {
  if (!reason || !reason.trim()) {
    throw new ApiError(400, 'Rejection reason is required');
  }

  if (!isDbConnected() || !mongoose.Types.ObjectId.isValid(id)) {
    throw new ApiError(400, 'Invalid verification request ID');
  }

  const request = await VerificationRequest.findById(id);
  if (!request) throw new ApiError(404, 'Verification request not found');

  if (request.status === 'rejected') {
    throw new ApiError(400, 'Verification request is already rejected');
  }

  const now = new Date();
  request.status = 'rejected';
  request.reviewNotes = reason.trim();
  request.reviewedBy = adminUser?._id;
  request.reviewedAt = now;
  if (Array.isArray(request.documents)) {
    request.documents.forEach((d) => {
      d.status = 'rejected';
    });
  }
  await request.save();

  // Synchronize BabysitterProfile
  const profile = await BabysitterProfile.findOne({
    $or: [{ _id: request.babysitterProfile }, { user: request.babysitter }],
  });
  if (profile) {
    profile.verificationStatus = 'rejected';
    profile.verificationReviewedAt = now;
    profile.verificationReviewedBy = adminUser?._id;
    profile.verificationNotes = reason.trim();
    if (Array.isArray(profile.documents)) {
      profile.documents.forEach((d) => {
        d.status = 'rejected';
      });
    }
    await profile.save();
  }

  // Create AuditLog
  try {
    await AuditLog.create({
      actor: adminUser?._id,
      action: 'reject_verification',
      targetType: 'VerificationRequest',
      targetId: id,
      notes: reason.trim(),
      metadata: { babysitterId: request.babysitter },
    });
  } catch (_) {}

  // Notify Babysitter
  try {
    await Notification.create({
      user: request.babysitter,
      title: 'Verification Rejected',
      message: `Your verification application was rejected: ${reason.trim()}`,
      type: 'verification_rejected',
      data: { verificationId: id, reason: reason.trim() },
    });
  } catch (_) {}

  return request;
}

/**
 * Agency / Admin requests changes for a verification request
 */
async function requestChanges(id, adminUser, notes) {
  if (!notes || !notes.trim()) {
    throw new ApiError(400, 'Instructions / notes for required changes are required');
  }

  if (!isDbConnected() || !mongoose.Types.ObjectId.isValid(id)) {
    throw new ApiError(400, 'Invalid verification request ID');
  }

  const request = await VerificationRequest.findById(id);
  if (!request) throw new ApiError(404, 'Verification request not found');

  const now = new Date();
  request.status = 'changes_requested';
  request.reviewNotes = notes.trim();
  request.reviewedBy = adminUser?._id;
  request.reviewedAt = now;
  if (Array.isArray(request.documents)) {
    request.documents.forEach((d) => {
      d.status = 'changes_requested';
    });
  }
  await request.save();

  // Synchronize BabysitterProfile
  const profile = await BabysitterProfile.findOne({
    $or: [{ _id: request.babysitterProfile }, { user: request.babysitter }],
  });
  if (profile) {
    profile.verificationStatus = 'changes_requested';
    profile.verificationReviewedAt = now;
    profile.verificationReviewedBy = adminUser?._id;
    profile.verificationNotes = notes.trim();
    if (Array.isArray(profile.documents)) {
      profile.documents.forEach((d) => {
        d.status = 'changes_requested';
      });
    }
    await profile.save();
  }

  // Create AuditLog
  try {
    await AuditLog.create({
      actor: adminUser?._id,
      action: 'request_changes_verification',
      targetType: 'VerificationRequest',
      targetId: id,
      notes: notes.trim(),
      metadata: { babysitterId: request.babysitter },
    });
  } catch (_) {}

  // Notify Babysitter
  try {
    await Notification.create({
      user: request.babysitter,
      title: 'Verification Changes Requested',
      message: `The agency has requested additional details or updated documents: ${notes.trim()}`,
      type: 'verification_changes_requested',
      data: { verificationId: id, notes: notes.trim() },
    });
  } catch (_) {}

  return request;
}

module.exports = {
  syncVerificationRequests,
  submitVerification,
  approveVerification,
  rejectVerification,
  requestChanges,
};
