const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { list, create } = require('../controllers/messageController');
router.get('/', auth, list);
router.post('/', auth, create);
module.exports = router;
