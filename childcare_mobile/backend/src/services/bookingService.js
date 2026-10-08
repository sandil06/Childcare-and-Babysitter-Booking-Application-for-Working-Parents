const mongoose = require('mongoose');
const Booking = require('../models/Booking');
const BabysitterProfile = require('../models/BabysitterProfile');
const User = require('../models/User');
const ApiError = require('../utils/ApiError');

function isDbConnected() {
  return mongoose.connection.readyState === 1;
}

function timeToMinutes(timeStr) {
  if (!timeStr) return 0;
  // Handle "HH:MM" or "HH:MM AM/PM"
  const clean = timeStr.trim();
  const match = clean.match(/^(\d{1,2}):(\d{2})(?:\s*([AP]M))?$/i);
  if (!match) {
    const parts = clean.split(':').map(Number);
    return (parts[0] || 0) * 60 + (parts[1] || 0);
  }
  let hour = Number.parseInt(match[1], 10);
  const min = Number.parseInt(match[2], 10);
  const period = match[3] ? match[3].toUpperCase() : null;
  if (period === 'PM' && hour < 12) hour += 12;
  if (period === 'AM' && hour === 12) hour = 0;
  return hour * 60 + min;
}

function calculateDurationHours(startTime, endTime) {
  const startM = timeToMinutes(startTime);
  const endM = timeToMinutes(endTime);
  if (endM <= startM) {
    throw new ApiError(400, 'End time must be after start time');
  }
  const diffM = endM - startM;
  return Math.max(0.5, Math.round((diffM / 60) * 10) / 10);
}

async function getBabysitterHourlyRate(babysitterId) {
  if (!babysitterId) return 1500.0;
  if (isDbConnected()) {
    try {
      // Could be BabysitterProfile ID or User ID
      let profile = null;
      if (mongoose.Types.ObjectId.isValid(babysitterId)) {
        profile = await BabysitterProfile.findOne({
          $or: [{ _id: babysitterId }, { user: babysitterId }],
        });
      }
      if (profile && profile.hourlyRate > 0) {
        return profile.hourlyRate;
      }
    } catch (_) {}
  }
  return 1500.0;
}

async function calculatePrice({ babysitterId, date, startTime, endTime }) {
  if (!startTime || !endTime) {
    throw new ApiError(400, 'startTime and endTime are required for price calculation');
  }
  const duration = calculateDurationHours(startTime, endTime);
  const hourlyRate = await getBabysitterHourlyRate(babysitterId);
  const subtotal = Math.round(duration * hourlyRate);
  const serviceFee = 0;
  const totalAmount = subtotal + serviceFee;

  return {
    duration,
    hourlyRate,
    subtotal,
    serviceFee,
    totalAmount,
  };
}

async function checkAvailabilityAndConflicts({ babysitterId, date, startTime, endTime, excludeBookingId = null, memoryStore = null }) {
  const startM = timeToMinutes(startTime);
  const endM = timeToMinutes(endTime);

  if (isDbConnected()) {
    const targetDate = new Date(date);
    const startOfDay = new Date(Date.UTC(targetDate.getUTCFullYear(), targetDate.getUTCMonth(), targetDate.getUTCDate(), 0, 0, 0, 0));
    const endOfDay = new Date(Date.UTC(targetDate.getUTCFullYear(), targetDate.getUTCMonth(), targetDate.getUTCDate(), 23, 59, 59, 999));
    const localStart = new Date(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate(), 0, 0, 0, 0);
    const localEnd = new Date(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate(), 23, 59, 59, 999);
    const minStart = startOfDay < localStart ? startOfDay : localStart;
    const maxEnd = endOfDay > localEnd ? endOfDay : localEnd;

    let sitterUserIds = [babysitterId];
    if (mongoose.Types.ObjectId.isValid(babysitterId)) {
      const profile = await BabysitterProfile.findOne({
        $or: [{ _id: babysitterId }, { user: babysitterId }],
      });
      if (profile) {
        if (profile.user) sitterUserIds.push(profile.user);
        if (profile._id) sitterUserIds.push(profile._id);
      }
    }

    const query = {
      babysitter: { $in: sitterUserIds },
      date: { $gte: minStart, $lte: maxEnd },
      status: { $in: ['pending', 'accepted', 'confirmed', 'travelling', 'arrived', 'in_progress'] },
    };

    if (excludeBookingId && mongoose.Types.ObjectId.isValid(excludeBookingId)) {
      query._id = { $ne: excludeBookingId };
    }

    const existingBookings = await Booking.find(query);
    for (const b of existingBookings) {
      const existingStartM = timeToMinutes(b.startTime);
      const existingEndM = timeToMinutes(b.endTime);

      // Overlap condition: start < existingEnd && end > existingStart
      if (startM < existingEndM && endM > existingStartM) {
        return {
          available: false,
          conflictBookingId: b.bookingId || b._id.toString(),
          reason: `Babysitter has an existing booking (${b.startTime} - ${b.endTime}) that overlaps with requested time.`,
        };
      }
    }
  } else if (memoryStore) {
    const targetDateStr = new Date(date).toISOString().split('T')[0];
    for (const b of memoryStore.values()) {
      if (excludeBookingId && (b._id === excludeBookingId || b.id === excludeBookingId)) continue;
      const bSitterId = (b.babysitter?._id || b.babysitter || '').toString();
      if (bSitterId === babysitterId.toString()) {
        const bDateStr = new Date(b.date).toISOString().split('T')[0];
        if (bDateStr === targetDateStr && ['pending', 'accepted', 'confirmed', 'travelling', 'arrived', 'in_progress'].includes(b.status)) {
          const existingStartM = timeToMinutes(b.startTime);
          const existingEndM = timeToMinutes(b.endTime);
          if (startM < existingEndM && endM > existingStartM) {
            return {
              available: false,
              conflictBookingId: b.bookingId || b.id || b._id,
              reason: `Babysitter has an existing booking (${b.startTime} - ${b.endTime}) that overlaps with requested time.`,
            };
          }
        }
      }
    }
  }

  return { available: true };
}


module.exports = {
  calculateDurationHours,
  calculatePrice,
  checkAvailabilityAndConflicts,
  getBabysitterHourlyRate,
  timeToMinutes,
};
