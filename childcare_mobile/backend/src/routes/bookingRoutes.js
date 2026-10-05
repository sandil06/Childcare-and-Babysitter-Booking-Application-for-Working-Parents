const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const validation = require('../middleware/validationMiddleware');
const { bookingValidator } = require('../validators/bookingValidator');
const bookingController = require('../controllers/bookingController');

router.post('/calculate-price', auth, bookingController.calculatePrice);
router.get('/', auth, bookingController.list);
router.post('/', auth, bookingValidator, validation, bookingController.create);
router.get('/:id', auth, bookingController.getById);
router.patch('/:id/accept', auth, bookingController.accept);
router.patch('/:id/reject', auth, bookingController.reject);
router.patch('/:id/status', auth, bookingController.updateStatus);
router.patch('/:id/cancel', auth, bookingController.cancel);
router.patch('/:id/reschedule', auth, bookingController.reschedule);

module.exports = router;

