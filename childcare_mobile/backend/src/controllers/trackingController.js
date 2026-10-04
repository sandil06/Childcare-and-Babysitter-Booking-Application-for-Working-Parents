const mongoose = require('mongoose');
const TrackingLocation = require('../models/TrackingLocation');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');

const memorySharing = new Map();

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
			const record = await TrackingLocation.findOne({ user: userId }).lean();
			return ApiResponse.success(res, {
				sharingEnabled: record?.sharingEnabled === true,
				latitude: record?.latitude ?? null,
				longitude: record?.longitude ?? null,
				recordedAt: record?.recordedAt ?? null,
			}, 'Live location status retrieved');
		}

		const record = memorySharing.get(userId.toString());
		return ApiResponse.success(res, record || {
			sharingEnabled: false,
			latitude: null,
			longitude: null,
			recordedAt: null,
		}, 'Live location status retrieved');
	} catch (error) {
		next(error);
	}
}

async function updateLiveLocation(req, res, next) {
	try {
		const userId = getUserId(req);
		if (!userId) return next(new ApiError(401, 'Authentication required'));

		const { sharingEnabled, latitude, longitude } = req.body || {};
		if (typeof sharingEnabled !== 'boolean') {
			return next(new ApiError(400, 'sharingEnabled must be a boolean'));
		}

		const hasCoordinates = latitude !== undefined || longitude !== undefined;
		if (hasCoordinates && (typeof latitude !== 'number' || typeof longitude !== 'number')) {
			return next(new ApiError(400, 'latitude and longitude must both be numbers'));
		}

		const update = {
			sharingEnabled,
			...(hasCoordinates ? { latitude, longitude, recordedAt: new Date() } : {}),
		};

		if (isDbConnected() && mongoose.Types.ObjectId.isValid(userId)) {
			const record = await TrackingLocation.findOneAndUpdate(
				{ user: userId },
				{ $set: update, $setOnInsert: { user: userId } },
				{ new: true, upsert: true, runValidators: true }
			).lean();
			return ApiResponse.success(res, {
				sharingEnabled: record.sharingEnabled === true,
				latitude: record.latitude ?? null,
				longitude: record.longitude ?? null,
				recordedAt: record.recordedAt ?? null,
			}, 'Live location status updated');
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

function locations(req, res) {
	return ApiResponse.success(res, []);
}

module.exports = { locations, liveLocationStatus, updateLiveLocation };
