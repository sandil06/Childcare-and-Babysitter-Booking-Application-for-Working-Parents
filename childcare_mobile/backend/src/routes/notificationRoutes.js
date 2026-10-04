const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const notificationController = require('../controllers/notificationController');

router.get('/', auth, notificationController.list);
router.patch('/read-all', auth, notificationController.markAllRead);
router.patch('/:id/read', auth, notificationController.markRead);

module.exports = router;
