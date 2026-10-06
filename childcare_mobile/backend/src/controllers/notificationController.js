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

const BOOKING_TYPES = [
  'new_booking_request',
  'booking_accepted',
  'booking_rejected',
  'booking_cancelled',
  'booking_rescheduled',
  'booking_confirmed',
  'upcoming_booking_reminder',
  'payment_received',
  'travelling',
  'arrived',
  'in_progress',
  'completed',
];

const MESSAGE_TYPES = ['new_message'];

/**
 * Creates and stores a notification, and optionally emits to Socket.IO room
 */
async function createNotification({ userId, title, message, type = 'system', data = {}, io = null }) {
  try {
    let saved = null;
    if (isDbConnected() && mongoose.Types.ObjectId.isValid(userId)) {
      saved = await Notification.create({
        user: userId,
        title,
        message,
        type,
        data,
      });
    } else {
      const id = `notif-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
      saved = {
        _id: id,
        id,
        user: userId,
        title,
        message,
        type,
        data,
        isRead: false,
        createdAt: new Date(),
      };
      memoryNotifications.set(id, saved);
    }

    if (io) {
      io.to(`user:${userId}`).emit('notification', saved);
    }
    return saved;
  } catch (err) {
    console.warn('[NotificationController] createNotification error:', err.message);
  }
}

async function list(req, res, next) {
  try {
    const userId = getUserId(req);
    const { category } = req.query;
    const page = Math.max(1, Number.parseInt(req.query.page, 10) || 1);
    const limit = Math.min(50, Number.parseInt(req.query.limit, 10) || 20);
    const skip = (page - 1) * limit;

    const queryFilter = { user: userId };
    if (category === 'bookings') {
      queryFilter.type = { $in: BOOKING_TYPES };
    } else if (category === 'messages') {
      queryFilter.type = { $in: MESSAGE_TYPES };
    }

    if (isDbConnected()) {
      const notifications = await Notification.find(queryFilter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit);
      return ApiResponse.success(res, notifications, 'Notifications retrieved');
    }

    // Memory fallback
    let userNotifs = Array.from(memoryNotifications.values()).filter(
      (n) => n.user.toString() === userId.toString()
    );

    if (userNotifs.length === 0) {
      // Seed sample notifications if empty
      userNotifs = [
        {
          _id: 'notif-1',
          id: 'notif-1',
          user: userId,
          title: 'Booking Confirmed',
          message: 'Your booking with Amaya Fernando has been confirmed.',
          type: 'booking_accepted',
          isRead: false,
          createdAt: new Date(Date.now() - 15 * 60 * 1000),
          data: { bookingId: 'BK-10293' },
        },
        {
          _id: 'notif-2',
          id: 'notif-2',
          user: userId,
          title: 'New Message',
          message: 'Amaya Fernando: "Hello, I will arrive 10 minutes early."',
          type: 'new_message',
          isRead: false,
          createdAt: new Date(Date.now() - 35 * 60 * 1000),
          data: { conversationId: 'conv-1' },
        },
        {
          _id: 'notif-3',
          id: 'notif-3',
          user: userId,
          title: 'Payment Confirmed',
          message: 'Payment of Rs. 6,000 via Stripe Sandbox was successful.',
          type: 'payment_received',
          isRead: true,
          createdAt: new Date(Date.now() - 2 * 3600 * 1000),
          data: { amount: 6000 },
        },
      ];
      userNotifs.forEach((n) => memoryNotifications.set(n.id, n));
    }

    if (category === 'bookings') {
      userNotifs = userNotifs.filter((n) => BOOKING_TYPES.includes(n.type));
    } else if (category === 'messages') {
      userNotifs = userNotifs.filter((n) => MESSAGE_TYPES.includes(n.type));
    }

    userNotifs.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    return ApiResponse.success(res, userNotifs.slice(skip, skip + limit), 'Notifications retrieved');
  } catch (err) {
    next(err);
  }
}

async function markRead(req, res, next) {
  try {
    const userId = getUserId(req);
    const notifId = req.params.id;

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(notifId)) {
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
  createNotification,
  memoryNotifications,
};
