const router = require('express').Router();
const {
  register,
  login,
  me,
  sendVerification,
  verifyEmailCode,
} = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');
const validationMiddleware = require('../middleware/validationMiddleware');
const { registerValidator, loginValidator } = require('../validators/authValidator');

router.post('/send-verification', sendVerification);
router.post('/send-otp', sendVerification);
router.post('/verify-code', verifyEmailCode);
router.post('/register', registerValidator, validationMiddleware, register);
router.post('/login', loginValidator, validationMiddleware, login);
router.get('/me', authMiddleware, me);

module.exports = router;
