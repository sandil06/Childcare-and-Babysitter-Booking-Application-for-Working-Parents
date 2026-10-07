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
const verificationService = require('../services/verificationService');

function isDbConnected() {
  return mongoose.connection.readyState === 1;
}

// In-memory mock stores for offline / test resilience
const memoryVerifications = new Map();
const memoryReports = new Map();
const memoryUsers = new Map();
const memoryBookings = new Map();

function initSampleBookings() {
  if (memoryBookings.size > 0) return;

  const samples = [
    {
      _id: 'bk-901',
      id: 'bk-901',
      bookingId: '#BK-901',
      parent: { _id: 'u-1', name: 'Dulani Senanayake', email: 'dulani.s@gmail.com', phone: '+94 77 445 5667' },
      babysitter: { _id: 'u-2', name: 'Amaya Fernando', email: 'amaya.fernando@example.com', phone: '+94 77 123 4567' },
      parentName: 'Dulani Senanayake',
      babysitterName: 'Amaya Fernando',
      parentPhone: '+94 77 445 5667',
      babysitterPhone: '+94 77 123 4567',
      date: '2026-10-08',
      startTime: '09:00 AM',
      endTime: '01:00 PM',
      durationHours: 4,
      hourlyRate: 1500,
      subtotal: 6000,
      serviceFee: 600,
      totalAmount: 6600,
      status: 'confirmed',
      paymentStatus: 'paid',
      address: 'No 45, Flower Road, Colombo 07',
      notes: 'Please arrive 10 minutes early.',
      createdAt: new Date(Date.now() - 86400000 * 2),
    },
    {
      _id: 'bk-902',
      id: 'bk-902',
      bookingId: '#BK-902',
      parent: { _id: 'u-4', name: 'Saman Jayatilleke', email: 'saman.j@yahoo.com', phone: '+94 70 334 8899' },
      babysitter: { _id: 'u-3', name: 'Kavindi Perera', email: 'kavindi.perera@example.com', phone: '+94 71 987 6543' },
      parentName: 'Saman Jayatilleke',
      babysitterName: 'Kavindi Perera',
      parentPhone: '+94 70 334 8899',
      babysitterPhone: '+94 71 987 6543',
      date: '2026-10-07',
      startTime: '02:00 PM',
      endTime: '06:00 PM',
      durationHours: 4,
      hourlyRate: 1350,
      subtotal: 5400,
      serviceFee: 540,
      totalAmount: 5940,
      status: 'in_progress',
      paymentStatus: 'paid',
      address: '22/4 Nawala Road, Nugegoda',
      notes: 'Baby needs feeding at 3:30 PM.',
      createdAt: new Date(Date.now() - 86400000 * 1),
    },
    {
      _id: 'bk-903',
      id: 'bk-903',
      bookingId: '#BK-903',
      parent: { _id: 'u-5', name: 'Nimali Disanayake', email: 'nimali.d@gmail.com', phone: '+94 75 221 4455' },
      babysitter: { _id: 'u-6', name: 'Sanduni Jayawardena', email: 'sanduni.j@example.com', phone: '+94 76 555 8899' },
      parentName: 'Nimali Disanayake',
      babysitterName: 'Sanduni Jayawardena',
      parentPhone: '+94 75 221 4455',
      babysitterPhone: '+94 76 555 8899',
      date: '2026-10-06',
      startTime: '08:00 AM',
      endTime: '12:00 PM',
      durationHours: 4,
      hourlyRate: 1800,
      subtotal: 7200,
      serviceFee: 720,
      totalAmount: 7920,
      status: 'completed',
      paymentStatus: 'paid',
      address: '15 Station Road, Dehiwala',
      notes: 'Care completed smoothly.',
      createdAt: new Date(Date.now() - 86400000 * 3),
    },
  ];

  for (const s of samples) {
    memoryBookings.set(s._id, s);
  }
}

initSampleBookings();

