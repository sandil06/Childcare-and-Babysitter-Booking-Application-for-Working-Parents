const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');
const ROLES = require('../constants/roles');
const { getDashboard } = require('../controllers/agencyController');

// All agency endpoints require authenticated agency or admin role
const requireAgency = roleMiddleware(ROLES.AGENCY, ROLES.ADMIN);

router.get('/dashboard', auth, requireAgency, getDashboard);

module.exports = router;
