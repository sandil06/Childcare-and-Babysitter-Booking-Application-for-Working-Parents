const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');
const ROLES = require('../constants/roles');
const { getDashboard } = require('../controllers/agencyController');
const verificationController = require('../controllers/verificationController');

// All agency endpoints require authenticated agency or admin role
const requireAgency = roleMiddleware(ROLES.AGENCY, ROLES.ADMIN);

// Dashboard
router.get('/dashboard', auth, requireAgency, getDashboard);

// Verifications
router.get('/verifications', auth, requireAgency, verificationController.list);
router.get('/verifications/:id', auth, requireAgency, verificationController.getById);
router.patch('/verifications/:id/approve', auth, requireAgency, verificationController.approve);
router.patch('/verifications/:id/reject', auth, requireAgency, verificationController.reject);
router.patch('/verifications/:id/request-changes', auth, requireAgency, verificationController.requestChanges);

module.exports = router;
