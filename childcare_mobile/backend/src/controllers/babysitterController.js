const mongoose = require('mongoose');
const Booking = require('../models/Booking');
const Notification = require('../models/Notification');
const ApiResponse = require('../utils/ApiResponse');
const generateToken = require('../utils/generateToken');
const babysitterService = require('../services/babysitterService');
const ROLES = require('../constants/roles');

function isDbConnected() {
  return mongoose.connection.readyState === 1;
}

function getUserId(req) {
  return req.user?.sub || req.user?.id;
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

async function updateMe(req, res, next) {
  try {
    const userId = getUserId(req);
    const updated = await babysitterService.updateProfileByUserId(userId, req.body);
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
      const completed = await Booking.find({ babysitter: userId, status: 'completed' });
      totalEarnings = completed.reduce(
        (sum, b) => sum + (b.total || (b.hourlyRate * b.durationHours)),
        0
      );
      completedBookingsCount = completed.length;

      upcomingBooking = await Booking.findOne({
        babysitter: userId,
        status: { $in: ['accepted', 'confirmed', 'travelling', 'arrived', 'in_progress'] },
      })
        .populate('parent', 'name email phone avatar')
        .sort({ date: 1, startTime: 1 });

      newRequests = await Booking.find({
        babysitter: userId,
        status: 'pending',
      })
        .populate('parent', 'name email phone avatar')
        .sort({ date: 1, startTime: 1 });

      unreadCount = await Notification.countDocuments({ user: userId, isRead: false });
    }

    const stats = {
      totalEarnings: Number(totalEarnings.toFixed(2)),
      rating: profile?.averageRating || 5.0,
      completedBookings: completedBookingsCount,
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
    const profile = await babysitterService.getProfileByUserId(req.params.id);
    return ApiResponse.success(res, profile, 'Profile retrieved');
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
};
