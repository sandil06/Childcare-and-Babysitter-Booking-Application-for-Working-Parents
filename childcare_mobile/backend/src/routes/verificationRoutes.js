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

// Document-level review endpoints
router.patch('/:verificationId/documents/:documentId/approve', auth, requireAgency, verificationController.approveDocument);
router.patch('/:verificationId/documents/:documentId/reject', auth, requireAgency, verificationController.rejectDocument);
router.patch('/:verificationId/documents/:documentId/request-changes', auth, requireAgency, verificationController.requestChangesDocument);

// Qualification-level review endpoints
router.patch('/:verificationId/qualifications/:qualificationId/approve', auth, requireAgency, verificationController.approveQualification);
router.patch('/:verificationId/qualifications/:qualificationId/reject', auth, requireAgency, verificationController.rejectQualification);
router.patch('/:verificationId/qualifications/:qualificationId/request-changes', auth, requireAgency, verificationController.requestChangesQualification);

module.exports = router;
