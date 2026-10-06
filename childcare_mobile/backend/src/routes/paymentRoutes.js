const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const {
  createPaymentIntent,
  confirmPayment,
  getPaymentByBooking,
  getReceipt,
  handleWebhook,
} = require('../controllers/paymentController');

// Stripe payment endpoints
router.post('/create-intent', auth, createPaymentIntent);
router.post('/confirm', auth, confirmPayment);
router.get('/booking/:bookingId', auth, getPaymentByBooking);
router.get('/receipt/:paymentId', auth, getReceipt);
router.post('/webhook', handleWebhook);

module.exports = router;
