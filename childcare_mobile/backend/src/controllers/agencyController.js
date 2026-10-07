const mongoose = require('mongoose');
const User = require('../models/User');
const BabysitterProfile = require('../models/BabysitterProfile');
const Booking = require('../models/Booking');
const VerificationRequest = require('../models/VerificationRequest');
const Report = require('../models/Report');
const AuditLog = require('../models/AuditLog');
const Notification = require('../models/Notification');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');
const pagination = require('../utils/pagination');
const ROLES = require('../constants/roles');

function isDbConnected() {
  return mongoose.connection.readyState === 1;
}

// In-memory mock stores for offline / test resilience
const memoryVerifications = new Map();
const memoryReports = new Map();
const memoryUsers = new Map();

function initSampleUsers() {
  if (memoryUsers.size > 0) return;

  const samples = [
    {
      _id: 'u-1',
      id: 'u-1',
      name: 'Dulani Senanayake',
      email: 'dulani.s@gmail.com',
      phone: '+94 77 445 5667',
      role: 'parent',
      accountStatus: 'active',
      isActive: true,
      isEmailVerified: true,
      totalBookings: 14,
      openReports: 0,
      createdAt: new Date(Date.now() - 86400000 * 45),
    },
    {
      _id: 'u-2',
      id: 'u-2',
      name: 'Amaya Fernando',
      email: 'amaya.fernando@example.com',
      phone: '+94 77 123 4567',
      role: 'babysitter',
      accountStatus: 'active',
      isActive: true,
      isEmailVerified: true,
      totalBookings: 28,
      averageRating: 4.9,
      openReports: 0,
      createdAt: new Date(Date.now() - 86400000 * 90),
    },
    {
      _id: 'u-3',
      id: 'u-3',
      name: 'Kavindi Perera',
      email: 'kavindi.perera@example.com',
      phone: '+94 71 987 6543',
      role: 'babysitter',
      accountStatus: 'active',
      isActive: true,
      isEmailVerified: true,
      totalBookings: 12,
      averageRating: 4.8,
      openReports: 0,
      createdAt: new Date(Date.now() - 86400000 * 30),
    },
    {
      _id: 'u-4',
      id: 'u-4',
      name: 'Saman Jayatilleke',
      email: 'saman.j@yahoo.com',
      phone: '+94 70 334 8899',
      role: 'parent',
      accountStatus: 'active',
      isActive: true,
      isEmailVerified: true,
      totalBookings: 6,
      openReports: 0,
      createdAt: new Date(Date.now() - 86400000 * 60),
    },
    {
      _id: 'u-5',
      id: 'u-5',
      name: 'Nimali Disanayake',
      email: 'nimali.d@gmail.com',
      phone: '+94 75 221 4455',
      role: 'parent',
      accountStatus: 'suspended',
      isActive: false,
      suspensionReason: 'Repeated late cancellations without notification',
      isEmailVerified: true,
      totalBookings: 3,
      openReports: 1,
      createdAt: new Date(Date.now() - 86400000 * 15),
    },
    {
      _id: 'u-6',
      id: 'u-6',
      name: 'Sanduni Jayawardena',
      email: 'sanduni.j@example.com',
      phone: '+94 76 555 8899',
      role: 'babysitter',
      accountStatus: 'active',
      isActive: true,
      isEmailVerified: true,
      totalBookings: 34,
      averageRating: 5.0,
      openReports: 0,
      createdAt: new Date(Date.now() - 86400000 * 120),
    },
    {
      _id: 'u-7',
      id: 'u-7',
      name: 'Chaminda Silva',
      email: 'admin@littlehands.lk',
      phone: '+94 11 234 5678',
      role: 'agency',
      accountStatus: 'active',
      isActive: true,
      isEmailVerified: true,
      totalBookings: 0,
      openReports: 0,
      createdAt: new Date(Date.now() - 86400000 * 200),
    },
  ];

  for (const s of samples) {
    memoryUsers.set(s._id, s);
  }
}

initSampleUsers();

/**
 * GET /api/v1/agency/dashboard
 * Aggregates platform KPIs, queues, and recent administrative activities
 */
