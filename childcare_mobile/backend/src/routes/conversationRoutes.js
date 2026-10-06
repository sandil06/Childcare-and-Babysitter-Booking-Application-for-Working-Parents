const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const conversationController = require('../controllers/conversationController');

router.get('/', auth, conversationController.list);
router.post('/', auth, conversationController.getOrCreate);
router.get('/:id/messages', auth, conversationController.getMessages);
router.post('/:id/messages', auth, conversationController.sendMessage);
router.patch('/:id/read', auth, conversationController.markAsRead);

module.exports = router;
