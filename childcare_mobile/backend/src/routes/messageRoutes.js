const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const messageController = require('../controllers/messageController');

router.get('/conversations', auth, messageController.getConversations);
router.get('/:conversationId', auth, messageController.getMessages);
router.post('/', auth, messageController.sendMessage);
router.get('/', auth, messageController.getConversations);

module.exports = router;
