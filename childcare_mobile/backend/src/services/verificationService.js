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

      const existingReq = await VerificationRequest.findOne({ babysitter: sitter._id });
      if (!existingReq) {
        const docs = profile.documents && profile.documents.length > 0
          ? profile.documents.map((d) => ({
              type: d.type || 'id',
              name: d.name || 'Identity Document',
              url: d.url || DEFAULT_DOCUMENTS[0].url,
              status: profile.verificationStatus || 'pending',
              uploadedAt: d.uploadedAt || profile.createdAt || new Date(),
            }))
          : DEFAULT_DOCUMENTS.map((d) => ({
              ...d,
              status: profile.verificationStatus || 'pending',
              uploadedAt: profile.createdAt || new Date(),
            }));

        await VerificationRequest.create({
          babysitter: sitter._id,
          babysitterProfile: profile._id,
          status: profile.verificationStatus || 'pending',
          documents: docs,
          reviewNotes: profile.verificationNotes || '',
          reviewedAt: profile.verificationReviewedAt || null,
          reviewedBy: profile.verificationReviewedBy || null,
          submittedAt: profile.createdAt || new Date(),
        });
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
  if (!isDbConnected() || !mongoose.Types.ObjectId.isValid(id)) {
    throw new ApiError(400, 'Invalid verification request ID');
  }

  const request = await VerificationRequest.findById(id);
  if (!request) throw new ApiError(404, 'Verification request not found');

  if (request.status === 'verified') {
    throw new ApiError(400, 'Verification request is already approved');
  }

  const approvalNote = notes || request.reviewNotes || 'Approved by agency';
  const now = new Date();

  request.status = 'verified';
  request.reviewNotes = approvalNote;
  request.reviewedBy = adminUser?._id;
  request.reviewedAt = now;
  await request.save();

  // Synchronize BabysitterProfile
  await BabysitterProfile.findOneAndUpdate(
    { $or: [{ _id: request.babysitterProfile }, { user: request.babysitter }] },
    {
      verificationStatus: 'verified',
      verificationReviewedAt: now,
      verificationReviewedBy: adminUser?._id,
      verificationNotes: approvalNote,
    }
  );

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
  await request.save();

  // Synchronize BabysitterProfile
  await BabysitterProfile.findOneAndUpdate(
    { $or: [{ _id: request.babysitterProfile }, { user: request.babysitter }] },
    {
      verificationStatus: 'rejected',
      verificationReviewedAt: now,
      verificationReviewedBy: adminUser?._id,
      verificationNotes: reason.trim(),
    }
  );

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
  await request.save();

  // Synchronize BabysitterProfile
  await BabysitterProfile.findOneAndUpdate(
    { $or: [{ _id: request.babysitterProfile }, { user: request.babysitter }] },
    {
      verificationStatus: 'changes_requested',
      verificationReviewedAt: now,
      verificationReviewedBy: adminUser?._id,
      verificationNotes: notes.trim(),
    }
  );

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
