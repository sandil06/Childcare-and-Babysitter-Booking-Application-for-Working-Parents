const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    message: {
      type: String,
      required: true,
      trim: true,
    },
    type: {
      type: String,
      enum: [
        'new_booking_request',
        'booking_accepted',
        'booking_cancelled',
        'booking_rescheduled',
        'upcoming_booking_reminder',
        'new_message',
        'payment_received',
        'verification_approved',
        'verification_rejected',
        'system',
        'verification_submitted',
        'verification_updated',
        'verification_changes_requested',
        'safety_report',
        'high_priority_complaint',
        'system_alert',
        'agency_broadcast',
        'user_suspended',
        'user_reactivated',
        'booking_emergency_cancelled',
        'account_activity',
      ],
      default: 'system',
    },
    isRead: {
      type: Boolean,
      default: false,
    },
    readAt: {
      type: Date,
      default: null,
    },
    data: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
  },
  { timestamps: true }
);

notificationSchema.index({ user: 1, isRead: 1, createdAt: -1 });

module.exports =
  mongoose.models.Notification ||
  mongoose.model('Notification', notificationSchema);
