const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const {
	locations,
	liveLocationStatus,
	updateLiveLocation,
} = require('../controllers/trackingController');
router.get('/live-location', auth, liveLocationStatus);
router.patch('/live-location', auth, updateLiveLocation);
router.get('/:bookingId', auth, locations);
module.exports = router;
