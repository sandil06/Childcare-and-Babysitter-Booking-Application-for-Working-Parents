const mongoose = require('mongoose');
const Booking = require('../models/Booking');
const BabysitterProfile = require('../models/BabysitterProfile');
const ApiResponse = require('../utils/ApiResponse');

function isDbConnected() {
  return mongoose.connection.readyState === 1;
}

function getUserId(req) {
  return req.user?.sub || req.user?.id;
}

async function getMeEarnings(req, res, next) {
  try {
    const userId = getUserId(req);
    let completedBookings = [];
    let defaultHourlyRate = 25.0;

    if (isDbConnected()) {
      const profile = await BabysitterProfile.findOne({ user: userId });
      if (profile && profile.hourlyRate) {
        defaultHourlyRate = profile.hourlyRate;
      }

      completedBookings = await Booking.find({
        babysitter: userId,
        status: 'completed',
      })
        .populate('parent', 'name email phone')
        .sort({ date: -1 });
    }

    const earningsItems = completedBookings.map((b) => {
      const duration = Number(b.durationHours) || 4.0;
      const rate = Number(b.hourlyRate) || defaultHourlyRate;
      const gross = duration * rate;
      const serviceFee = Number((gross * 0.05).toFixed(2));
      const netAmount = Number((gross - serviceFee).toFixed(2));

      return {
        id: b._id ? b._id.toString() : b.id,
        bookingId: b.bookingId || `#BK-${b._id ? b._id.toString().slice(-4) : '0000'}`,
        parentName: b.parent?.name || 'Parent',
        date: b.date || new Date(),
        durationHours: duration,
        hourlyRate: rate,
        serviceFee,
        netAmount,
        status: b.paymentStatus || 'paid',
      };
    });

    // Dynamic calculations based strictly on completed bookings in database
    const totalEarnings = earningsItems.reduce((acc, cur) => acc + cur.netAmount, 0);

    const now = new Date();
    const currentMonth = now.getMonth();
    const currentYear = now.getFullYear();

    const monthItems = earningsItems.filter((item) => {
      const itemDate = new Date(item.date);
      return itemDate.getMonth() === currentMonth && itemDate.getFullYear() === currentYear;
    });
    const currentMonthEarnings = monthItems.reduce((acc, cur) => acc + cur.netAmount, 0);

    // Calculate weekly earnings (last 7 days)
    const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const weekItems = earningsItems.filter((item) => new Date(item.date) >= sevenDaysAgo);
    const weeklyEarnings = weekItems.reduce((acc, cur) => acc + cur.netAmount, 0);

    // Calculate average hourly rate
    const totalRate = earningsItems.reduce((acc, cur) => acc + cur.hourlyRate, 0);
    const hourlyRateAverage = earningsItems.length > 0
      ? Number((totalRate / earningsItems.length).toFixed(1))
      : defaultHourlyRate;

    // Pending payout
    const pendingPayout = earningsItems
      .filter((i) => i.status === 'pending')
      .reduce((acc, cur) => acc + cur.netAmount, 0);

    // Weekly day-by-day distribution
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const weeklyDataMap = { Mon: 0, Tue: 0, Wed: 0, Thu: 0, Fri: 0, Sat: 0, Sun: 0 };

    for (const item of weekItems) {
      const d = new Date(item.date);
      const name = dayNames[d.getDay()];
      if (weeklyDataMap[name] !== undefined) {
        weeklyDataMap[name] += item.netAmount;
      }
    }

    const weeklyData = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) => ({
      day,
      amount: Number(weeklyDataMap[day].toFixed(2)),
    }));

    const responseData = {
      totalEarnings: Number(totalEarnings.toFixed(2)),
      currentMonthEarnings: Number(currentMonthEarnings.toFixed(2)),
      weeklyEarnings: Number(weeklyEarnings.toFixed(2)),
      completedBookings: earningsItems.length,
      pendingPayout: Number(pendingPayout.toFixed(2)),
      hourlyRateAverage,
      weeklyData,
      recentEarnings: earningsItems,
    };

    return ApiResponse.success(res, responseData, 'Earnings summary retrieved successfully');
  } catch (err) {
    next(err);
  }
}

async function getMeEarningsHistory(req, res, next) {
  try {
    const userId = getUserId(req);
    const { page = 1, limit = 20 } = req.query;

    if (isDbConnected()) {
      const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);
      const bookings = await Booking.find({ babysitter: userId, status: 'completed' })
        .populate('parent', 'name email phone')
        .sort({ date: -1 })
        .skip(skip)
        .limit(parseInt(limit, 10));

      const items = bookings.map((b) => {
        const duration = Number(b.durationHours) || 4.0;
        const rate = Number(b.hourlyRate) || 25.0;
        const gross = duration * rate;
        const serviceFee = Number((gross * 0.05).toFixed(2));
        const netAmount = Number((gross - serviceFee).toFixed(2));

        return {
          id: b._id.toString(),
          bookingId: b.bookingId,
          parentName: b.parent?.name || 'Parent',
          date: b.date,
          durationHours: duration,
          hourlyRate: rate,
          serviceFee,
          netAmount,
          status: b.paymentStatus || 'paid',
        };
      });

      return ApiResponse.success(res, items, 'Earnings history retrieved');
    }

    return ApiResponse.success(res, [], 'Earnings history retrieved');
  } catch (err) {
    next(err);
  }
}

async function requestPayout(req, res, next) {
  try {
    return ApiResponse.success(
      res,
      {
        payoutId: `po-${Date.now()}`,
        status: 'processing',
        estimatedTransferDate: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000),
      },
      'Payout request created successfully'
    );
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getMeEarnings,
  getMeEarningsHistory,
  requestPayout,
};
