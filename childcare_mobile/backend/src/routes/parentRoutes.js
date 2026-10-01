const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { getProfile } = require('../controllers/parentController');
router.get('/profile', auth, getProfile);
module.exports = router;
