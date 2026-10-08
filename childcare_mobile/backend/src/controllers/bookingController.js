const mongoose = require('mongoose');
const Booking = require('../models/Booking');
const BabysitterProfile = require('../models/BabysitterProfile');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');
const bookingService = require('../services/bookingService');
const { createNotification } = require('./notificationController');

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
      const sitterProfile = await BabysitterProfile.findOne({ user: userId });
      const sitterIds = [userId];
      if (sitterProfile) sitterIds.push(sitterProfile._id);

      const filter = { babysitter: { $in: sitterIds } };
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

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(bookingId)) {
      const booking = await Booking.findById(bookingId).populate(
        'parent babysitter',
        'name email phone avatar'
      );
      if (!booking) return next(new ApiError(404, 'Booking not found'));
      const userId = getUserId(req).toString();
      const sitterProfile = await BabysitterProfile.findOne({ user: userId });
      const allowedSitterIds = [userId];
      if (sitterProfile) allowedSitterIds.push(sitterProfile._id.toString());

      const parentId = booking.parent?._id ? booking.parent._id.toString() : booking.parent?.toString();
      const sitterId = booking.babysitter?._id ? booking.babysitter._id.toString() : booking.babysitter?.toString();

      if (parentId !== userId && !allowedSitterIds.includes(sitterId)) {
        return next(new ApiError(403, 'You are not authorized to view this booking'));
      }
      return ApiResponse.success(res, booking, 'Booking details retrieved');
    }

    const booking = memoryBookings.get(bookingId);
    if (!booking) return next(new ApiError(404, 'Booking not found'));
    const userId = getUserId(req).toString();
    const parentId = booking.parent?._id ? booking.parent._id.toString() : booking.parent?.toString();
    const sitterId = booking.babysitter?._id ? booking.babysitter._id.toString() : booking.babysitter?.toString();
    if (parentId !== userId && sitterId !== userId) {
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

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(bookingId)) {
      const booking = await Booking.findById(bookingId).populate(
        'parent',
        'name email phone avatar'
      );
      if (!booking) return next(new ApiError(404, 'Booking not found'));

      const sitterProfile = await BabysitterProfile.findOne({ user: userId });
      const allowedSitterIds = [userId.toString()];
      if (sitterProfile) allowedSitterIds.push(sitterProfile._id.toString());

      const sitterId = booking.babysitter?._id ? booking.babysitter._id.toString() : booking.babysitter?.toString();
      if (!allowedSitterIds.includes(sitterId)) {
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

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(bookingId)) {
      const booking = await Booking.findById(bookingId).populate(
        'parent',
        'name email phone avatar'
      );
      if (!booking) return next(new ApiError(404, 'Booking not found'));

      const sitterProfile = await BabysitterProfile.findOne({ user: userId });
      const allowedSitterIds = [userId.toString()];
      if (sitterProfile) allowedSitterIds.push(sitterProfile._id.toString());

      const sitterId = booking.babysitter?._id ? booking.babysitter._id.toString() : booking.babysitter?.toString();
      if (!allowedSitterIds.includes(sitterId)) {
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

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(bookingId)) {
      const booking = await Booking.findById(bookingId).populate(
        'parent',
        'name email phone avatar'
      );
      if (!booking) return next(new ApiError(404, 'Booking not found'));

      const sitterProfile = await BabysitterProfile.findOne({ user: userId });
      const allowedSitterIds = [userId.toString()];
      if (sitterProfile) allowedSitterIds.push(sitterProfile._id.toString());

      const sitterId = booking.babysitter?._id ? booking.babysitter._id.toString() : booking.babysitter?.toString();
      if (!allowedSitterIds.includes(sitterId)) {
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

      // Notify parent of caregiver progress
      const parentId = booking.parent?._id || booking.parent;
      if (parentId) {
        const notifMap = {
          travelling: { title: 'Caregiver Travelling', message: 'Your babysitter is on the way to your address.' },
          arrived: { title: 'Caregiver Arrived', message: 'Your babysitter has arrived at your address.' },
          in_progress: { title: 'Service In Progress', message: 'Childcare service has officially started.' },
          completed: { title: 'Service Completed', message: 'Childcare service is completed. Please review your caregiver.' },
        };
        if (notifMap[newStatus]) {
          createNotification({
            userId: parentId,
            title: notifMap[newStatus].title,
            message: notifMap[newStatus].message,
            type: newStatus,
            data: { bookingId: booking._id || booking.id },
          }).catch(() => {});
        }
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

    // Notify parent in memory mode
    const memParentId = booking.parent?._id || booking.parent;
    if (memParentId) {
      const notifMap = {
        travelling: { title: 'Caregiver Travelling', message: 'Your babysitter is on the way to your address.' },
        arrived: { title: 'Caregiver Arrived', message: 'Your babysitter has arrived at your address.' },
        in_progress: { title: 'Service In Progress', message: 'Childcare service has officially started.' },
        completed: { title: 'Service Completed', message: 'Childcare service is completed. Please review your caregiver.' },
      };
      if (notifMap[newStatus]) {
        createNotification({
          userId: memParentId,
          title: notifMap[newStatus].title,
          message: notifMap[newStatus].message,
          type: newStatus,
          data: { bookingId: booking._id || booking.id },
        }).catch(() => {});
      }
    }

    return ApiResponse.success(res, booking, `Booking status updated to ${newStatus}`);
  } catch (err) {
    next(err);
  }
}

async function calculatePrice(req, res, next) {
  try {
    const babysitterId = req.body.babysitterId || req.body.babysitter;
    const { date, startTime, endTime } = req.body;
    const priceData = await bookingService.calculatePrice({
      babysitterId,
      date: date || new Date(),
      startTime,
      endTime,
    });
    return ApiResponse.success(res, priceData, 'Price calculated successfully');
  } catch (err) {
    next(err);
  }
}

async function create(req, res, next) {
  try {
    const parentId = getUserId(req) || req.body.parent || req.body.parentId;
    let babysitterId = req.body.babysitter || req.body.babysitterId;

    let date = req.body.date ? new Date(req.body.date) : (req.body.startAt ? new Date(req.body.startAt) : new Date());
    let startTime = req.body.startTime;
    let endTime = req.body.endTime;
    if (!startTime && req.body.startAt) {
      const s = new Date(req.body.startAt);
      startTime = `${String(s.getHours()).padStart(2, '0')}:${String(s.getMinutes()).padStart(2, '0')}`;
    }
    if (!endTime && req.body.endAt) {
      const e = new Date(req.body.endAt);
      endTime = `${String(e.getHours()).padStart(2, '0')}:${String(e.getMinutes()).padStart(2, '0')}`;
    }

    startTime = startTime || '09:00';
    endTime = endTime || '13:00';

    if (babysitterId && isDbConnected() && mongoose.Types.ObjectId.isValid(babysitterId)) {
      const profile = await BabysitterProfile.findById(babysitterId);
      if (profile && profile.user) {
        babysitterId = profile.user;
      }
    }

    // Check for overlapping bookings (works for both MongoDB and in-memory store)
    const conflictCheck = await bookingService.checkAvailabilityAndConflicts({
      babysitterId,
      date,
      startTime,
      endTime,
      memoryStore: memoryBookings,
    });
    if (!conflictCheck.available) {
      return next(new ApiError(400, conflictCheck.reason));
    }

    if (isDbConnected()) {


      // Calculate server-side duration & price
      let durationHours = req.body.durationHours || req.body.duration;
      try {
        durationHours = bookingService.calculateDurationHours(startTime, endTime);
      } catch (_) {
        durationHours = durationHours || 4.0;
      }

      const hourlyRate = req.body.hourlyRate || (await bookingService.getBabysitterHourlyRate(babysitterId));
      const subtotal = Math.round(durationHours * hourlyRate);
      const serviceFee = req.body.serviceFee || 0;
      const totalAmount = subtotal + serviceFee;

      const booking = await Booking.create({
        ...req.body,
        parent: parentId,
        babysitter: babysitterId,
        date,
        startTime,
        endTime,
        durationHours,
        hourlyRate,
        subtotal,
        serviceFee,
        total: totalAmount,
        totalAmount,
        location: req.body.address || req.body.location || 'Colombo, Sri Lanka',
        status: 'pending',
        paymentStatus: req.body.paymentStatus || 'pending',
      });
      return ApiResponse.success(res, booking, 'Booking created', 201);
    }

    let durationHours = req.body.durationHours || req.body.duration;
    try {
      durationHours = bookingService.calculateDurationHours(startTime, endTime);
    } catch (_) {
      durationHours = durationHours || 4.0;
    }

    const hourlyRate = req.body.hourlyRate || (await bookingService.getBabysitterHourlyRate(babysitterId));
    const subtotal = Math.round(durationHours * hourlyRate);
    const serviceFee = req.body.serviceFee || 0;
    const totalAmount = subtotal + serviceFee;

    const id = `bk-${Date.now()}`;
    const newBooking = {
      _id: id,
      id,
      ...req.body,
      parent: parentId,
      babysitter: babysitterId,
      date,
      startTime,
      endTime,
      durationHours,
      hourlyRate,
      subtotal,
      serviceFee,
      total: totalAmount,
      totalAmount,
      location: req.body.address || req.body.location || 'Colombo, Sri Lanka',
      status: 'pending',
      paymentStatus: 'pending',
      createdAt: new Date(),
    };
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
    const requestedStatus = req.query.status;

    if (isDbConnected()) {
      const filter = { $or: [{ parent: userId }, { babysitter: userId }] };

      if (requestedStatus) {
        if (requestedStatus === 'upcoming') {
          filter.status = { $in: ['accepted', 'confirmed', 'travelling', 'arrived', 'in_progress', 'pending'] };
        } else if (requestedStatus === 'completed') {
          filter.status = 'completed';
        } else if (requestedStatus === 'cancelled') {
          filter.status = { $in: ['cancelled', 'rejected'] };
        } else {
          filter.status = requestedStatus;
        }
      }

      const bookings = await Booking.find(filter)
        .populate('parent', 'name email phone avatar')
        .populate('babysitter', 'name email phone avatar')
        .sort({ date: -1, startTime: 1 })
        .skip(skip)
        .limit(limit);

      res.set('X-Page', String(page));
      res.set('X-Limit', String(limit));
      res.set('X-Has-More', String(bookings.length === limit));
      return ApiResponse.success(res, bookings, 'Bookings retrieved');
    }

    let list = Array.from(memoryBookings.values()).filter(
      (b) =>
        b.parent?.toString() === userId.toString() ||
        b.babysitter?.toString() === userId.toString()
    );

    if (requestedStatus) {
      if (requestedStatus === 'upcoming') {
        list = list.filter((b) =>
          ['accepted', 'confirmed', 'travelling', 'arrived', 'in_progress', 'pending'].includes(b.status)
        );
      } else if (requestedStatus === 'completed') {
        list = list.filter((b) => b.status === 'completed');
      } else if (requestedStatus === 'cancelled') {
        list = list.filter((b) => ['cancelled', 'rejected'].includes(b.status));
      } else {
        list = list.filter((b) => b.status === requestedStatus);
      }
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

async function cancel(req, res, next) {
  try {
    const userId = getUserId(req);
    const bookingId = req.params.id;
    const reason = req.body.reason || req.body.cancellationReason || 'Cancelled by user';

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(bookingId)) {
      const booking = await Booking.findById(bookingId).populate('parent babysitter', 'name email phone avatar');
      if (!booking) return next(new ApiError(404, 'Booking not found'));

      const parentId = booking.parent?._id ? booking.parent._id.toString() : booking.parent?.toString();
      const sitterId = booking.babysitter?._id ? booking.babysitter._id.toString() : booking.babysitter?.toString();

      const userRole = req.user?.role;
      const isAdminOrAgency = ['agency', 'admin'].includes(userRole);
      if (parentId !== userId.toString() && sitterId !== userId.toString() && !isAdminOrAgency) {
        return next(new ApiError(403, 'You are not authorized to cancel this booking'));
      }

      if (['completed', 'cancelled', 'rejected'].includes(booking.status)) {
        return next(new ApiError(400, `Cannot cancel booking with current status "${booking.status}"`));
      }

      booking.status = 'cancelled';
      booking.cancelledBy = userId;
      booking.cancellationReason = reason;
      booking.cancelledAt = new Date();
      await booking.save();

      // Notify the other user (sitter if parent cancelled, parent if sitter cancelled)
      const recipientId = (userId.toString() === parentId) ? sitterId : parentId;
      if (recipientId) {
        createNotification({
          userId: recipientId,
          title: 'Booking Cancelled',
          message: `Booking #${booking.bookingId || booking._id} has been cancelled: ${reason}`,
          type: 'booking_cancelled',
          data: { bookingId: booking._id },
        }).catch(() => {});
      }

      return ApiResponse.success(res, booking, 'Booking cancelled successfully');
    }

    const booking = memoryBookings.get(bookingId);
    if (!booking) return next(new ApiError(404, 'Booking not found'));
    const parentId = booking.parent?._id ? booking.parent._id.toString() : booking.parent?.toString();
    const sitterId = booking.babysitter?._id ? booking.babysitter._id.toString() : booking.babysitter?.toString();
    const userRole = req.user?.role;
    const isAdminOrAgency = ['agency', 'admin'].includes(userRole);
    if (parentId !== userId.toString() && sitterId !== userId.toString() && !isAdminOrAgency) {
      return next(new ApiError(403, 'You are not authorized to cancel this booking'));
    }

    if (['completed', 'cancelled', 'rejected'].includes(booking.status)) {
      return next(new ApiError(400, `Cannot cancel booking with current status "${booking.status}"`));
    }

    booking.status = 'cancelled';
    booking.cancelledBy = userId;
    booking.cancellationReason = reason;
    booking.cancelledAt = new Date();
    booking.updatedAt = new Date();
    memoryBookings.set(bookingId, booking);

    const recipientId = (userId.toString() === parentId) ? sitterId : parentId;
    if (recipientId) {
      createNotification({
        userId: recipientId,
        title: 'Booking Cancelled',
        message: `Booking #${booking.bookingId || booking._id || booking.id} has been cancelled: ${reason}`,
        type: 'booking_cancelled',
        data: { bookingId: booking._id || booking.id },
      }).catch(() => {});
    }

    return ApiResponse.success(res, booking, 'Booking cancelled successfully');
  } catch (err) {
    next(err);
  }
}

async function reschedule(req, res, next) {
  try {
    const userId = getUserId(req);
    const bookingId = req.params.id;
    const { date, startTime, endTime } = req.body;

    if (!date || !startTime || !endTime) {
      return next(new ApiError(400, 'date, startTime, and endTime are required for rescheduling'));
    }

    const sMin = bookingService.timeToMinutes(startTime);
    const eMin = bookingService.timeToMinutes(endTime);
    if (eMin <= sMin) {
      return next(new ApiError(400, 'End time must be after start time'));
    }

    const parsedDate = new Date(date);
    if (isNaN(parsedDate.getTime())) {
      return next(new ApiError(400, 'Invalid date format'));
    }

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(bookingId)) {
      const booking = await Booking.findById(bookingId).populate('parent babysitter', 'name email phone avatar');
      if (!booking) return next(new ApiError(404, 'Booking not found'));

      const parentId = booking.parent?._id ? booking.parent._id.toString() : booking.parent?.toString();
      const sitterId = booking.babysitter?._id ? booking.babysitter._id.toString() : booking.babysitter?.toString();

      const userRole = req.user?.role;
      const isAdminOrAgency = ['agency', 'admin'].includes(userRole);
      if (parentId !== userId.toString() && !isAdminOrAgency) {
        return next(new ApiError(403, 'You are not authorized to reschedule this booking'));
      }

      if (!['pending', 'accepted', 'confirmed'].includes(booking.status)) {
        return next(
          new ApiError(
            400,
            `Cannot reschedule a booking that is ${booking.status}. Rescheduling is only permitted for pending, accepted, or confirmed bookings.`
          )
        );
      }

      // Check conflict for new time slot
      const conflictCheck = await bookingService.checkAvailabilityAndConflicts({
        babysitterId: sitterId,
        date,
        startTime,
        endTime,
        excludeBookingId: booking._id,
      });
      if (!conflictCheck.available) {
        return next(new ApiError(400, conflictCheck.reason));
      }

      // Calculate new pricing
      const newDuration = bookingService.calculateDurationHours(startTime, endTime);
      const newSubtotal = Math.round(newDuration * (booking.hourlyRate || 1500));
      const newTotal = newSubtotal + (booking.serviceFee || 0);

      // Price change during reschedule validation:
      const currentPaidTotal = booking.total || booking.totalAmount;
      if (booking.paymentStatus === 'paid' && newTotal !== currentPaidTotal) {
        return next(
          new ApiError(
            400,
            'This booking cannot be rescheduled to a different price after payment.'
          )
        );
      }

      // Record reschedule history
      booking.rescheduleHistory = booking.rescheduleHistory || [];
      booking.rescheduleHistory.push({
        oldDate: booking.date,
        oldStartTime: booking.startTime,
        oldEndTime: booking.endTime,
        newDate: parsedDate,
        newStartTime: startTime,
        newEndTime: endTime,
        requestedAt: new Date(),
      });

      booking.date = parsedDate;
      booking.startTime = startTime;
      booking.endTime = endTime;
      booking.durationHours = newDuration;
      booking.subtotal = newSubtotal;
      booking.total = newTotal;
      booking.totalAmount = newTotal;

      await booking.save();

      // Notify babysitter
      if (sitterId) {
        const dateFormatted = parsedDate.toISOString().split('T')[0];
        createNotification({
          userId: sitterId,
          title: 'Booking Rescheduled',
          message: `Booking #${booking.bookingId || booking._id} has been rescheduled to ${dateFormatted} (${startTime} – ${endTime}).`,
          type: 'booking_rescheduled',
          data: { bookingId: booking._id },
        }).catch(() => {});
      }

      return ApiResponse.success(res, booking, 'Booking rescheduled successfully');
    }

    // Memory fallback
    const booking = memoryBookings.get(bookingId);
    if (!booking) return next(new ApiError(404, 'Booking not found'));

    const parentId = booking.parent?._id ? booking.parent._id.toString() : booking.parent?.toString();
    const sitterId = booking.babysitter?._id ? booking.babysitter._id.toString() : booking.babysitter?.toString();
    const userRole = req.user?.role;
    const isAdminOrAgency = ['agency', 'admin'].includes(userRole);
    if (parentId !== userId.toString() && !isAdminOrAgency) {
      return next(new ApiError(403, 'You are not authorized to reschedule this booking'));
    }

    if (!['pending', 'accepted', 'confirmed'].includes(booking.status)) {
      return next(
        new ApiError(
          400,
          `Cannot reschedule a booking that is ${booking.status}. Rescheduling is only permitted for pending, accepted, or confirmed bookings.`
        )
      );
    }

    const conflictCheck = await bookingService.checkAvailabilityAndConflicts({
      babysitterId: sitterId,
      date,
      startTime,
      endTime,
      excludeBookingId: booking._id || booking.id,
      memoryStore: memoryBookings,
    });
    if (!conflictCheck.available) {
      return next(new ApiError(400, conflictCheck.reason));
    }

    const newDuration = bookingService.calculateDurationHours(startTime, endTime);
    const newSubtotal = Math.round(newDuration * (booking.hourlyRate || 1500));
    const newTotal = newSubtotal + (booking.serviceFee || 0);

    const currentPaidTotal = booking.total || booking.totalAmount;
    if (booking.paymentStatus === 'paid' && newTotal !== currentPaidTotal) {
      return next(
        new ApiError(
          400,
          'This booking cannot be rescheduled to a different price after payment.'
        )
      );
    }

    booking.rescheduleHistory = booking.rescheduleHistory || [];
    booking.rescheduleHistory.push({
      oldDate: booking.date,
      oldStartTime: booking.startTime,
      oldEndTime: booking.endTime,
      newDate: parsedDate,
      newStartTime: startTime,
      newEndTime: endTime,
      requestedAt: new Date(),
    });

    booking.date = parsedDate;
    booking.startTime = startTime;
    booking.endTime = endTime;
    booking.durationHours = newDuration;
    booking.subtotal = newSubtotal;
    booking.total = newTotal;
    booking.totalAmount = newTotal;
    booking.updatedAt = new Date();
    memoryBookings.set(bookingId, booking);

    if (sitterId) {
      const dateFormatted = parsedDate.toISOString().split('T')[0];
      createNotification({
        userId: sitterId,
        title: 'Booking Rescheduled',
        message: `Booking #${booking.bookingId || booking._id || booking.id} has been rescheduled to ${dateFormatted} (${startTime} – ${endTime}).`,
        type: 'booking_rescheduled',
        data: { bookingId: booking._id || booking.id },
      }).catch(() => {});
    }

    return ApiResponse.success(res, booking, 'Booking rescheduled successfully');
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
  calculatePrice,
  cancel,
  reschedule,
  memoryBookings,
};

