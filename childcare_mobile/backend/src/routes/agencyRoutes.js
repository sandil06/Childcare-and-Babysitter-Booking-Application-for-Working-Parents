const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { dashboard } = require('../controllers/agencyController');
router.get('/dashboard', auth, dashboard);
module.exports = router;
