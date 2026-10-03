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

function checkOverlap(existingSlots, newStart, newEnd, excludeId = null) {
  const newStartMin = parseMinutes(newStart);
  const newEndMin = parseMinutes(newEnd);

  return existingSlots.some((slot) => {
    if (excludeId && (slot._id?.toString() === excludeId || slot.id?.toString() === excludeId)) {
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
        const d = new Date(req.query.date);
        const nextDay = new Date(d);
        nextDay.setDate(nextDay.getDate() + 1);
        query.date = { $gte: d, $lt: nextDay };
      }
      const slots = await Availability.find(query).sort({ date: 1, startTime: 1 });
      return ApiResponse.success(res, slots, 'Availability retrieved');
    }

    // Memory fallback
    const userSlots = Array.from(memorySlots.values()).filter(
      (s) => s.babysitter.toString() === userId.toString()
    );
    return ApiResponse.success(res, userSlots, 'Availability retrieved');
  } catch (err) {
    next(err);
  }
}

async function createMeAvailability(req, res, next) {
  try {
    const userId = getUserId(req);
    const { date, startTime, endTime, available = true, isRecurring = false, repeatDays = [] } = req.body;

    const parsedDate = new Date(date);
    const dateStart = new Date(parsedDate.getFullYear(), parsedDate.getMonth(), parsedDate.getDate());

    if (isDbConnected()) {
      const nextDay = new Date(dateStart);
      nextDay.setDate(nextDay.getDate() + 1);

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
    const existingMemory = Array.from(memorySlots.values()).filter(
      (s) =>
        s.babysitter.toString() === userId.toString() &&
        new Date(s.date).toDateString() === dateStart.toDateString()
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

    if (isDbConnected()) {
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

      const nextDay = new Date(slot.date);
      nextDay.setDate(nextDay.getDate() + 1);

      const existingForDay = await Availability.find({
        babysitter: userId,
        date: { $gte: slot.date, $lt: nextDay },
      });

      if (checkOverlap(existingForDay, newStart, newEnd, slotId)) {
        return next(new ApiError(400, 'Overlapping availability slot exists for this date'));
      }

      Object.assign(slot, req.body);
      await slot.save();

      return ApiResponse.success(res, slot, 'Availability slot updated');
    }

    // Memory fallback
    const slot = memorySlots.get(slotId);
    if (!slot) return next(new ApiError(404, 'Availability slot not found'));
    if (slot.babysitter.toString() !== userId.toString()) {
      return next(new ApiError(403, 'You are not authorized to modify this availability slot'));
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

    if (isDbConnected()) {
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
