const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { create, getMyReports } = require('../controllers/reportController');

router.post('/', auth, create);
router.get('/my', auth, getMyReports);

module.exports = router;
