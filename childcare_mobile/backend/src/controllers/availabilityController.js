const mongoose = require('mongoose');
const Availability = require('../models/Availability');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');
const { parseMinutes } = require('../validators/availabilityValidator');

// Memory store fallback when MongoDB is not connected
const memorySlots = new Map();

function isDbConnected() {
  return mongoose.connection.readyState === 1;
}

function getUserId(req) {
  return req.user?.sub || req.user?.id;
}

function parseDateUtc(dateInput) {
  if (!dateInput) return new Date();
  if (dateInput instanceof Date) {
    return new Date(Date.UTC(dateInput.getUTCFullYear(), dateInput.getUTCMonth(), dateInput.getUTCDate(), 0, 0, 0, 0));
  }
  const clean = dateInput.toString().split('T')[0];
  const parts = clean.split('-').map(Number);
  if (parts.length === 3 && !isNaN(parts[0]) && !isNaN(parts[1]) && !isNaN(parts[2])) {
    return new Date(Date.UTC(parts[0], parts[1] - 1, parts[2], 0, 0, 0, 0));
  }
  const d = new Date(dateInput);
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), 0, 0, 0, 0));
}

function checkOverlap(existingSlots, newStart, newEnd, excludeId = null) {
  const newStartMin = parseMinutes(newStart);
  const newEndMin = parseMinutes(newEnd);

  return existingSlots.some((slot) => {
    if (excludeId && (slot._id?.toString() === excludeId || slot.id?.toString() === excludeId)) {
      return false;
    }
    // A full-day unavailable marker (00:00 - 23:59, available: false) should not block adding working hours
    if (slot.available === false && slot.startTime === '00:00' && slot.endTime === '23:59') {
      return false;
    }
    const slotStartMin = parseMinutes(slot.startTime);
    const slotEndMin = parseMinutes(slot.endTime);
    // Two intervals [A, B] and [C, D] overlap if max(A, C) < min(B, D)
    return Math.max(newStartMin, slotStartMin) < Math.min(newEndMin, slotEndMin);
  });
}

async function getMeAvailability(req, res, next) {
  try {
    const userId = getUserId(req);

    if (isDbConnected()) {
      const query = { babysitter: userId };
      if (req.query.date) {
        const dateStart = parseDateUtc(req.query.date);
        const nextDay = new Date(dateStart.getTime() + 24 * 60 * 60 * 1000);
        query.date = { $gte: dateStart, $lt: nextDay };
      }
      const slots = await Availability.find(query).sort({ date: 1, startTime: 1 });
      return ApiResponse.success(res, slots, 'Availability retrieved');
    }

    // Memory fallback
    const userSlots = Array.from(memorySlots.values()).filter(
      (s) => s.babysitter.toString() === userId.toString()
    );
    if (req.query.date) {
      const targetStr = parseDateUtc(req.query.date).toISOString().split('T')[0];
      const filtered = userSlots.filter(
        (s) => parseDateUtc(s.date).toISOString().split('T')[0] === targetStr
      );
      return ApiResponse.success(res, filtered, 'Availability retrieved');
    }
    return ApiResponse.success(res, userSlots, 'Availability retrieved');
  } catch (err) {
    next(err);
  }
}

