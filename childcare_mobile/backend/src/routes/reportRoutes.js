const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { create } = require('../controllers/reportController');
router.post('/', auth, create);
module.exports = router;
