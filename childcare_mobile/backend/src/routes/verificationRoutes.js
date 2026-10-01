const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { list } = require('../controllers/verificationController');
router.get('/', auth, list);
module.exports = router;