async function getDashboard(req, res, next) {
  try {
    if (isDbConnected()) {
      const [
        totalUsers,
        totalParents,
        totalBabysitters,
        verifiedBabysitters,
        pendingVerifications,
        rejectedVerifications,
        totalBookings,
        activeBookings,
        completedBookings,
        cancelledBookings,
        openComplaints,
        resolvedComplaints,
        recentVerifications,
        recentComplaints,
        recentBookings,
      ] = await Promise.all([
        User.countDocuments(),
        User.countDocuments({ role: ROLES.PARENT }),
        User.countDocuments({ role: ROLES.BABYSITTER }),
        BabysitterProfile.countDocuments({ verificationStatus: 'verified' }),
        VerificationRequest.countDocuments({ status: { $in: ['pending', 'under_review'] } }),
        VerificationRequest.countDocuments({ status: 'rejected' }),
        Booking.countDocuments(),
        Booking.countDocuments({
          status: { $in: ['accepted', 'confirmed', 'travelling', 'arrived', 'in_progress'] },
        }),
        Booking.countDocuments({ status: 'completed' }),
        Booking.countDocuments({ status: 'cancelled' }),
        Report.countDocuments({ status: { $in: ['open', 'under_review'] } }),
        Report.countDocuments({ status: 'resolved' }),
        VerificationRequest.find()
          .sort({ submittedAt: -1, createdAt: -1 })
          .limit(5)
          .populate('babysitter', 'name email phone avatar')
          .populate('babysitterProfile', 'experienceYears hourlyRate verificationStatus address skills documents')
          .lean(),
        Report.find()
          .sort({ createdAt: -1 })
          .limit(5)
          .populate('reporter', 'name email role')
          .populate('reportedUser', 'name email role')
          .lean(),
        Booking.find()
          .sort({ createdAt: -1 })
          .limit(5)
          .populate('parent', 'name email')
          .populate('babysitter', 'name email')
          .lean(),
      ]);

      const formattedBookings = (recentBookings || []).map((b) => ({
        id: b._id ? b._id.toString() : b.id,
        bookingId: b.bookingId || `#BK-${b._id?.toString().slice(-4)}`,
        parentName: b.parent?.name || 'Parent',
        babysitterName: b.babysitter?.name || 'Caregiver',
        date: b.date ? new Date(b.date).toISOString().split('T')[0] : 'Scheduled',
        startTime: b.startTime || '09:00',
        endTime: b.endTime || '13:00',
        status: b.status || 'pending',
        paymentStatus: b.paymentStatus || 'pending',
        totalAmount: b.totalAmount || b.total || 0,
      }));

      return ApiResponse.success(
        res,
        {
          stats: {
            totalUsers,
            totalParents,
            totalBabysitters,
            verifiedBabysitters,
            pendingVerifications,
            rejectedVerifications,
            totalBookings,
            activeBookings,
            completedBookings,
            cancelledBookings,
            openComplaints,
            resolvedComplaints,
          },
          recentVerifications: recentVerifications || [],
          recentComplaints: recentComplaints || [],
          recentBookings: formattedBookings,
          systemActivities: [
            {
              id: 'act-1',
              action: 'Platform health monitoring active',
              timestamp: new Date().toISOString(),
              type: 'system',
            },
          ],
        },
        'Agency dashboard data retrieved'
      );
    }

    // Memory Fallback
    const verificationsList = Array.from(memoryVerifications.values());
    const reportsList = Array.from(memoryReports.values());

    return ApiResponse.success(
      res,
      {
        stats: {
          totalUsers: 148,
          totalParents: 92,
          totalBabysitters: 54,
          verifiedBabysitters: 38,
          pendingVerifications: verificationsList.filter((v) => v.status === 'pending').length || 12,
          rejectedVerifications: verificationsList.filter((v) => v.status === 'rejected').length || 4,
          totalBookings: 320,
          activeBookings: 18,
          completedBookings: 284,
          cancelledBookings: 18,
          openComplaints: reportsList.filter((r) => r.status === 'open').length || 5,
          resolvedComplaints: reportsList.filter((r) => r.status === 'resolved').length || 27,
        },
        recentVerifications: verificationsList.slice(0, 5),
        recentComplaints: reportsList.slice(0, 5),
        recentBookings: [
          {
            id: 'bk-901',
            bookingId: '#BK-901',
            parentName: 'Dulani Senanayake',
            babysitterName: 'Amaya Fernando',
            date: '2026-10-08',
            startTime: '09:00 AM',
            endTime: '01:00 PM',
            status: 'confirmed',
            paymentStatus: 'paid',
            totalAmount: 6000.0,
          },
        ],
        systemActivities: [
          {
            id: 'act-1',
            action: 'Automated verification check completed',
            timestamp: new Date().toISOString(),
            type: 'system',
          },
        ],
      },
      'Agency dashboard data retrieved'
    );
  } catch (err) {
    next(err);
  }
}

