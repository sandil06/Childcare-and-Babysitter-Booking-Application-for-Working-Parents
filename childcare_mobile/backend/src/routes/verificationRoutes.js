const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');
const ROLES = require('../constants/roles');
const verificationController = require('../controllers/verificationController');

const requireAgency = roleMiddleware(ROLES.AGENCY, ROLES.ADMIN);

// Babysitter self-service verification submission & status check
router.post('/submit', auth, verificationController.submitVerification);
router.get('/my-status', auth, verificationController.getMyVerificationStatus);

// Administrative verification review and approval workflows
router.get('/', auth, requireAgency, verificationController.list);
router.get('/:id', auth, requireAgency, verificationController.getById);
router.patch('/:id/approve', auth, requireAgency, verificationController.approve);
router.patch('/:id/reject', auth, requireAgency, verificationController.reject);
router.patch('/:id/request-changes', auth, requireAgency, verificationController.requestChanges);

module.exports = router;