function initSampleReports() {
  if (memoryReports.size > 0) return;

  const samples = [
    {
      _id: 'rep-401',
      id: 'rep-401',
      reporter: { _id: 'u-1', name: 'Dulani Senanayake', email: 'dulani.s@gmail.com', role: 'parent', phone: '+94 77 445 5667' },
      reportedUser: { _id: 'u-2', name: 'Amaya Fernando', email: 'amaya.fernando@example.com', role: 'babysitter', phone: '+94 77 123 4567' },
      booking: { _id: 'bk-901', bookingId: '#BK-901', date: '2026-10-08', totalAmount: 6600 },
      category: 'Inappropriate Behaviour',
      priority: 'high',
      status: 'open',
      description: 'Sitter arrived 45 minutes late without prior notice and was continuously distracted on mobile device.',
      evidence: ['https://images.unsplash.com/photo-1544717305-2782549b5136'],
      resolutionNotes: '',
      resolvedBy: null,
      resolvedAt: null,
      createdAt: new Date(Date.now() - 3600000 * 5),
    },
    {
      _id: 'rep-402',
      id: 'rep-402',
      reporter: { _id: 'u-3', name: 'Kavindi Perera', email: 'kavindi.perera@example.com', role: 'babysitter', phone: '+94 71 987 6543' },
      reportedUser: { _id: 'u-4', name: 'Saman Jayatilleke', email: 'saman.j@yahoo.com', role: 'parent', phone: '+94 70 334 8899' },
      booking: { _id: 'bk-902', bookingId: '#BK-902', date: '2026-10-07', totalAmount: 5940 },
      category: 'Payment Issue',
      priority: 'medium',
      status: 'under_review',
      description: 'Extended care shift by 2 additional hours outside agreed booking window without settling overtime fee.',
      evidence: [],
      resolutionNotes: 'Agency rep reached out to parent regarding overtime charge adjustment.',
      resolvedBy: null,
      resolvedAt: null,
      createdAt: new Date(Date.now() - 86400000 * 1),
    },
    {
      _id: 'rep-403',
      id: 'rep-403',
      reporter: { _id: 'u-5', name: 'Nimali Disanayake', email: 'nimali.d@gmail.com', role: 'parent', phone: '+94 75 221 4455' },
      reportedUser: { _id: 'u-6', name: 'Sanduni Jayawardena', email: 'sanduni.j@example.com', role: 'babysitter', phone: '+94 76 555 8899' },
      booking: { _id: 'bk-903', bookingId: '#BK-903', date: '2026-10-06', totalAmount: 7920 },
      category: 'Safety',
      priority: 'urgent',
      status: 'open',
      description: 'Babysitter left the toddler unattended in the living room for more than 15 minutes near open balcony doors.',
      evidence: [],
      resolutionNotes: '',
      resolvedBy: null,
      resolvedAt: null,
      createdAt: new Date(Date.now() - 3600000 * 12),
    },
    {
      _id: 'rep-404',
      id: 'rep-404',
      reporter: { _id: 'u-1', name: 'Dulani Senanayake', email: 'dulani.s@gmail.com', role: 'parent', phone: '+94 77 445 5667' },
      reportedUser: { _id: 'u-7', name: 'Kasun Rathnayake', email: 'kasun.r@example.com', role: 'babysitter', phone: '+94 72 333 4455' },
      booking: null,
      category: 'Fraud',
      priority: 'low',
      status: 'resolved',
      description: 'Suspected fake profile details and mismatched profile picture compared to submitted identity documents.',
      evidence: [],
      resolutionNotes: 'Identity re-verified via government ID portal. Profile updated and cleared.',
      resolvedBy: { name: 'Agency Admin' },
      resolvedAt: new Date(Date.now() - 86400000 * 3),
      createdAt: new Date(Date.now() - 86400000 * 5),
    },
    {
      _id: 'rep-405',
      id: 'rep-405',
      reporter: { _id: 'u-4', name: 'Saman Jayatilleke', email: 'saman.j@yahoo.com', role: 'parent', phone: '+94 70 334 8899' },
      reportedUser: { _id: 'u-8', name: 'Thilini Rajapaksha', email: 'thilini.r@example.com', role: 'babysitter', phone: '+94 77 888 9900' },
      booking: null,
      category: 'Service Quality',
      priority: 'low',
      status: 'dismissed',
      description: 'Minor dispute regarding snack preferences provided during the booking.',
      evidence: [],
      resolutionNotes: 'Reviewed communication logs; no policy violation found. Advised both parties on clear prep notes.',
      resolvedBy: { name: 'Agency Admin' },
      resolvedAt: new Date(Date.now() - 86400000 * 4),
      createdAt: new Date(Date.now() - 86400000 * 6),
    },
  ];

  for (const s of samples) {
    memoryReports.set(s._id, s);
  }
}

