const mongoose = require('mongoose');
const Booking = require('../models/Booking');
const BabysitterProfile = require('../models/BabysitterProfile');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');

// Memory store fallback
const memoryBookings = new Map();

function isDbConnected() {
  return mongoose.connection.readyState === 1;
}

function getUserId(req) {
  return req.user?.sub || req.user?.id;
}

function getPageParams(query) {
  const page = Math.max(1, Number.parseInt(query.page, 10) || 1);
  const limit = Math.min(50, Math.max(1, Number.parseInt(query.limit, 10) || 20));
  return { page, limit, skip: (page - 1) * limit };
}

// Allowed job lifecycle transitions
const ALLOWED_STATUS_TRANSITIONS = {
  pending: ['accepted', 'rejected', 'cancelled'],
  accepted: ['travelling', 'confirmed', 'cancelled'],
  confirmed: ['travelling', 'cancelled'],
  travelling: ['arrived', 'cancelled'],
  arrived: ['in_progress', 'cancelled'],
  in_progress: ['completed', 'cancelled'],
  completed: [],
  cancelled: [],
  rejected: [],
};

async function getMeBookings(req, res, next) {
  try {
    const userId = getUserId(req);
    const { status } = req.query;
    const { page, limit, skip } = getPageParams(req.query);

    if (isDbConnected()) {
      const filter = { babysitter: userId };
      if (status && status !== 'all') {
        filter.status = status;
      }
      const bookings = await Booking.find(filter)
        .populate('parent', 'name email phone avatar')
        .sort({ date: -1, startTime: 1 })
        .skip(skip)
        .limit(limit);
      res.set('X-Page', String(page));
      res.set('X-Limit', String(limit));
      res.set('X-Has-More', String(bookings.length === limit));
      return ApiResponse.success(res, bookings, 'Bookings retrieved');
    }

    // Memory fallback
    let list = Array.from(memoryBookings.values()).filter(
      (b) => b.babysitter.toString() === userId.toString()
    );
    if (status && status !== 'all') {
      list = list.filter((b) => b.status === status);
    }
    const paged = list.slice(skip, skip + limit);
    res.set('X-Page', String(page));
    res.set('X-Limit', String(limit));
    res.set('X-Has-More', String(skip + limit < list.length));
    return ApiResponse.success(res, paged, 'Bookings retrieved');
  } catch (err) {
    next(err);
  }
}

async function getMeBookingRequests(req, res, next) {
  try {
    req.query.status = 'pending';
    return getMeBookings(req, res, next);
  } catch (err) {
    next(err);
  }
}

async function getById(req, res, next) {
  try {
    const bookingId = req.params.id;

    if (isDbConnected()) {
      const booking = await Booking.findById(bookingId).populate(
        'parent babysitter',
        'name email phone avatar'
      );
      if (!booking) return next(new ApiError(404, 'Booking not found'));
      const userId = getUserId(req).toString();
      if (booking.parent._id.toString() !== userId && booking.babysitter._id.toString() !== userId) {
        return next(new ApiError(403, 'You are not authorized to view this booking'));
      }
      return ApiResponse.success(res, booking, 'Booking details retrieved');
    }

    const booking = memoryBookings.get(bookingId);
    if (!booking) return next(new ApiError(404, 'Booking not found'));
    const userId = getUserId(req).toString();
    if (booking.parent.toString() !== userId && booking.babysitter.toString() !== userId) {
      return next(new ApiError(403, 'You are not authorized to view this booking'));
    }
    return ApiResponse.success(res, booking, 'Booking details retrieved');
  } catch (err) {
    next(err);
  }
}

async function accept(req, res, next) {
  try {
    const userId = getUserId(req);
    const bookingId = req.params.id;

    if (isDbConnected()) {
      const booking = await Booking.findById(bookingId).populate(
        'parent',
        'name email phone avatar'
      );
      if (!booking) return next(new ApiError(404, 'Booking not found'));

      if (booking.babysitter.toString() !== userId.toString()) {
        return next(new ApiError(403, 'You are not authorized to accept this booking'));
      }

      if (booking.status !== 'pending') {
        return next(
          new ApiError(400, `Cannot accept booking with current status "${booking.status}"`)
        );
      }

      booking.status = 'accepted';
      await booking.save();

      return ApiResponse.success(res, booking, 'Booking accepted successfully');
    }

    // Memory fallback
    const booking = memoryBookings.get(bookingId);
    if (!booking) return next(new ApiError(404, 'Booking not found'));
    if (booking.babysitter.toString() !== userId.toString()) {
      return next(new ApiError(403, 'You are not authorized to accept this booking'));
    }
    if (booking.status !== 'pending') {
      return next(
        new ApiError(400, `Cannot accept booking with current status "${booking.status}"`)
      );
    }
    booking.status = 'accepted';
    booking.updatedAt = new Date();
    memoryBookings.set(bookingId, booking);
    return ApiResponse.success(res, booking, 'Booking accepted successfully');
  } catch (err) {
    next(err);
  }
}