async function createMeAvailability(req, res, next) {
  try {
    const userId = getUserId(req);
    const { date, startTime, endTime, available = true, isRecurring = false, repeatDays = [] } = req.body;

    const dateStart = parseDateUtc(date);
    const nextDay = new Date(dateStart.getTime() + 24 * 60 * 60 * 1000);

    if (isDbConnected()) {
      // If adding an available working slot, clear any full-day unavailable blocker for that date
      if (available) {
        await Availability.deleteMany({
          babysitter: userId,
          date: { $gte: dateStart, $lt: nextDay },
          startTime: '00:00',
          endTime: '23:59',
          available: false,
        });
      }

      const existingForDay = await Availability.find({
        babysitter: userId,
        date: { $gte: dateStart, $lt: nextDay },
      });

      if (checkOverlap(existingForDay, startTime, endTime)) {
        return next(new ApiError(400, 'Overlapping availability slot exists for this date'));
      }

      const slot = await Availability.create({
        babysitter: userId,
        date: dateStart,
        startTime,
        endTime,
        available,
        isRecurring,
        repeatDays,
      });

      return ApiResponse.success(res, slot, 'Availability slot created', 201);
    }

    // Memory fallback
    if (available) {
      for (const [key, val] of memorySlots.entries()) {
        if (
          val.babysitter.toString() === userId.toString() &&
          parseDateUtc(val.date).toISOString().split('T')[0] === dateStart.toISOString().split('T')[0] &&
          val.startTime === '00:00' &&
          val.endTime === '23:59' &&
          !val.available
        ) {
          memorySlots.delete(key);
        }
      }
    }

    const existingMemory = Array.from(memorySlots.values()).filter(
      (s) =>
        s.babysitter.toString() === userId.toString() &&
        parseDateUtc(s.date).toISOString().split('T')[0] === dateStart.toISOString().split('T')[0]
    );

    if (checkOverlap(existingMemory, startTime, endTime)) {
      return next(new ApiError(400, 'Overlapping availability slot exists for this date'));
    }

    const slotId = `av-${Date.now()}`;
    const newSlot = {
      _id: slotId,
      id: slotId,
      babysitter: userId,
      date: dateStart,
      startTime,
      endTime,
      available,
      isRecurring,
      repeatDays,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    memorySlots.set(slotId, newSlot);
    return ApiResponse.success(res, newSlot, 'Availability slot created', 201);
  } catch (err) {
    next(err);
  }
}

async function update(req, res, next) {
  try {
    const userId = getUserId(req);
    const slotId = req.params.id;

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(slotId)) {
      const slot = await Availability.findById(slotId);
      if (!slot) return next(new ApiError(404, 'Availability slot not found'));

      if (slot.babysitter.toString() !== userId.toString()) {
        return next(new ApiError(403, 'You are not authorized to modify this availability slot'));
      }

      const newStart = req.body.startTime || slot.startTime;
      const newEnd = req.body.endTime || slot.endTime;

      if (parseMinutes(newEnd) <= parseMinutes(newStart)) {
        return next(new ApiError(400, 'End time must be after start time'));
      }

      const dateStart = parseDateUtc(slot.date);
      const nextDay = new Date(dateStart.getTime() + 24 * 60 * 60 * 1000);

      const existingForDay = await Availability.find({
        babysitter: userId,
        date: { $gte: dateStart, $lt: nextDay },
      });

      if (checkOverlap(existingForDay, newStart, newEnd, slotId)) {
        return next(new ApiError(400, 'Overlapping availability slot exists for this date'));
      }

      Object.assign(slot, req.body);
      if (req.body.date) {
        slot.date = parseDateUtc(req.body.date);
      }
      await slot.save();

      return ApiResponse.success(res, slot, 'Availability slot updated');
    }

    // Memory fallback
    const slot = memorySlots.get(slotId);
    if (!slot) return next(new ApiError(404, 'Availability slot not found'));
    if (slot.babysitter.toString() !== userId.toString()) {
      return next(new ApiError(403, 'You are not authorized to modify this availability slot'));
    }

    const newStart = req.body.startTime || slot.startTime;
    const newEnd = req.body.endTime || slot.endTime;
    if (parseMinutes(newEnd) <= parseMinutes(newStart)) {
      return next(new ApiError(400, 'End time must be after start time'));
    }

    const slotDateStr = parseDateUtc(slot.date).toISOString().split('T')[0];
    const existingMemory = Array.from(memorySlots.values()).filter(
      (candidate) =>
        candidate.babysitter.toString() === userId.toString() &&
        parseDateUtc(candidate.date).toISOString().split('T')[0] === slotDateStr
    );
    if (checkOverlap(existingMemory, newStart, newEnd, slotId)) {
      return next(new ApiError(400, 'Overlapping availability slot exists for this date'));
    }

    const updated = { ...slot, ...req.body, updatedAt: new Date() };
    memorySlots.set(slotId, updated);
    return ApiResponse.success(res, updated, 'Availability slot updated');
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  try {
    const userId = getUserId(req);
    const slotId = req.params.id;

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(slotId)) {
      const slot = await Availability.findById(slotId);
      if (!slot) return next(new ApiError(404, 'Availability slot not found'));
      if (slot.babysitter.toString() !== userId.toString()) {
        return next(new ApiError(403, 'You are not authorized to delete this availability slot'));
      }
      await slot.deleteOne();
      return ApiResponse.success(res, null, 'Availability slot removed');
    }

    // Memory fallback
    const slot = memorySlots.get(slotId);
    if (!slot) return next(new ApiError(404, 'Availability slot not found'));
    if (slot.babysitter.toString() !== userId.toString()) {
      return next(new ApiError(403, 'You are not authorized to delete this availability slot'));
    }
    memorySlots.delete(slotId);
    return ApiResponse.success(res, null, 'Availability slot removed');
  } catch (err) {
    next(err);
  }
}

async function list(req, res, next) {
  try {
    const filter = {};
    if (req.query.babysitter) filter.babysitter = req.query.babysitter;

    if (isDbConnected()) {
      const slots = await Availability.find(filter).sort({ date: 1, startTime: 1 });
      return ApiResponse.success(res, slots, 'Availabilities retrieved');
    }

    return ApiResponse.success(res, Array.from(memorySlots.values()), 'Availabilities retrieved');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getMeAvailability,
  createMeAvailability,
  update,
  remove,
  list,
};
