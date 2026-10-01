const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { create } = require('../controllers/paymentController');
router.post('/', auth, create);
module.exports = router;
