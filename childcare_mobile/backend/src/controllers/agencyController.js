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
      booking.cancelledBy = 'agency_admin';
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
  memoryUsers,
  memoryBookings,
  memoryVerifications,
  memoryReports,
};
