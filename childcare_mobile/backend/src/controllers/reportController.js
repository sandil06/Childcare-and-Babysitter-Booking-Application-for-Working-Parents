const mongoose = require('mongoose');
const Report = require('../models/Report');
const Notification = require('../models/Notification');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');
const { memoryReports } = require('./agencyController');

function isDbConnected() {
  return mongoose.connection.readyState === 1;
}

/**
 * POST /api/v1/reports
 * Submit a complaint or safety report (Parent or Babysitter)
 */
async function create(req, res, next) {
  try {
    const reporterId = req.user?.id || req.user?._id || req.user?.sub;
    const {
      reportedUserId,
      reportedUser: reportedUserParam,
      bookingId,
      booking,
      category = 'Safety',
      description,
      priority = 'medium',
      evidence = [],
    } = req.body;

    const targetUser = reportedUserId || reportedUserParam;
    if (!targetUser) {
      return next(new ApiError(400, 'Reported user ID is required'));
    }

    if (!description || description.trim().length < 10) {
      return next(new ApiError(400, 'Report description must be at least 10 characters long'));
    }

    const validCategories = [
      'Safety',
      'Inappropriate Behaviour',
      'Harassment',
      'Fraud',
      'Payment Issue',
      'Service Quality',
      'Other',
    ];
    const normalizedCategory =
      validCategories.find(
        (c) => c.toLowerCase() === (category || '').toLowerCase()
      ) || 'Safety';

    const validPriorities = ['low', 'medium', 'high', 'urgent'];
    const normalizedPriority = validPriorities.includes((priority || '').toLowerCase())
      ? priority.toLowerCase()
      : 'medium';

    const bId = bookingId || booking || null;

    if (isDbConnected()) {
      const newReport = await Report.create({
        reporter: reporterId,
        reportedUser: targetUser,
        booking: bId,
        category: normalizedCategory,
        description: description.trim(),
        priority: normalizedPriority,
        evidence: Array.isArray(evidence) ? evidence : [],
        status: 'open',
      });

      // Dispatch notification to agency team
      try {
        await Notification.create({
          user: targetUser,
          title: `New Safety Report: ${normalizedCategory}`,
          message: `A safety complaint (${normalizedPriority} priority) has been filed regarding user ${targetUser}.`,
          type: normalizedPriority === 'urgent' ? 'high_priority_complaint' : 'safety_report',
          data: {
            reportId: newReport._id,
            targetAudience: 'agency',
            priority: normalizedPriority,
          },
        });
      } catch (notifErr) {
        // continue
      }

      return ApiResponse.success(res, newReport, 'Report submitted successfully', 201);
    }

    // Memory fallback
    const reportId = `rep-${Date.now()}`;
    const newReport = {
      _id: reportId,
      id: reportId,
      reporter: {
        _id: reporterId,
        id: reporterId,
        name: req.user?.name || 'Reporting User',
        email: req.user?.email || 'user@example.com',
        role: req.user?.role || 'parent',
      },
      reportedUser: {
        _id: targetUser,
        id: targetUser,
        name: 'Reported Subject',
      },
      booking: bId ? { _id: bId, id: bId } : null,
      category: normalizedCategory,
      description: description.trim(),
      priority: normalizedPriority,
      evidence: Array.isArray(evidence) ? evidence : [],
      status: 'open',
      createdAt: new Date(),
    };

    memoryReports.set(reportId, newReport);
    return ApiResponse.success(res, newReport, 'Report submitted successfully', 201);
  } catch (err) {
    next(err);
  }
}

/**
 * GET /api/v1/reports/my
 * Retrieve reports submitted by authenticated user
 */
async function getMyReports(req, res, next) {
  try {
    const userId = req.user?.id || req.user?._id;
    const { status, page = 1, limit = 20 } = req.query;

    if (isDbConnected()) {
      const filter = { reporter: userId };
      if (status && status !== 'all') filter.status = status;

      const skip = (Number(page) - 1) * Number(limit);
      const [reports, total] = await Promise.all([
        Report.find(filter)
          .populate('reportedUser', 'name email avatar role')
          .sort({ createdAt: -1 })
          .skip(skip)
          .limit(Number(limit))
          .lean(),
        Report.countDocuments(filter),
      ]);

      return ApiResponse.paginated(res, reports, { page, limit, total }, 'Reports retrieved');
    }

    let list = Array.from(memoryReports.values()).filter(
      (r) => (r.reporter?._id || r.reporter?.id) === userId
    );
    if (status && status !== 'all') {
      list = list.filter((r) => r.status === status);
    }

    return ApiResponse.paginated(res, list, { page, limit, total: list.length }, 'Reports retrieved (mock)');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  create,
  getMyReports,
};