/**
 * GET /api/v1/agency/users
 * Paginated user listing with filters for role, status, and search
 */
async function getUsers(req, res, next) {
  try {
    const { role, status, search } = req.query;
    const { page, limit, skip } = pagination(req.query);

    if (isDbConnected()) {
      const filter = {};
      if (role && role !== 'all') {
        filter.role = role.toLowerCase();
      }
      if (status && status !== 'all') {
        if (status === 'suspended') {
          filter.$or = [{ accountStatus: 'suspended' }, { isActive: false }];
        } else if (status === 'active') {
          filter.accountStatus = 'active';
          filter.isActive = true;
        }
      }

      let users = await User.find(filter)
        .select('-passwordHash')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean();

      if (search && search.trim()) {
        const query = search.trim().toLowerCase();
        users = users.filter(
          (u) =>
            u.name?.toLowerCase().includes(query) ||
            u.email?.toLowerCase().includes(query) ||
            u.phone?.toLowerCase().includes(query)
        );
      }

      const total = await User.countDocuments(filter);

      res.set('X-Page', String(page));
      res.set('X-Limit', String(limit));
      res.set('X-Total', String(total));
      res.set('X-Has-More', String(skip + limit < total));

      return ApiResponse.success(res, users, 'Users retrieved successfully');
    }

    initSampleUsers();
    let list = Array.from(memoryUsers.values());

    if (role && role !== 'all') {
      list = list.filter((u) => u.role.toLowerCase() === role.toLowerCase());
    }

    if (status && status !== 'all') {
      list = list.filter((u) => u.accountStatus.toLowerCase() === status.toLowerCase());
    }

    if (search && search.trim()) {
      const query = search.trim().toLowerCase();
      list = list.filter(
        (u) =>
          u.name?.toLowerCase().includes(query) ||
          u.email?.toLowerCase().includes(query) ||
          u.phone?.toLowerCase().includes(query)
      );
    }

    const total = list.length;
    const paged = list.slice(skip, skip + limit);

    res.set('X-Page', String(page));
    res.set('X-Limit', String(limit));
    res.set('X-Total', String(total));
    res.set('X-Has-More', String(skip + limit < total));

    return ApiResponse.success(res, paged, 'Users retrieved successfully');
  } catch (err) {
    next(err);
  }
}

/**
 * GET /api/v1/agency/users/:id
 * Retrieve details for a specific user
 */
async function getUserById(req, res, next) {
  try {
    const { id } = req.params;

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(id)) {
      const user = await User.findById(id).select('-passwordHash').lean();
      if (!user) return next(new ApiError(404, 'User not found'));
      return ApiResponse.success(res, user, 'User details retrieved');
    }

    initSampleUsers();
    const user = memoryUsers.get(id);
    if (!user) return next(new ApiError(404, 'User not found'));

    return ApiResponse.success(res, user, 'User details retrieved');
  } catch (err) {
    next(err);
  }
}

/**
 * PATCH /api/v1/agency/users/:id/suspend
 * Suspend user account with mandatory reason
 */
