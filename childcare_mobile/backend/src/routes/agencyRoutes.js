const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');
const ROLES = require('../constants/roles');
const {
  getDashboard,
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
} = require('../controllers/agencyController');
const verificationController = require('../controllers/verificationController');

// All agency endpoints require authenticated agency or admin role
const requireAgency = roleMiddleware(ROLES.AGENCY, ROLES.ADMIN);

// Dashboard, System Statistics & Audit Trails
router.get('/dashboard', auth, requireAgency, getDashboard);
router.get('/statistics', auth, requireAgency, getStatistics);
router.get('/audit-logs', auth, requireAgency, getAuditLogs);

// System Notifications & Platform Broadcasts
router.get('/notifications', auth, requireAgency, getAgencyNotifications);
router.post('/notifications/broadcast', auth, requireAgency, broadcastNotification);

// Verifications
router.get('/verifications', auth, requireAgency, verificationController.list);
router.get('/verifications/:id', auth, requireAgency, verificationController.getById);
router.patch('/verifications/:id/approve', auth, requireAgency, verificationController.approve);
router.patch('/verifications/:id/reject', auth, requireAgency, verificationController.reject);
router.patch('/verifications/:id/request-changes', auth, requireAgency, verificationController.requestChanges);

// User Management
router.get('/users', auth, requireAgency, getUsers);
router.get('/users/:id', auth, requireAgency, getUserById);
router.patch('/users/:id/suspend', auth, requireAgency, suspendUser);
router.patch('/users/:id/reactivate', auth, requireAgency, reactivateUser);

// Parent & Babysitter Management
router.get('/parents', auth, requireAgency, getParents);
router.get('/babysitters', auth, requireAgency, getBabysitters);

// Bookings Monitoring
router.get('/bookings', auth, requireAgency, getBookings);
router.patch('/bookings/:id/cancel', auth, requireAgency, cancelBookingByAdmin);

// Complaints & Safety Reports
router.get('/reports', auth, requireAgency, getReports);
router.get('/reports/:id', auth, requireAgency, getReportById);
router.patch('/reports/:id/status', auth, requireAgency, updateReportStatus);
router.patch('/reports/:id/resolve', auth, requireAgency, resolveReport);
router.patch('/reports/:id/escalate', auth, requireAgency, escalateReport);
router.patch('/reports/:id/dismiss', auth, requireAgency, dismissReport);

module.exports = router;
