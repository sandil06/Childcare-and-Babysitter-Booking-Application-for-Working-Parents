const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema(
  {
    actor: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
      index: true,
    },
    adminName: {
      type: String,
      default: 'Agency Administrator',
      trim: true,
    },
    adminEmail: {
      type: String,
      default: '',
      trim: true,
    },
    action: {
      type: String,
      required: true,
      index: true,
    },
    targetType: {
      type: String,
      required: true,
      enum: ['User', 'BabysitterProfile', 'VerificationRequest', 'Booking', 'Report', 'System'],
      index: true,
    },
    targetId: {
      type: String,
      required: true,
      index: true,
    },
    metadata: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
    notes: {
      type: String,
      default: '',
    },
    ipAddress: {
      type: String,
      default: '',
    },
  },
  { timestamps: true }
);

auditLogSchema.index({ createdAt: -1 });
auditLogSchema.index({ action: 1, createdAt: -1 });
auditLogSchema.index({ targetType: 1, targetId: 1 });
auditLogSchema.index({ actor: 1, createdAt: -1 });

auditLogSchema.statics.record = async function (data) {
  try {
    if (mongoose.connection.readyState !== 1) {
      return null;
    }
    const actorId = data.actor || data.adminId;
    const doc = {
      actor: actorId && mongoose.Types.ObjectId.isValid(actorId) ? actorId : null,
      adminName: data.adminName || 'Agency Administrator',
      adminEmail: data.adminEmail || '',
      action: data.action,
      targetType: data.targetType,
      targetId: String(data.targetId || ''),
      notes: data.notes || '',
      metadata: data.metadata || {},
      ipAddress: data.ipAddress || '',
    };
    return await this.create(doc);
  } catch (err) {
    console.error('[AuditLog.record error]', err.message);
    return null;
  }
};

module.exports = mongoose.models.AuditLog || mongoose.model('AuditLog', auditLogSchema);
