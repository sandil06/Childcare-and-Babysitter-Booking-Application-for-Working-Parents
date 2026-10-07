const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const {
  locations,
  liveLocationStatus,
  updateLiveLocation,
  updateBookingLocation,
  getBookingLocation,
} = require('../controllers/trackingController');

router.get('/live-location', auth, liveLocationStatus);
router.patch('/live-location', auth, updateLiveLocation);
router.post('/booking/:bookingId/location', auth, updateBookingLocation);
router.get('/booking/:bookingId/location', auth, getBookingLocation);
router.get('/:bookingId', auth, locations);

module.exports = router;
