const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { getProfile, updateProfile } = require('../controllers/parentController');

router.get('/profile', auth, getProfile);
router.patch('/profile', auth, updateProfile);

module.exports = router;
