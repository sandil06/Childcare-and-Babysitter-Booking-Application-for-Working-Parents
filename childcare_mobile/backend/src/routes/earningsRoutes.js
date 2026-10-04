const router = require('express').Router();
const earningsController = require('../controllers/earningsController');
const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');
const ROLES = require('../constants/roles');

router.get('/me', authMiddleware, roleMiddleware(ROLES.BABYSITTER), earningsController.getMeEarnings);
router.get('/me/history', authMiddleware, roleMiddleware(ROLES.BABYSITTER), earningsController.getMeEarningsHistory);
router.post('/me/payout', authMiddleware, roleMiddleware(ROLES.BABYSITTER), earningsController.requestPayout);

module.exports = router;