async function reject(req, res, next) {
  try {
    const userId = getUserId(req);
    const bookingId = req.params.id;
    const { reason } = req.body;

    if (isDbConnected()) {
      const booking = await Booking.findById(bookingId).populate(
        'parent',
        'name email phone avatar'
      );
      if (!booking) return next(new ApiError(404, 'Booking not found'));

      if (booking.babysitter.toString() !== userId.toString()) {
        return next(new ApiError(403, 'You are not authorized to decline this booking'));
      }

      if (booking.status !== 'pending') {
        return next(
          new ApiError(400, `Cannot decline booking with current status "${booking.status}"`)
        );
      }

      booking.status = 'rejected';
      booking.rejectionReason = reason || 'Declined by babysitter';
      await booking.save();

      return ApiResponse.success(res, booking, 'Booking declined successfully');
    }

    // Memory fallback
    const booking = memoryBookings.get(bookingId);
    if (!booking) return next(new ApiError(404, 'Booking not found'));
    if (booking.babysitter.toString() !== userId.toString()) {
      return next(new ApiError(403, 'You are not authorized to decline this booking'));
    }
    if (booking.status !== 'pending') {
      return next(
        new ApiError(400, `Cannot decline booking with current status "${booking.status}"`)
      );
    }
    booking.status = 'rejected';
    booking.rejectionReason = reason || 'Declined by babysitter';
    booking.updatedAt = new Date();
    memoryBookings.set(bookingId, booking);
    return ApiResponse.success(res, booking, 'Booking declined successfully');
  } catch (err) {
    next(err);
  }
}

async function updateStatus(req, res, next) {
  try {
    const userId = getUserId(req);
    const bookingId = req.params.id;
    const { status: newStatus } = req.body;

    if (!newStatus) return next(new ApiError(400, 'New status is required'));

    if (isDbConnected()) {
      const booking = await Booking.findById(bookingId).populate(
        'parent',
        'name email phone avatar'
      );
      if (!booking) return next(new ApiError(404, 'Booking not found'));

      if (booking.babysitter.toString() !== userId.toString()) {
        return next(new ApiError(403, 'You are not authorized to update this booking'));
      }

      const allowedTargets = ALLOWED_STATUS_TRANSITIONS[booking.status] || [];
      if (!allowedTargets.includes(newStatus)) {
        return next(
          new ApiError(
            400,
            `Invalid status transition from "${booking.status}" to "${newStatus}". Allowed next statuses: ${allowedTargets.join(', ')}`
          )
        );
      }

      booking.status = newStatus;
      await booking.save();

      // If marked completed, update babysitter completed bookings count
      if (newStatus === 'completed') {
        await BabysitterProfile.updateOne(
          { user: userId },
          { $inc: { totalCompletedBookings: 1 } }
        );
      }

      return ApiResponse.success(res, booking, `Booking status updated to ${newStatus}`);
    }

    // Memory fallback
    const booking = memoryBookings.get(bookingId);
    if (!booking) return next(new ApiError(404, 'Booking not found'));
    if (booking.babysitter.toString() !== userId.toString()) {
      return next(new ApiError(403, 'You are not authorized to update this booking'));
    }

    const allowedTargets = ALLOWED_STATUS_TRANSITIONS[booking.status] || [];
    if (!allowedTargets.includes(newStatus)) {
      return next(
        new ApiError(
          400,
          `Invalid status transition from "${booking.status}" to "${newStatus}". Allowed next statuses: ${allowedTargets.join(', ')}`
        )
      );
    }

    booking.status = newStatus;
    booking.updatedAt = new Date();
    memoryBookings.set(bookingId, booking);
    return ApiResponse.success(res, booking, `Booking status updated to ${newStatus}`);
  } catch (err) {
    next(err);
  }
}

async function create(req, res, next) {
  try {
    if (isDbConnected()) {
      const booking = await Booking.create(req.body);
      return ApiResponse.success(res, booking, 'Booking created', 201);
    }
    const id = `bk-${Date.now()}`;
    const newBooking = { _id: id, id, ...req.body, status: 'pending', createdAt: new Date() };
    memoryBookings.set(id, newBooking);
    return ApiResponse.success(res, newBooking, 'Booking created', 201);
  } catch (err) {
    next(err);
  }
}

async function list(req, res, next) {
  try {
    const userId = getUserId(req);
    const { page, limit, skip } = getPageParams(req.query);
    if (isDbConnected()) {
      const filter = { $or: [{ parent: userId }, { babysitter: userId }] };
      if (req.query.status) filter.status = req.query.status;
      const bookings = await Booking.find(filter)
        .sort({ date: -1 })
        .skip(skip)
        .limit(limit);
      return ApiResponse.success(res, bookings, 'Bookings retrieved');
    }
    const list = Array.from(memoryBookings.values()).filter(
      (booking) => booking.parent.toString() === userId.toString() || booking.babysitter.toString() === userId.toString()
    );
    return ApiResponse.success(res, list.slice(skip, skip + limit), 'Bookings retrieved');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getMeBookings,
  getMeBookingRequests,
  getById,
  accept,
  reject,
  updateStatus,
  create,
  list,
};
