const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const validation = require('../middleware/validationMiddleware');
const { bookingValidator } = require('../validators/bookingValidator');
const { list, create } = require('../controllers/bookingController');
router.get('/', auth, list);
router.post('/', auth, bookingValidator, validation, create);
module.exports = router;
