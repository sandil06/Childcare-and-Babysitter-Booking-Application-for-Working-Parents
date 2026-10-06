const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema(
  {
    actor: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    action: {
      type: String,
      required: true,
      enum: [
        'approve_verification',
        'reject_verification',
        'request_changes_verification',
        'suspend_user',
        'reactivate_user',
        'resolve_report',
        'dismiss_report',
        'escalate_report',
        'update_booking_status',
        'system_config_change',
      ],
    },
    targetType: {
      type: String,
      required: true,
      enum: ['User', 'BabysitterProfile', 'VerificationRequest', 'Booking', 'Report'],
    },
    targetId: {
      type: String,
      required: true,
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

auditLogSchema.index({ actor: 1, createdAt: -1 });
auditLogSchema.index({ targetType: 1, targetId: 1 });
auditLogSchema.index({ action: 1, createdAt: -1 });

module.exports = mongoose.models.AuditLog || mongoose.model('AuditLog', auditLogSchema);