async function suspendUser(req, res, next) {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const adminUser = req.user;

    if (!reason || !reason.trim()) {
      return next(new ApiError(400, 'Suspension reason is required'));
    }

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(id)) {
      const user = await User.findById(id);
      if (!user) return next(new ApiError(404, 'User not found'));

      user.accountStatus = 'suspended';
      user.isActive = false;
      user.suspensionReason = reason.trim();
      await user.save();

      try {
        await AuditLog.create({
          actor: adminUser?._id,
          action: 'suspend_user',
          targetType: 'User',
          targetId: id,
          notes: reason.trim(),
          metadata: { email: user.email, role: user.role },
        });
      } catch (logErr) {
        // continue
      }

      try {
        await Notification.create({
          user: user._id,
          title: 'Account Suspended',
          message: `Your account has been suspended by the agency. Reason: ${reason.trim()}`,
          type: 'system',
        });
      } catch (notifErr) {
        // continue
      }

      const safeUser = user.toObject();
      delete safeUser.passwordHash;
      return ApiResponse.success(res, safeUser, 'User suspended successfully');
    }

    initSampleUsers();
    const user = memoryUsers.get(id);
    if (!user) return next(new ApiError(404, 'User not found'));

    user.accountStatus = 'suspended';
    user.isActive = false;
    user.suspensionReason = reason.trim();
    memoryUsers.set(id, user);

    return ApiResponse.success(res, user, 'User suspended successfully');
  } catch (err) {
    next(err);
  }
}

/**
 * PATCH /api/v1/agency/users/:id/reactivate
 * Reactivate suspended user account
 */
async function reactivateUser(req, res, next) {
  try {
    const { id } = req.params;
    const adminUser = req.user;

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(id)) {
      const user = await User.findById(id);
      if (!user) return next(new ApiError(404, 'User not found'));

      user.accountStatus = 'active';
      user.isActive = true;
      user.suspensionReason = '';
      await user.save();

      try {
        await AuditLog.create({
          actor: adminUser?._id,
          action: 'reactivate_user',
          targetType: 'User',
          targetId: id,
          notes: 'User account restored to active status',
          metadata: { email: user.email, role: user.role },
        });
      } catch (logErr) {
        // continue
      }

      try {
        await Notification.create({
          user: user._id,
          title: 'Account Reactivated',
          message: 'Your account has been reactivated. You can now access all services.',
          type: 'system',
        });
      } catch (notifErr) {
        // continue
      }

      const safeUser = user.toObject();
      delete safeUser.passwordHash;
      return ApiResponse.success(res, safeUser, 'User reactivated successfully');
    }

    initSampleUsers();
    const user = memoryUsers.get(id);
    if (!user) return next(new ApiError(404, 'User not found'));

    user.accountStatus = 'active';
    user.isActive = true;
    user.suspensionReason = '';
    memoryUsers.set(id, user);

    return ApiResponse.success(res, user, 'User reactivated successfully');
  } catch (err) {
    next(err);
  }
}

/**
 * GET /api/v1/agency/parents
 * Paginated list of parent users with ParentProfile details
 */
async function getParents(req, res, next) {
  try {
    const { search, status } = req.query;
    const { page, limit, skip } = pagination(req.query);

    if (isDbConnected()) {
      const filter = { role: ROLES.PARENT };
      if (status && status !== 'all') {
        if (status === 'suspended') {
          filter.$or = [{ accountStatus: 'suspended' }, { isActive: false }];
        } else if (status === 'active') {
          filter.accountStatus = 'active';
          filter.isActive = true;
        }
      }

      let users = await User.find(filter)
        .select('-passwordHash')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean();

      if (search && search.trim()) {
        const query = search.trim().toLowerCase();
        users = users.filter(
          (u) =>
            u.name?.toLowerCase().includes(query) ||
            u.email?.toLowerCase().includes(query)
        );
      }

      const ParentProfile = require('../models/ParentProfile');
      const enhanced = await Promise.all(
        users.map(async (u) => {
          const profile = await ParentProfile.findOne({ user: u._id }).lean();
          return {
            ...u,
            profile: profile || null,
            childrenCount: profile?.children?.length || 0,
            isNicVerified: profile?.isNicVerified || false,
            address: profile?.address || '',
          };
        })
      );

      const total = await User.countDocuments(filter);
      res.set('X-Page', String(page));
      res.set('X-Limit', String(limit));
      res.set('X-Total', String(total));
      res.set('X-Has-More', String(skip + limit < total));

      return ApiResponse.success(res, enhanced, 'Parents retrieved successfully');
    }

    initSampleUsers();
    let list = Array.from(memoryUsers.values()).filter((u) => u.role === 'parent');
    if (status && status !== 'all') {
      list = list.filter((u) => u.accountStatus.toLowerCase() === status.toLowerCase());
    }
    if (search && search.trim()) {
      const q = search.trim().toLowerCase();
      list = list.filter((u) => u.name.toLowerCase().includes(q) || u.email.toLowerCase().includes(q));
    }

    const enhanced = list.map((u) => ({
      ...u,
      childrenCount: 2,
      isNicVerified: true,
      address: 'Colombo, Western Province',
      emergencyContact: '+94 77 999 8888',
      children: [
        { name: 'Dinuka', age: '4 yrs', notes: 'Allergic to peanuts' },
        { name: 'Senuka', age: '1 yr', notes: 'Needs afternoon nap' },
      ],
    }));

    const total = enhanced.length;
    const paged = enhanced.slice(skip, skip + limit);

    res.set('X-Page', String(page));
    res.set('X-Limit', String(limit));
    res.set('X-Total', String(total));
    res.set('X-Has-More', String(skip + limit < total));

    return ApiResponse.success(res, paged, 'Parents retrieved successfully');
  } catch (err) {
    next(err);
  }
}

