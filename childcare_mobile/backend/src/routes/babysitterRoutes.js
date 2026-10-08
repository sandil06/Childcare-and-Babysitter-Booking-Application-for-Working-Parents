const router = require('express').Router();
const babysitterController = require('../controllers/babysitterController');
const availabilityController = require('../controllers/availabilityController');
const bookingController = require('../controllers/bookingController');
const earningsController = require('../controllers/earningsController');
const { validateRegister, validateUpdate } = require('../validators/babysitterValidator');
const { validateCreate: validateCreateAvailability } = require('../validators/availabilityValidator');
const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');
const ROLES = require('../constants/roles');

// Public routes
router.post('/register', validateRegister, babysitterController.register);
router.get('/', babysitterController.list);

// Authenticated babysitter routes
router.get('/me', authMiddleware, roleMiddleware(ROLES.BABYSITTER), babysitterController.getMe);
router.patch('/me', authMiddleware, roleMiddleware(ROLES.BABYSITTER), validateUpdate, babysitterController.updateMe);
router.get('/me/dashboard', authMiddleware, roleMiddleware(ROLES.BABYSITTER), babysitterController.getDashboard);

// Document management endpoints
router.post('/me/verification-documents', authMiddleware, roleMiddleware(ROLES.BABYSITTER), babysitterController.addDocument);
router.patch('/me/verification-documents/:id', authMiddleware, roleMiddleware(ROLES.BABYSITTER), babysitterController.updateDocument);
router.delete('/me/verification-documents/:id', authMiddleware, roleMiddleware(ROLES.BABYSITTER), babysitterController.deleteDocument);

// Qualification management endpoints
router.post('/me/qualifications', authMiddleware, roleMiddleware(ROLES.BABYSITTER), babysitterController.addQualification);
router.patch('/me/qualifications/:id', authMiddleware, roleMiddleware(ROLES.BABYSITTER), babysitterController.updateQualification);
router.delete('/me/qualifications/:id', authMiddleware, roleMiddleware(ROLES.BABYSITTER), babysitterController.deleteQualification);

// Availability endpoints
router.get('/me/availability', authMiddleware, roleMiddleware(ROLES.BABYSITTER), availabilityController.getMeAvailability);
router.post('/me/availability', authMiddleware, roleMiddleware(ROLES.BABYSITTER), validateCreateAvailability, availabilityController.createMeAvailability);

// Bookings & Requests endpoints
router.get('/me/bookings', authMiddleware, roleMiddleware(ROLES.BABYSITTER), bookingController.getMeBookings);
router.get('/me/booking-requests', authMiddleware, roleMiddleware(ROLES.BABYSITTER), bookingController.getMeBookingRequests);

// Earnings & Statistics endpoints
router.get('/me/earnings', authMiddleware, roleMiddleware(ROLES.BABYSITTER), earningsController.getMeEarnings);
router.get('/me/earnings/history', authMiddleware, roleMiddleware(ROLES.BABYSITTER), earningsController.getMeEarningsHistory);
router.post('/me/earnings/payout', authMiddleware, roleMiddleware(ROLES.BABYSITTER), earningsController.requestPayout);

// Details by ID
router.get('/:id', babysitterController.getById);

module.exports = router;
