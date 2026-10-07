const mongoose = require('mongoose');
const TrackingLocation = require('../models/TrackingLocation');
const Booking = require('../models/Booking');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');
const { memoryBookings } = require('./bookingController');

const memorySharing = new Map();
const memoryBookingLocations = new Map();

function getUserId(req) {
  return req.user?.sub || req.user?.id;
}

function isDbConnected() {
  return mongoose.connection.readyState === 1;
}

async function liveLocationStatus(req, res, next) {
  try {
    const userId = getUserId(req);
    if (!userId) return next(new ApiError(401, 'Authentication required'));

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(userId)) {
      const record = await TrackingLocation.findOne({ user: userId }).sort({ recordedAt: -1 }).lean();
      return ApiResponse.success(
        res,
        {
          sharingEnabled: record?.sharingEnabled !== false,
          latitude: record?.latitude ?? null,
          longitude: record?.longitude ?? null,
          recordedAt: record?.recordedAt ?? null,
        },
        'Live location status retrieved'
      );
    }

    const record = memorySharing.get(userId.toString());
    return ApiResponse.success(
      res,
      record || {
        sharingEnabled: true,
        latitude: null,
        longitude: null,
        recordedAt: null,
      },
      'Live location status retrieved'
    );
  } catch (error) {
    next(error);
  }
}

async function updateLiveLocation(req, res, next) {
  try {
    const userId = getUserId(req);
    if (!userId) return next(new ApiError(401, 'Authentication required'));

    const { sharingEnabled, latitude, longitude } = req.body || {};
    if (sharingEnabled !== undefined && typeof sharingEnabled !== 'boolean') {
      return next(new ApiError(400, 'sharingEnabled must be a boolean'));
    }

    const hasCoordinates = latitude !== undefined && longitude !== undefined;
    if (hasCoordinates && (typeof latitude !== 'number' || typeof longitude !== 'number')) {
      return next(new ApiError(400, 'latitude and longitude must both be numbers'));
    }

    const update = {
      sharingEnabled: sharingEnabled !== undefined ? sharingEnabled : true,
      ...(hasCoordinates ? { latitude, longitude, recordedAt: new Date() } : {}),
    };

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(userId)) {
      const record = await TrackingLocation.findOneAndUpdate(
        { user: userId },
        { $set: update, $setOnInsert: { user: userId } },
        { new: true, upsert: true, runValidators: true }
      ).lean();
      return ApiResponse.success(
        res,
        {
          sharingEnabled: record.sharingEnabled === true,
          latitude: record.latitude ?? null,
          longitude: record.longitude ?? null,
          recordedAt: record.recordedAt ?? null,
        },
        'Live location status updated'
      );
    }

    const previous = memorySharing.get(userId.toString()) || {};
    const record = {
      ...previous,
      ...update,
      latitude: update.latitude ?? previous.latitude ?? null,
      longitude: update.longitude ?? previous.longitude ?? null,
      recordedAt: update.recordedAt ?? previous.recordedAt ?? null,
    };
    memorySharing.set(userId.toString(), record);
    return ApiResponse.success(res, record, 'Live location status updated');
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/v1/tracking/booking/:bookingId/location
 * Updates caregiver's live GPS coordinates for a specific booking
 */
async function updateBookingLocation(req, res, next) {
  try {
    const userId = getUserId(req);
    const { bookingId } = req.params;
    const { latitude, longitude, heading = 0, speed = 0, status = 'travelling' } = req.body;

    if (latitude === undefined || longitude === undefined) {
      throw new ApiError(400, 'latitude and longitude are required');
    }

    const numLat = Number(latitude);
    const numLng = Number(longitude);

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(bookingId)) {
      const loc = await TrackingLocation.create({
        booking: bookingId,
        user: userId,
        latitude: numLat,
        longitude: numLng,
        heading: Number(heading),
        speed: Number(speed),
        status,
        recordedAt: new Date(),
      });

      return ApiResponse.success(res, loc, 'Caregiver location recorded', 201);
    }

    // Memory fallback
    const loc = {
      _id: `loc-${Date.now()}`,
      bookingId,
      userId,
      latitude: numLat,
      longitude: numLng,
      heading: Number(heading),
      speed: Number(speed),
      status,
      recordedAt: new Date(),
    };

    memoryBookingLocations.set(bookingId, loc);
    return ApiResponse.success(res, loc, 'Caregiver location recorded', 201);
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/v1/tracking/booking/:bookingId/location
 * Retrieves latest caregiver coordinates and ETA for booking
 */
async function getBookingLocation(req, res, next) {
  try {
    const { bookingId } = req.params;

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(bookingId)) {
      const latest = await TrackingLocation.findOne({ booking: bookingId })
        .sort({ recordedAt: -1 })
        .populate('user', 'name avatar phone');

      if (latest) {
        return ApiResponse.success(res, latest, 'Latest location retrieved');
      }
    }

    // Memory fallback
    const mem = memoryBookingLocations.get(bookingId);
    if (mem) {
      return ApiResponse.success(res, mem, 'Latest location retrieved');
    }

    // Default simulation fallback coordinates (Colombo, Sri Lanka)
    return ApiResponse.success(
      res,
      {
        bookingId,
        latitude: 6.8925,
        longitude: 79.8580,
        destinationLatitude: 6.9044,
        destinationLongitude: 79.8639,
        heading: 45,
        speed: 28.5,
        status: 'travelling',
        etaMinutes: 12,
        recordedAt: new Date(),
      },
      'Simulation coordinates retrieved'
    );
  } catch (error) {
    next(error);
  }
}

function locations(req, res) {
  return ApiResponse.success(res, []);
}

module.exports = {
  locations,
  liveLocationStatus,
  updateLiveLocation,
  updateBookingLocation,
  getBookingLocation,
  memoryBookingLocations,
};
