const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { locations } = require('../controllers/trackingController');
router.get('/:bookingId', auth, locations);
module.exports = router;
