const mongoose = require('mongoose');
const Notification = require('../models/Notification');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');

// Memory store fallback
const memoryNotifications = new Map();

function isDbConnected() {
  return mongoose.connection.readyState === 1;
}

function getUserId(req) {
  return req.user?.sub || req.user?.id;
}

async function list(req, res, next) {
  try {
    const userId = getUserId(req);

    if (isDbConnected()) {
      const notifications = await Notification.find({ user: userId }).sort({
        createdAt: -1,
      });
      return ApiResponse.success(res, notifications, 'Notifications retrieved');
    }

    // Memory fallback
    let userNotifs = Array.from(memoryNotifications.values()).filter(
      (n) => n.user.toString() === userId.toString()
    );

    if (userNotifs.length === 0) {
      // Seed initial sample notifications for the user
      userNotifs = [
        {
          _id: 'notif-1',
          id: 'notif-1',
          user: userId,
          title: 'New Booking Request',
          message: 'Sarah Jenkins requested a 4-hour booking for today at 3:00 PM.',
          type: 'new_booking_request',
          isRead: false,
          createdAt: new Date(Date.now() - 25 * 60 * 1000),
        },
        {
          _id: 'notif-2',
          id: 'notif-2',
          user: userId,
          title: 'Payment Received',
          message: 'You received $112.00 for your booking with Emily Watson.',
          type: 'payment_received',
          isRead: false,
          createdAt: new Date(Date.now() - 3 * 3600 * 1000),
        },
        {
          _id: 'notif-3',
          id: 'notif-3',
          user: userId,
          title: 'Verification Approved',
          message: 'Congratulations! Your CPR and Police Clearance have been verified.',
          type: 'verification_approved',
          isRead: true,
          createdAt: new Date(Date.now() - 24 * 3600 * 1000),
        },
        {
          _id: 'notif-4',
          id: 'notif-4',
          user: userId,
          title: 'Upcoming Booking Reminder',
          message: 'You have an upcoming booking tomorrow at 10:00 AM with Michael Chang.',
          type: 'upcoming_booking_reminder',
          isRead: true,
          createdAt: new Date(Date.now() - 26 * 3600 * 1000),
        },
      ];
      userNotifs.forEach((n) => memoryNotifications.set(n.id, n));
    }

    return ApiResponse.success(res, userNotifs, 'Notifications retrieved');
  } catch (err) {
    next(err);
  }
}

async function markRead(req, res, next) {
  try {
    const userId = getUserId(req);
    const notifId = req.params.id;

    if (isDbConnected()) {
      const notif = await Notification.findOne({ _id: notifId, user: userId });
      if (!notif) return next(new ApiError(404, 'Notification not found'));

      notif.isRead = true;
      notif.readAt = new Date();
      await notif.save();

      return ApiResponse.success(res, notif, 'Notification marked as read');
    }

    // Memory fallback
    const notif = memoryNotifications.get(notifId);
    if (!notif) return next(new ApiError(404, 'Notification not found'));
    notif.isRead = true;
    notif.readAt = new Date();
    memoryNotifications.set(notifId, notif);
    return ApiResponse.success(res, notif, 'Notification marked as read');
  } catch (err) {
    next(err);
  }
}

async function markAllRead(req, res, next) {
  try {
    const userId = getUserId(req);

    if (isDbConnected()) {
      await Notification.updateMany(
        { user: userId, isRead: false },
        { $set: { isRead: true, readAt: new Date() } }
      );
      return ApiResponse.success(res, null, 'All notifications marked as read');
    }

    // Memory fallback
    for (const [id, notif] of memoryNotifications.entries()) {
      if (notif.user.toString() === userId.toString()) {
        notif.isRead = true;
        notif.readAt = new Date();
        memoryNotifications.set(id, notif);
      }
    }

    return ApiResponse.success(res, null, 'All notifications marked as read');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  list,
  markRead,
  markAllRead,
};
