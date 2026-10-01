const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const validation = require('../middleware/validationMiddleware');
const { reviewValidator } = require('../validators/reviewValidator');
const { create } = require('../controllers/reviewController');
router.post('/', auth, reviewValidator, validation, create);
module.exports = router;