initSampleReports();

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
      await verificationService.syncVerificationRequests();

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

      const formattedVerifications = (recentVerifications || []).map((v) => ({
        ...v,
        id: v._id ? v._id.toString() : v.id,
        name: v.babysitter?.name || v.babysitterProfile?.name || v.name || 'Babysitter',
        email: v.babysitter?.email || v.babysitterProfile?.email || v.email || '',
        phone: v.babysitter?.phone || v.babysitterProfile?.phone || v.phone || '',
        avatar: v.babysitter?.avatar || v.babysitterProfile?.profileImage || v.avatar || '',
      }));

      const statsData = {
        totalUsers,
        totalParents,
        totalBabysitters,
        verifiedBabysitters,
        pendingVerifications,
        rejectedVerifications,
        rejectedApplications: rejectedVerifications,
        totalBookings,
        activeBookings,
        completedBookings,
        cancelledBookings,
        openComplaints,
        openSafetyReports: openComplaints,
        resolvedComplaints,
      };

      return ApiResponse.success(
        res,
        {
          stats: statsData,
          ...statsData,
          recentVerifications: formattedVerifications,
          recentVerificationRequests: formattedVerifications,
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

async function findUserFlexible(id) {
  if (!id) return null;
  if (isDbConnected()) {
    if (mongoose.Types.ObjectId.isValid(id)) {
      const u = await User.findById(id);
      if (u) return u;
    }
    const cleanId = id.toString().trim();
    const byEmailOrPhone = await User.findOne({
      $or: [{ email: cleanId.toLowerCase() }, { phone: cleanId }],
    });
    if (byEmailOrPhone) return byEmailOrPhone;

    try {
      const BabysitterProfile = require('../models/BabysitterProfile');
      if (mongoose.Types.ObjectId.isValid(cleanId)) {
        const bp = await BabysitterProfile.findById(cleanId);
        if (bp && (bp.user || bp.userId)) {
          const u = await User.findById(bp.user || bp.userId);
          if (u) return u;
        }
      }
    } catch (_) {}

    try {
      const ParentProfile = require('../models/ParentProfile');
      if (mongoose.Types.ObjectId.isValid(cleanId)) {
        const pp = await ParentProfile.findById(cleanId);
        if (pp && (pp.user || pp.userId)) {
          const u = await User.findById(pp.user || pp.userId);
          if (u) return u;
        }
      }
    } catch (_) {}
  }

  initSampleUsers();
  let mem = memoryUsers.get(id);
  if (!mem) {
    const cleanId = id.toString().trim().toLowerCase();
    mem = Array.from(memoryUsers.values()).find(
      (u) =>
        u._id === id ||
        u.id === id ||
        u.email?.toLowerCase() === cleanId ||
        u.phone === cleanId
    );
  }
  return mem || null;
}

/**
 * GET /api/v1/agency/users/:id
 * Retrieve details for a specific user
 */
async function getUserById(req, res, next) {
  try {
    const { id } = req.params;
    const user = await findUserFlexible(id);
    if (!user) return next(new ApiError(404, 'User not found'));

    if (user.toObject) {
      const safeUser = user.toObject();
      delete safeUser.passwordHash;
      return ApiResponse.success(res, safeUser, 'User details retrieved');
    }

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

    const user = await findUserFlexible(id);
    if (!user) return next(new ApiError(404, 'User not found'));

    if (user.save) {
      user.accountStatus = 'suspended';
      user.isActive = false;
      user.suspensionReason = reason.trim();
      user.suspendedAt = new Date();
      await user.save();

      if (user.role === 'babysitter') {
        try {
          const BabysitterProfile = require('../models/BabysitterProfile');
          await BabysitterProfile.findOneAndUpdate(
            { user: user._id },
            { isAvailable: false }
          );
        } catch (_) {}
      }

      try {
        await AuditLog.create({
          actor:
            adminUser?._id && mongoose.Types.ObjectId.isValid(adminUser._id)
              ? adminUser._id
              : null,
          adminName: adminUser?.name || 'Agency Administrator',
          adminEmail: adminUser?.email || '',
          action: 'suspend_user',
          targetType: 'User',
          targetId: user._id.toString(),
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

    // In-memory fallback
    user.accountStatus = 'suspended';
    user.isActive = false;
    user.suspensionReason = reason.trim();
    user.suspendedAt = new Date();
    memoryUsers.set(user.id || user._id || id, user);

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

    const user = await findUserFlexible(id);
    if (!user) return next(new ApiError(404, 'User not found'));

    if (user.save) {
      user.accountStatus = 'active';
      user.isActive = true;
      user.suspensionReason = '';
      user.suspendedAt = null;
      await user.save();

      if (user.role === 'babysitter') {
        try {
          const BabysitterProfile = require('../models/BabysitterProfile');
          await BabysitterProfile.findOneAndUpdate(
            { user: user._id },
            { isAvailable: true }
          );
        } catch (_) {}
      }

      try {
        await AuditLog.create({
          actor:
            adminUser?._id && mongoose.Types.ObjectId.isValid(adminUser._id)
              ? adminUser._id
              : null,
          adminName: adminUser?.name || 'Agency Administrator',
          adminEmail: adminUser?.email || '',
          action: 'reactivate_user',
          targetType: 'User',
          targetId: user._id.toString(),
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
          message:
            'Your account has been reactivated. You can now access all services.',
          type: 'system',
        });
      } catch (notifErr) {
        // continue
      }

      const safeUser = user.toObject();
      delete safeUser.passwordHash;
      return ApiResponse.success(res, safeUser, 'User reactivated successfully');
    }

    // In-memory fallback
    user.accountStatus = 'active';
    user.isActive = true;
    user.suspensionReason = '';
    user.suspendedAt = null;
    memoryUsers.set(user.id || user._id || id, user);

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

/**
 * GET /api/v1/agency/bookings
 * Paginated list of bookings with status and search filters
 */
async function getBookings(req, res, next) {
  try {
    const { status, search } = req.query;
    const { page, limit, skip } = pagination(req.query);

    if (isDbConnected()) {
      const filter = {};
      if (status && status !== 'all') {
        filter.status = status.toLowerCase();
      }

      let bookings = await Booking.find(filter)
        .populate('parent', 'name email phone avatar')
        .populate('babysitter', 'name email phone avatar')
        .sort({ date: -1, createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .lean();

      if (search && search.trim()) {
        const q = search.trim().toLowerCase();
        bookings = bookings.filter(
          (b) =>
            b.bookingId?.toLowerCase().includes(q) ||
            b.parent?.name?.toLowerCase().includes(q) ||
            b.babysitter?.name?.toLowerCase().includes(q)
        );
      }

      const formatted = bookings.map((b) => ({
        ...b,
        id: b._id.toString(),
        parentName: b.parent?.name || 'Parent',
        babysitterName: b.babysitter?.name || 'Babysitter',
        parentPhone: b.parent?.phone || '',
        babysitterPhone: b.babysitter?.phone || '',
      }));

      const total = await Booking.countDocuments(filter);
      res.set('X-Page', String(page));
      res.set('X-Limit', String(limit));
      res.set('X-Total', String(total));
      res.set('X-Has-More', String(skip + limit < total));

      return ApiResponse.success(res, formatted, 'Bookings retrieved successfully');
    }

    initSampleBookings();
    let list = Array.from(memoryBookings.values());

    if (status && status !== 'all') {
      list = list.filter((b) => b.status.toLowerCase() === status.toLowerCase());
    }

    if (search && search.trim()) {
      const q = search.trim().toLowerCase();
      list = list.filter(
        (b) =>
          b.bookingId.toLowerCase().includes(q) ||
          b.parentName.toLowerCase().includes(q) ||
          b.babysitterName.toLowerCase().includes(q)
      );
    }

    const total = list.length;
    const paged = list.slice(skip, skip + limit);

    res.set('X-Page', String(page));
    res.set('X-Limit', String(limit));
    res.set('X-Total', String(total));
    res.set('X-Has-More', String(skip + limit < total));

    return ApiResponse.success(res, paged, 'Bookings retrieved successfully');
  } catch (err) {
    next(err);
  }
}

/**
 * PATCH /api/v1/agency/bookings/:id/cancel
 * Emergency admin cancellation for active booking
 */
async function cancelBookingByAdmin(req, res, next) {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const adminUser = req.user;

    if (!reason || !reason.trim()) {
      return next(new ApiError(400, 'Cancellation reason is required'));
    }

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(id)) {
      const booking = await Booking.findById(id);
      if (!booking) return next(new ApiError(404, 'Booking not found'));

      booking.status = 'cancelled';
      booking.cancellationReason = reason.trim();
      booking.cancelledBy = (adminUser?._id && mongoose.Types.ObjectId.isValid(adminUser._id)) ? adminUser._id : null;
      booking.cancelledAt = new Date();
      await booking.save();

      try {
        await AuditLog.create({
          actor: adminUser?._id,
          action: 'update_booking_status',
          targetType: 'Booking',
          targetId: id,
          notes: `Admin cancelled booking: ${reason.trim()}`,
        });
      } catch (logErr) {
        // continue
      }

      // Notify parent and sitter
      const bParentId = booking.parent?._id || booking.parent;
      const bSitterId = booking.babysitter?._id || booking.babysitter;
      if (bParentId) {
        Notification.create({
          user: bParentId,
          title: 'Booking Cancelled by Agency',
          message: `Your booking #${booking.bookingId || booking._id} was cancelled by administration: ${reason.trim()}`,
          type: 'booking_emergency_cancelled',
          data: { bookingId: booking._id },
        }).catch(() => {});
      }
      if (bSitterId) {
        Notification.create({
          user: bSitterId,
          title: 'Booking Cancelled by Agency',
          message: `Your booking #${booking.bookingId || booking._id} was cancelled by administration: ${reason.trim()}`,
          type: 'booking_emergency_cancelled',
          data: { bookingId: booking._id },
        }).catch(() => {});
      }

      return ApiResponse.success(res, booking, 'Booking cancelled by administrator');
    }

    initSampleBookings();
    const booking = memoryBookings.get(id);
    if (!booking) return next(new ApiError(404, 'Booking not found'));

    booking.status = 'cancelled';
    booking.cancellationReason = reason.trim();
    memoryBookings.set(id, booking);

    return ApiResponse.success(res, booking, 'Booking cancelled by administrator');
  } catch (err) {
    next(err);
  }
}

async function getReports(req, res, next) {
  try {
    const { status, priority, category, search, page = 1, limit = 20 } = req.query;
    initSampleReports();

    if (isDbConnected()) {
      const query = {};
      if (status && status !== 'all') {
        query.status = status;
      }
      if (priority && priority !== 'all') {
        query.priority = priority;
      }
      if (category && category !== 'all') {
        query.category = category;
      }

      let reports = await Report.find(query)
        .populate('reporter', 'name email role phone')
        .populate('reportedUser', 'name email role phone')
        .populate('booking', 'bookingId date startTime endTime totalAmount')
        .sort({ createdAt: -1 })
        .lean();

      if (search && search.trim()) {
        const s = search.trim().toLowerCase();
        reports = reports.filter((r) => {
          const cat = (r.category || '').toLowerCase();
          const desc = (r.description || '').toLowerCase();
          const repName = (r.reporter?.name || '').toLowerCase();
          const targetName = (r.reportedUser?.name || '').toLowerCase();
          return cat.includes(s) || desc.includes(s) || repName.includes(s) || targetName.includes(s);
        });
      }

      const total = reports.length;
      const startIndex = (Number(page) - 1) * Number(limit);
      const paginated = reports.slice(startIndex, startIndex + Number(limit));

      return ApiResponse.success(res, paginated, 'Reports retrieved successfully');
    }

    let reports = Array.from(memoryReports.values());
    if (status && status !== 'all') {
      reports = reports.filter((r) => r.status === status);
    }
    if (priority && priority !== 'all') {
      reports = reports.filter((r) => r.priority === priority);
    }
    if (category && category !== 'all') {
      reports = reports.filter((r) => r.category === category);
    }
    if (search && search.trim()) {
      const s = search.trim().toLowerCase();
      reports = reports.filter((r) => {
        const cat = (r.category || '').toLowerCase();
        const desc = (r.description || '').toLowerCase();
        const repName = (r.reporter?.name || '').toLowerCase();
        const targetName = (r.reportedUser?.name || '').toLowerCase();
        return cat.includes(s) || desc.includes(s) || repName.includes(s) || targetName.includes(s);
      });
    }

    reports.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    const total = reports.length;
    const startIndex = (Number(page) - 1) * Number(limit);
    const paginated = reports.slice(startIndex, startIndex + Number(limit));

    return ApiResponse.success(res, paginated, 'Reports retrieved successfully (mock)');
  } catch (err) {
    next(err);
  }
}

async function getReportById(req, res, next) {
  try {
    const { id } = req.params;
    initSampleReports();

    if (isDbConnected()) {
      const report = await Report.findById(id)
        .populate('reporter', 'name email role phone')
        .populate('reportedUser', 'name email role phone')
        .populate('booking')
        .populate('assignedTo', 'name email')
        .populate('resolvedBy', 'name email')
        .lean();

      if (!report) return next(new ApiError(404, 'Report not found'));
      return ApiResponse.success(res, report, 'Report details retrieved');
    }

    const report = memoryReports.get(id);
    if (!report) return next(new ApiError(404, 'Report not found'));
    return ApiResponse.success(res, report, 'Report details retrieved (mock)');
  } catch (err) {
    next(err);
  }
}

async function updateReportStatus(req, res, next) {
  try {
    const { id } = req.params;
    const { status, resolutionNotes, priority } = req.body;
    initSampleReports();

    if (!status && !priority && !resolutionNotes) {
      return next(new ApiError(400, 'At least one field to update is required'));
    }

    if (isDbConnected()) {
      const report = await Report.findById(id);
      if (!report) return next(new ApiError(404, 'Report not found'));

      if (status) report.status = status;
      if (priority) report.priority = priority;
      if (resolutionNotes !== undefined) report.resolutionNotes = resolutionNotes;
      if (status === 'resolved' || status === 'dismissed') {
        report.resolvedAt = new Date();
        report.resolvedBy = req.user?._id || req.user?.id || null;
      }

      await report.save();

      try {
        await AuditLog.create({
          adminId: req.user?._id || req.user?.id || null,
          adminName: req.user?.name || 'Agency Admin',
          adminEmail: req.user?.email || 'admin@childcare.com',
          action: 'update_report_status',
          targetType: 'Report',
          targetId: id,
          notes: `Report status updated to ${report.status}${resolutionNotes ? ': ' + resolutionNotes : ''}`,
        });
      } catch (logErr) {
        // continue
      }

      return ApiResponse.success(res, report, 'Report status updated successfully');
    }

    const report = memoryReports.get(id);
    if (!report) return next(new ApiError(404, 'Report not found'));

    if (status) report.status = status;
    if (priority) report.priority = priority;
    if (resolutionNotes !== undefined) report.resolutionNotes = resolutionNotes;
    if (status === 'resolved' || status === 'dismissed') {
      report.resolvedAt = new Date();
      report.resolvedBy = { name: req.user?.name || 'Agency Admin' };
    }
    memoryReports.set(id, report);

    return ApiResponse.success(res, report, 'Report status updated successfully (mock)');
  } catch (err) {
    next(err);
  }
}

async function resolveReport(req, res, next) {
  try {
    const { id } = req.params;
    const { resolutionNotes } = req.body;
    initSampleReports();

    if (isDbConnected()) {
      const report = await Report.findById(id);
      if (!report) return next(new ApiError(404, 'Report not found'));

      report.status = 'resolved';
      report.resolutionNotes = resolutionNotes || report.resolutionNotes || 'Resolved by agency administrator';
      report.resolvedAt = new Date();
      report.resolvedBy = req.user?._id || req.user?.id || null;
      await report.save();

      try {
        await AuditLog.create({
          adminId: req.user?._id || req.user?.id || null,
          adminName: req.user?.name || 'Agency Admin',
          adminEmail: req.user?.email || 'admin@childcare.com',
          action: 'resolve_report',
          targetType: 'Report',
          targetId: id,
          notes: `Report resolved: ${report.resolutionNotes}`,
        });
      } catch (logErr) {
        // continue
      }

      return ApiResponse.success(res, report, 'Report resolved successfully');
    }

    const report = memoryReports.get(id);
    if (!report) return next(new ApiError(404, 'Report not found'));

    report.status = 'resolved';
    report.resolutionNotes = resolutionNotes || report.resolutionNotes || 'Resolved by agency administrator';
    report.resolvedAt = new Date();
    report.resolvedBy = { name: req.user?.name || 'Agency Admin' };
    memoryReports.set(id, report);

    return ApiResponse.success(res, report, 'Report resolved successfully (mock)');
  } catch (err) {
    next(err);
  }
}

async function escalateReport(req, res, next) {
  try {
    const { id } = req.params;
    const { notes } = req.body;
    initSampleReports();

    if (isDbConnected()) {
      const report = await Report.findById(id);
      if (!report) return next(new ApiError(404, 'Report not found'));

      report.priority = 'urgent';
      report.status = 'under_review';
      if (notes) report.resolutionNotes = (report.resolutionNotes ? report.resolutionNotes + '\n' : '') + `Escalation note: ${notes}`;
      await report.save();

      try {
        await AuditLog.create({
          adminId: req.user?._id || req.user?.id || null,
          adminName: req.user?.name || 'Agency Admin',
          adminEmail: req.user?.email || 'admin@childcare.com',
          action: 'escalate_report',
          targetType: 'Report',
          targetId: id,
          notes: `Report escalated to URGENT priority`,
        });
      } catch (logErr) {
        // continue
      }

      return ApiResponse.success(res, report, 'Report escalated to urgent priority');
    }

    const report = memoryReports.get(id);
    if (!report) return next(new ApiError(404, 'Report not found'));

    report.priority = 'urgent';
    report.status = 'under_review';
    if (notes) report.resolutionNotes = (report.resolutionNotes ? report.resolutionNotes + '\n' : '') + `Escalation note: ${notes}`;
    memoryReports.set(id, report);

    return ApiResponse.success(res, report, 'Report escalated to urgent priority (mock)');
  } catch (err) {
    next(err);
  }
}

async function dismissReport(req, res, next) {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    initSampleReports();

    if (isDbConnected()) {
      const report = await Report.findById(id);
      if (!report) return next(new ApiError(404, 'Report not found'));

      report.status = 'dismissed';
      report.resolutionNotes = reason ? `Dismissed: ${reason}` : 'Dismissed by agency administrator';
      report.resolvedAt = new Date();
      report.resolvedBy = req.user?._id || req.user?.id || null;
      await report.save();

      try {
        await AuditLog.create({
          adminId: req.user?._id || req.user?.id || null,
          adminName: req.user?.name || 'Agency Admin',
          adminEmail: req.user?.email || 'admin@childcare.com',
          action: 'dismiss_report',
          targetType: 'Report',
          targetId: id,
          notes: `Report dismissed: ${report.resolutionNotes}`,
        });
      } catch (logErr) {
        // continue
      }

      return ApiResponse.success(res, report, 'Report dismissed');
    }

    const report = memoryReports.get(id);
    if (!report) return next(new ApiError(404, 'Report not found'));

    report.status = 'dismissed';
    report.resolutionNotes = reason ? `Dismissed: ${reason}` : 'Dismissed by agency administrator';
    report.resolvedAt = new Date();
    report.resolvedBy = { name: req.user?.name || 'Agency Admin' };
    memoryReports.set(id, report);

    return ApiResponse.success(res, report, 'Report dismissed (mock)');
  } catch (err) {
    next(err);
  }
}

async function getStatistics(req, res, next) {
  try {
    initSampleUsers();
    initSampleBookings();
    initSampleReports();

    if (isDbConnected()) {
      await verificationService.syncVerificationRequests();
      const [
        totalUsers,
        totalParents,
        totalBabysitters,
        activeUsers,
        suspendedUsers,
        totalBookings,
        pendingBookings,
        activeBookings,
        completedBookings,
        cancelledBookings,
        pendingVerifications,
        underReviewVerifications,
        verifiedRequests,
        rejectedVerifications,
        totalReports,
        openReports,
        underReviewReports,
        resolvedReports,
        urgentReports,
      ] = await Promise.all([
        User.countDocuments(),
        User.countDocuments({ role: ROLES.PARENT }),
        User.countDocuments({ role: ROLES.BABYSITTER }),
        User.countDocuments({ accountStatus: 'active' }),
        User.countDocuments({ accountStatus: 'suspended' }),
        Booking.countDocuments(),
        Booking.countDocuments({ status: { $in: ['pending', 'requested'] } }),
        Booking.countDocuments({ status: { $in: ['confirmed', 'in_progress', 'started'] } }),
        Booking.countDocuments({ status: 'completed' }),
        Booking.countDocuments({ status: 'cancelled' }),
        VerificationRequest.countDocuments({ status: 'pending' }),
        VerificationRequest.countDocuments({ status: 'under_review' }),
        VerificationRequest.countDocuments({ status: 'verified' }),
        VerificationRequest.countDocuments({ status: 'rejected' }),
        Report.countDocuments(),
        Report.countDocuments({ status: 'open' }),
        Report.countDocuments({ status: 'under_review' }),
        Report.countDocuments({ status: 'resolved' }),
        Report.countDocuments({ priority: 'urgent' }),
      ]);

      const volumeAgg = await Booking.aggregate([
        { $match: { paymentStatus: 'paid' } },
        { $group: { _id: null, total: { $sum: '$totalAmount' } } },
      ]);
      const totalVolume = volumeAgg[0]?.total || 0;
      const platformRevenue = Math.round(totalVolume * 0.1);

      return ApiResponse.success(res, {
        users: {
          total: totalUsers,
          parents: totalParents,
          babysitters: totalBabysitters,
          verified: verifiedRequests,
          active: activeUsers,
          suspended: suspendedUsers,
        },
        bookings: {
          total: totalBookings,
          pending: pendingBookings,
          active: activeBookings,
          completed: completedBookings,
          cancelled: cancelledBookings,
          rejected: 0,
        },
        verifications: {
          pending: pendingVerifications,
          under_review: underReviewVerifications,
          verified: verifiedRequests,
          rejected: rejectedVerifications,
        },
        reports: {
          total: totalReports,
          open: openReports,
          under_review: underReviewReports,
          resolved: resolvedReports,
          urgent: urgentReports,
        },
        payments: {
          totalVolume,
          platformRevenue,
          successful: completedBookings,
          failed: cancelledBookings,
        },
      }, 'System statistics retrieved successfully');
    }

    // Offline / Mock aggregation
    const usersList = Array.from(memoryUsers.values());
    const bookingsList = Array.from(memoryBookings.values());
    const verificationsList = Array.from(memoryVerifications.values());
    const reportsList = Array.from(memoryReports.values());

    const totalUsers = usersList.length || 148;
    const totalParents = usersList.filter((u) => u.role === 'parent').length || 92;
    const totalBabysitters = usersList.filter((u) => u.role === 'babysitter').length || 54;
    const activeUsers = usersList.filter((u) => u.accountStatus !== 'suspended').length || 142;
    const suspendedUsers = usersList.filter((u) => u.accountStatus === 'suspended').length || 6;

    const totalBookings = bookingsList.length || 320;
    const pendingBookings = bookingsList.filter((b) => b.status === 'pending').length || 8;
    const activeBookings = bookingsList.filter((b) => ['confirmed', 'in_progress'].includes(b.status)).length || 18;
    const completedBookings = bookingsList.filter((b) => b.status === 'completed').length || 284;
    const cancelledBookings = bookingsList.filter((b) => b.status === 'cancelled').length || 18;

    const pendingVerifications = verificationsList.filter((v) => v.status === 'pending').length || 12;
    const underReviewVerifications = verificationsList.filter((v) => v.status === 'under_review').length || 4;
    const verifiedRequests = verificationsList.filter((v) => v.status === 'verified').length || 38;
    const rejectedVerifications = verificationsList.filter((v) => v.status === 'rejected').length || 4;

    const totalReports = reportsList.length || 36;
    const openReports = reportsList.filter((r) => r.status === 'open').length || 5;
    const underReviewReports = reportsList.filter((r) => r.status === 'under_review').length || 4;
    const resolvedReports = reportsList.filter((r) => r.status === 'resolved').length || 27;
    const urgentReports = reportsList.filter((r) => r.priority === 'urgent').length || 2;

    const totalVolume = bookingsList.reduce((acc, b) => acc + (b.totalAmount || 0), 0) || 486000;
    const platformRevenue = Math.round(totalVolume * 0.1);

    return ApiResponse.success(res, {
      users: {
        total: totalUsers,
        parents: totalParents,
        babysitters: totalBabysitters,
        verified: verifiedRequests,
        active: activeUsers,
        suspended: suspendedUsers,
      },
      bookings: {
        total: totalBookings,
        pending: pendingBookings,
        active: activeBookings,
        completed: completedBookings,
        cancelled: cancelledBookings,
        rejected: 0,
      },
      verifications: {
        pending: pendingVerifications,
        under_review: underReviewVerifications,
        verified: verifiedRequests,
        rejected: rejectedVerifications,
      },
      reports: {
        total: totalReports,
        open: openReports,
        under_review: underReviewReports,
        resolved: resolvedReports,
        urgent: urgentReports,
      },
      payments: {
        totalVolume,
        platformRevenue,
        successful: completedBookings,
        failed: cancelledBookings,
      },
    }, 'System statistics retrieved successfully (mock)');
  } catch (err) {
    next(err);
  }
}

const memoryAuditLogs = [];

function initSampleAuditLogs() {
  if (memoryAuditLogs.length > 0) return;

  const samples = [
    {
      _id: 'audit-01',
      id: 'audit-01',
      adminName: 'Chief Compliance Officer',
      adminEmail: 'compliance@littlehands.lk',
      action: 'approve_verification',
      targetType: 'VerificationRequest',
      targetId: 'ver-101',
      notes: 'Approved babysitter verification documents for Amaya Fernando',
      createdAt: new Date(Date.now() - 3600000 * 2),
    },
    {
      _id: 'audit-02',
      id: 'audit-02',
      adminName: 'Chief Compliance Officer',
      adminEmail: 'compliance@littlehands.lk',
      action: 'suspend_user',
      targetType: 'User',
      targetId: 'u-1',
      notes: 'Suspended user account: Repeated policy violations',
      createdAt: new Date(Date.now() - 3600000 * 4),
    },
    {
      _id: 'audit-03',
      id: 'audit-03',
      adminName: 'Agency Administrator',
      adminEmail: 'admin@littlehands.lk',
      action: 'resolve_report',
      targetType: 'Report',
      targetId: 'rep-401',
      notes: 'Mediation complete, refund credited',
      createdAt: new Date(Date.now() - 86400000),
    },
  ];

  memoryAuditLogs.push(...samples);
}

initSampleAuditLogs();

async function getAuditLogs(req, res, next) {
  try {
    const { action, targetType, page = 1, limit = 20 } = req.query;
    initSampleAuditLogs();

    if (isDbConnected()) {
      const query = {};
      if (action && action !== 'all') query.action = action;
      if (targetType && targetType !== 'all') query.targetType = targetType;

      const skip = (Number(page) - 1) * Number(limit);
      const [logs, total] = await Promise.all([
        AuditLog.find(query)
          .populate('actor', 'name email role')
          .sort({ createdAt: -1 })
          .skip(skip)
          .limit(Number(limit))
          .lean(),
        AuditLog.countDocuments(query),
      ]);

      return ApiResponse.paginated(res, logs, { page, limit, total }, 'Audit logs retrieved successfully');
    }

    let logs = [...memoryAuditLogs];
    if (action && action !== 'all') {
      logs = logs.filter((l) => l.action === action);
    }
    if (targetType && targetType !== 'all') {
      logs = logs.filter((l) => l.targetType === targetType);
    }

    logs.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    const total = logs.length;
    const startIndex = (Number(page) - 1) * Number(limit);
    const paginated = logs.slice(startIndex, startIndex + Number(limit));

    return ApiResponse.paginated(res, paginated, { page, limit, total }, 'Audit logs retrieved successfully (mock)');
  } catch (err) {
    next(err);
  }
}

const memoryAgencyNotifications = [];

function initSampleAgencyNotifications() {
  if (memoryAgencyNotifications.length > 0) return;

  const samples = [
    {
      _id: 'anotif-1',
      id: 'anotif-1',
      title: 'New Verification Request Submitted',
      message: 'Amaya Fernando uploaded police clearance and qualification certificates for review.',
      type: 'verification_submitted',
      category: 'verification',
      targetAudience: 'agency',
      priority: 'high',
      isRead: false,
      createdAt: new Date(Date.now() - 1000 * 60 * 25),
      data: { verificationId: 'ver-101', babysitterId: 'sitter-1' },
    },
    {
      _id: 'anotif-2',
      id: 'anotif-2',
      title: 'Urgent Safety Report Filed',
      message: 'Parent Dulani Senanayake filed an urgent safety incident report regarding booking BK-901.',
      type: 'high_priority_complaint',
      category: 'safety',
      targetAudience: 'agency',
      priority: 'urgent',
      isRead: false,
      createdAt: new Date(Date.now() - 1000 * 60 * 90),
      data: { reportId: 'rep-401', bookingId: 'BK-901' },
    },
    {
      _id: 'anotif-3',
      id: 'anotif-3',
      title: 'Automated Atlas Backup Completed',
      message: 'Daily encrypted cluster snapshot and audit log backup completed without anomalies.',
      type: 'system_alert',
      category: 'system',
      targetAudience: 'agency',
      priority: 'normal',
      isRead: true,
      createdAt: new Date(Date.now() - 1000 * 3600 * 6),
      data: { component: 'mongodb_atlas' },
    },
    {
      _id: 'anotif-4',
      id: 'anotif-4',
      title: 'Verification Changes Submitted',
      message: 'Kavindi Perera updated first aid certification documents per agency feedback.',
      type: 'verification_updated',
      category: 'verification',
      targetAudience: 'agency',
      priority: 'normal',
      isRead: true,
      createdAt: new Date(Date.now() - 1000 * 3600 * 18),
      data: { verificationId: 'ver-102' },
    },
  ];

  memoryAgencyNotifications.push(...samples);
}

initSampleAgencyNotifications();

/**
 * GET /api/v1/agency/notifications
 * Administrative notifications feed with category filter and unread count
 */
async function getAgencyNotifications(req, res, next) {
  try {
    const { category = 'all', unreadOnly, page = 1, limit = 20 } = req.query;
    initSampleAgencyNotifications();

    const verificationTypes = [
      'verification_submitted',
      'verification_updated',
      'verification_approved',
      'verification_rejected',
      'verification_changes_requested',
    ];
    const safetyTypes = ['safety_report', 'high_priority_complaint'];
    const systemTypes = ['system_alert', 'agency_broadcast', 'system', 'user_suspended', 'user_reactivated'];

    if (isDbConnected()) {
      const query = {
        $or: [
          { user: req.user?._id || req.user?.id },
          { 'data.targetAudience': { $in: ['all', 'agency'] } },
          { type: { $in: [...verificationTypes, ...safetyTypes, ...systemTypes] } },
        ],
      };

      if (category === 'verification') {
        query.type = { $in: verificationTypes };
      } else if (category === 'safety') {
        query.type = { $in: safetyTypes };
      } else if (category === 'system') {
        query.type = { $in: systemTypes };
      }

      if (unreadOnly === 'true') {
        query.isRead = false;
      }

      const skip = (Number(page) - 1) * Number(limit);
      const [notifs, total, unreadCount] = await Promise.all([
        Notification.find(query).sort({ createdAt: -1 }).skip(skip).limit(Number(limit)).lean(),
        Notification.countDocuments(query),
        Notification.countDocuments({ ...query, isRead: false }),
      ]);

      res.set('X-Unread-Count', String(unreadCount));
      return ApiResponse.paginated(res, notifs, { page, limit, total }, 'Agency notifications retrieved');
    }

    let list = [...memoryAgencyNotifications];
    if (category === 'verification') {
      list = list.filter((n) => n.category === 'verification' || verificationTypes.includes(n.type));
    } else if (category === 'safety') {
      list = list.filter((n) => n.category === 'safety' || safetyTypes.includes(n.type));
    } else if (category === 'system') {
      list = list.filter((n) => n.category === 'system' || systemTypes.includes(n.type));
    }

    if (unreadOnly === 'true') {
      list = list.filter((n) => !n.isRead);
    }

    list.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    const total = list.length;
    const unreadCount = list.filter((n) => !n.isRead).length;
    const startIndex = (Number(page) - 1) * Number(limit);
    const paginated = list.slice(startIndex, startIndex + Number(limit));

    res.set('X-Unread-Count', String(unreadCount));
    return ApiResponse.paginated(res, paginated, { page, limit, total }, 'Agency notifications retrieved (mock)');
  } catch (err) {
    next(err);
  }
}

/**
 * POST /api/v1/agency/notifications/broadcast
 * Broadcast platform alert to specific or all audience groups
 */
async function broadcastNotification(req, res, next) {
  try {
    const { title, message, targetAudience = 'all', priority = 'normal', type = 'agency_broadcast' } = req.body;
    const adminUser = req.user;

    if (!title || !title.trim()) {
      return next(new ApiError(400, 'Notification title is required'));
    }
    if (!message || !message.trim()) {
      return next(new ApiError(400, 'Notification message is required'));
    }

    const validAudiences = ['all', 'parents', 'babysitters', 'agency'];
    if (!validAudiences.includes(targetAudience)) {
      return next(new ApiError(400, `Invalid target audience. Allowed: ${validAudiences.join(', ')}`));
    }

    const broadcastId = `bcast-${Date.now()}`;
    let recipientCount = 0;

    if (isDbConnected()) {
      let roleFilter = {};
      if (targetAudience === 'parents') roleFilter = { role: 'parent', isActive: true };
      else if (targetAudience === 'babysitters') roleFilter = { role: 'babysitter', isActive: true };
      else if (targetAudience === 'agency') roleFilter = { role: { $in: ['agency', 'admin'] } };
      else roleFilter = { isActive: true };

      const users = await User.find(roleFilter).select('_id');
      recipientCount = users.length;

      if (users.length > 0) {
        const notifs = users.map((u) => ({
          user: u._id,
          title: title.trim(),
          message: message.trim(),
          type: type || 'agency_broadcast',
          data: {
            broadcastId,
            targetAudience,
            priority,
            sentBy: adminUser?._id,
          },
        }));
        await Notification.insertMany(notifs);
      }
    } else {
      initSampleUsers();
      let users = Array.from(memoryUsers.values());
      if (targetAudience === 'parents') users = users.filter((u) => u.role === 'parent');
      else if (targetAudience === 'babysitters') users = users.filter((u) => u.role === 'babysitter');
      else if (targetAudience === 'agency') users = users.filter((u) => u.role === 'agency' || u.role === 'admin');

      recipientCount = Math.max(users.length, 12);

      initSampleAgencyNotifications();
      memoryAgencyNotifications.unshift({
        _id: broadcastId,
        id: broadcastId,
        title: title.trim(),
        message: message.trim(),
        type: type || 'agency_broadcast',
        category: 'system',
        targetAudience,
        priority,
        isRead: false,
        createdAt: new Date(),
        data: {
          broadcastId,
          recipientCount,
          sentBy: adminUser?.name || 'Agency Administrator',
        },
      });
    }

    // Record administrative audit trail
    await AuditLog.record({
      actor: adminUser?._id || 'agency-admin-1',
      adminName: adminUser?.name || 'Agency Administrator',
      adminEmail: adminUser?.email || 'admin@littlehands.lk',
      action: 'broadcast_notification',
      targetType: 'Notification',
      targetId: broadcastId,
      notes: `Dispatched system broadcast [${targetAudience}]: "${title.trim()}"`,
      metadata: { targetAudience, priority, recipientCount },
    });

    return ApiResponse.success(
      res,
      {
        broadcastId,
        title: title.trim(),
        message: message.trim(),
        targetAudience,
        priority,
        recipientCount,
        dispatchedAt: new Date(),
      },
      'Notification broadcast dispatched successfully',
      201
    );
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
  getBookings,
  cancelBookingByAdmin,
  getReports,
  getReportById,
  updateReportStatus,
  resolveReport,
  escalateReport,
  dismissReport,
  getStatistics,
  getAuditLogs,
  getAgencyNotifications,
  broadcastNotification,
  memoryUsers,
  memoryBookings,
  memoryVerifications,
  memoryReports,
  memoryAuditLogs,
  memoryAgencyNotifications,
};
