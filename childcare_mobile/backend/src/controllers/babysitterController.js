const ApiResponse = require('../utils/ApiResponse');
const generateToken = require('../utils/generateToken');
const babysitterService = require('../services/babysitterService');
const ROLES = require('../constants/roles');

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

    const stats = {
      totalEarnings: 1850.0,
      rating: profile?.averageRating || 4.9,
      completedBookings: profile?.totalCompletedBookings || 24,
    };

    return ApiResponse.success(
      res,
      {
        profile,
        stats,
        isAvailable: profile?.isAvailable ?? true,
        upcomingBooking: null,
        newRequests: [],
        unreadNotificationsCount: 2,
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