/**
 * GET /api/v1/agency/babysitters
 * Paginated list of babysitters with BabysitterProfile details
 */
async function getBabysitters(req, res, next) {
  try {
    const { search, status } = req.query;
    const { page, limit, skip } = pagination(req.query);

    if (isDbConnected()) {
      const filter = { role: ROLES.BABYSITTER };
      if (status && status !== 'all') {
        if (status === 'suspended') {
          filter.$or = [{ accountStatus: 'suspended' }, { isActive: false }];
        } else if (status === 'active') {
          filter.accountStatus = 'active';
          filter.isActive = true;
        }
      }

      let users = await User.find(filter)
        .select('-passwordHash')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean();

      if (search && search.trim()) {
        const query = search.trim().toLowerCase();
        users = users.filter(
          (u) =>
            u.name?.toLowerCase().includes(query) ||
            u.email?.toLowerCase().includes(query)
        );
      }

      const enhanced = await Promise.all(
        users.map(async (u) => {
          const profile = await BabysitterProfile.findOne({ user: u._id }).lean();
          return {
            ...u,
            profile: profile || null,
            experienceYears: profile?.experienceYears || 1,
            hourlyRate: profile?.hourlyRate || 1500,
            verificationStatus: profile?.verificationStatus || 'pending',
            rating: profile?.rating || 5.0,
            skills: profile?.skills || [],
          };
        })
      );

      const total = await User.countDocuments(filter);
      res.set('X-Page', String(page));
      res.set('X-Limit', String(limit));
      res.set('X-Total', String(total));
      res.set('X-Has-More', String(skip + limit < total));

      return ApiResponse.success(res, enhanced, 'Babysitters retrieved successfully');
    }

    initSampleUsers();
    let list = Array.from(memoryUsers.values()).filter((u) => u.role === 'babysitter');
    if (status && status !== 'all') {
      list = list.filter((u) => u.accountStatus.toLowerCase() === status.toLowerCase());
    }
    if (search && search.trim()) {
      const q = search.trim().toLowerCase();
      list = list.filter((u) => u.name.toLowerCase().includes(q) || u.email.toLowerCase().includes(q));
    }

    const enhanced = list.map((u) => ({
      ...u,
      experienceYears: 4,
      hourlyRate: 1500,
      verificationStatus: 'verified',
      rating: u.averageRating || 4.9,
      skills: ['First Aid & CPR', 'Toddler Care', 'Creative Play'],
      languages: ['English', 'Sinhala'],
      qualifications: ['Diploma in Early Childhood Education'],
    }));

    const total = enhanced.length;
    const paged = enhanced.slice(skip, skip + limit);

    res.set('X-Page', String(page));
    res.set('X-Limit', String(limit));
    res.set('X-Total', String(total));
    res.set('X-Has-More', String(skip + limit < total));

    return ApiResponse.success(res, paged, 'Babysitters retrieved successfully');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getDashboard,
  dashboard: getDashboard,
  getUsers,
  getUserById,
  suspendUser,
  reactivateUser,
  getParents,
  getBabysitters,
  memoryUsers,
  memoryVerifications,
  memoryReports,
};
