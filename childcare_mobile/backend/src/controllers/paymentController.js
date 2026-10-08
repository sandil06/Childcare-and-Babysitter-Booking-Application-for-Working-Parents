const mongoose = require('mongoose');
const Payment = require('../models/Payment');
const Booking = require('../models/Booking');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');
const stripeService = require('../services/stripeService');
const { memoryBookings } = require('./bookingController');

// Memory store fallback for payments
const memoryPayments = new Map();

function isDbConnected() {
  return mongoose.connection.readyState === 1;
}

function getUserId(req) {
  return req.user?.sub || req.user?.id;
}

/**
 * POST /api/v1/payments/create-intent
 * Creates a Stripe PaymentIntent for a specific booking
 */
async function createPaymentIntent(req, res, next) {
  try {
    const { bookingId } = req.body;
    if (!bookingId) {
      throw new ApiError(400, 'bookingId is required');
    }

    const userId = getUserId(req);
    let booking = null;

    if (isDbConnected()) {
      booking = await Booking.findById(bookingId).populate('parent babysitter');
      if (!booking) {
        booking = await Booking.findOne({ bookingId }).populate('parent babysitter');
      }
    } else {
      booking = memoryBookings.get(bookingId);
      if (!booking) {
        for (const b of memoryBookings.values()) {
          if (b.bookingId === bookingId || b._id?.toString() === bookingId || b.id === bookingId) {
            booking = b;
            break;
          }
        }
      }
    }

    if (!booking) {
      throw new ApiError(404, 'Booking not found');
    }

    if (booking.paymentStatus === 'paid' || booking.paymentStatus === 'succeeded') {
      throw new ApiError(400, 'This booking has already been paid for');
    }

    let amount = Number(booking.totalAmount || booking.total || 0);
    if (amount <= 0 && booking.durationHours && booking.hourlyRate) {
      amount = Math.round(Number(booking.durationHours) * Number(booking.hourlyRate)) + Number(booking.serviceFee || 0);
    }
    if (amount <= 0) {
      amount = 6000;
    }

    const parentId = booking.parent?._id || booking.parent || userId;
    const babysitterId = booking.babysitter?._id || booking.babysitter;
    const bId = booking._id || booking.id || bookingId;

    const intent = await stripeService.createPaymentIntent({
      amount,
      currency: 'lkr',
      bookingId: bId,
      parentId,
      babysitterId,
      metadata: {
        bookingReference: booking.bookingId || String(bId),
      },
    });

    // Save payment record
    if (isDbConnected()) {
      let paymentRecord = await Payment.findOne({ paymentIntentId: intent.id });
      if (!paymentRecord) {
        paymentRecord = new Payment({
          bookingId: bId,
          parentId,
          babysitterId,
          provider: 'stripe',
          paymentIntentId: intent.id,
          amount,
          currency: intent.currency || 'lkr',
          status: 'pending',
        });
        await paymentRecord.save();
      }

      booking.paymentIntentId = intent.id;
      booking.paymentStatus = 'processing';
      await booking.save();
    } else {
      const paymentId = 'pay-' + Date.now();
      const paymentRecord = {
        _id: paymentId,
        id: paymentId,
        bookingId: bId,
        parentId,
        babysitterId,
        provider: 'stripe',
        paymentIntentId: intent.id,
        amount,
        currency: intent.currency || 'lkr',
        status: 'pending',
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      memoryPayments.set(paymentId, paymentRecord);
      memoryPayments.set(intent.id, paymentRecord);

      booking.paymentIntentId = intent.id;
      booking.paymentStatus = 'processing';
      memoryBookings.set(booking.id || booking._id || bookingId, booking);
    }

    return ApiResponse.success(
      res,
      {
        paymentIntentId: intent.id,
        clientSecret: intent.clientSecret,
        publishableKey: stripeService.getPublishableKey(),
        amount,
        currency: intent.currency || 'lkr',
        bookingId: bId,
        isSandboxMock: intent.isSandboxMock,
      },
      'Payment intent created successfully'
    );
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/v1/payments/confirm
 * Confirms payment status for a booking
 */
async function confirmPayment(req, res, next) {
  try {
    const { paymentIntentId, bookingId } = req.body;
    if (!paymentIntentId && !bookingId) {
      throw new ApiError(400, 'Either paymentIntentId or bookingId is required');
    }

    let booking = null;
    let payment = null;

    if (isDbConnected()) {
      if (paymentIntentId) {
        payment = await Payment.findOne({ paymentIntentId });
      }
      if (bookingId) {
        booking = await Booking.findById(bookingId).populate('parent babysitter');
        if (!booking) {
          booking = await Booking.findOne({ bookingId }).populate('parent babysitter');
        }
      } else if (payment) {
        booking = await Booking.findById(payment.bookingId).populate('parent babysitter');
      }

      if (!booking) {
        throw new ApiError(404, 'Associated booking not found');
      }

      if (!payment) {
        payment = await Payment.findOne({ bookingId: booking._id });
      }

      const now = new Date();
      if (payment) {
        payment.status = 'succeeded';
        payment.paidAt = now;
        await payment.save();
      } else {
        payment = new Payment({
          bookingId: booking._id,
          parentId: booking.parent?._id || booking.parent,
          babysitterId: booking.babysitter?._id || booking.babysitter,
          provider: 'stripe',
          paymentIntentId: paymentIntentId || `pi_test_${Date.now()}`,
          amount: booking.totalAmount || booking.total,
          currency: 'lkr',
          status: 'succeeded',
          paidAt: now,
        });
        await payment.save();
      }

      booking.paymentStatus = 'paid';
      if (['pending', 'accepted'].includes(booking.status)) {
        booking.status = 'confirmed';
      }
      await booking.save();

      return ApiResponse.success(
        res,
        {
          payment,
          booking,
        },
        'Payment confirmed and booking updated'
      );
    }

    // Memory store fallback
    if (paymentIntentId) {
      payment = memoryPayments.get(paymentIntentId);
    }
    if (bookingId) {
      booking = memoryBookings.get(bookingId);
      if (!booking) {
        for (const b of memoryBookings.values()) {
          if (b.bookingId === bookingId || b._id?.toString() === bookingId || b.id === bookingId) {
            booking = b;
            break;
          }
        }
      }
    } else if (payment) {
      booking = memoryBookings.get(payment.bookingId);
    }

    if (!booking) {
      throw new ApiError(404, 'Associated booking not found');
    }

    const now = new Date();
    if (payment) {
      payment.status = 'succeeded';
      payment.paidAt = now;
      payment.updatedAt = now;
    } else {
      const pid = 'pay-' + Date.now();
      payment = {
        _id: pid,
        id: pid,
        bookingId: booking._id || booking.id,
        parentId: booking.parent?._id || booking.parent,
        babysitterId: booking.babysitter?._id || booking.babysitter,
        provider: 'stripe',
        paymentIntentId: paymentIntentId || `pi_test_${Date.now()}`,
        amount: booking.totalAmount || booking.total,
        currency: 'lkr',
        status: 'succeeded',
        paidAt: now,
        createdAt: now,
        updatedAt: now,
      };
      memoryPayments.set(pid, payment);
      memoryPayments.set(payment.paymentIntentId, payment);
    }

    booking.paymentStatus = 'paid';
    if (['pending', 'accepted'].includes(booking.status)) {
      booking.status = 'confirmed';
    }
    memoryBookings.set(booking.id || booking._id || bookingId, booking);

    return ApiResponse.success(
      res,
      {
        payment,
        booking,
      },
      'Payment confirmed and booking updated'
    );
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/v1/payments/booking/:bookingId
 * Retrieves payment information for a specific booking
 */
async function getPaymentByBooking(req, res, next) {
  try {
    const { bookingId } = req.params;

    if (isDbConnected()) {
      let payment = await Payment.findOne({ bookingId }).populate('parentId babysitterId bookingId');
      if (!payment) {
        const booking = await Booking.findOne({ bookingId });
        if (booking) {
          payment = await Payment.findOne({ bookingId: booking._id }).populate('parentId babysitterId bookingId');
        }
      }

      if (!payment) {
        throw new ApiError(404, 'No payment found for this booking');
      }

      return ApiResponse.success(res, payment, 'Payment retrieved');
    }

    // Memory fallback
    let payment = null;
    for (const p of memoryPayments.values()) {
      if (p.bookingId === bookingId) {
        payment = p;
        break;
      }
    }

    if (!payment) {
      throw new ApiError(404, 'No payment found for this booking');
    }

    return ApiResponse.success(res, payment, 'Payment retrieved');
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/v1/payments/receipt/:paymentId
 * Retrieves payment receipt details
 */
async function getReceipt(req, res, next) {
  try {
    const { paymentId } = req.params;
    let payment = null;
    let booking = null;

    if (isDbConnected()) {
      payment = await Payment.findById(paymentId);
      if (!payment) {
        payment = await Payment.findOne({ paymentIntentId: paymentId });
      }

      if (!payment) {
        // Fallback: check if paymentId is a bookingId
        booking = await Booking.findById(paymentId).populate('parent babysitter');
        if (!booking) {
          booking = await Booking.findOne({ bookingId: paymentId }).populate('parent babysitter');
        }
        if (booking) {
          payment = await Payment.findOne({ bookingId: booking._id });
        }
      } else {
        booking = await Booking.findById(payment.bookingId).populate('parent babysitter');
      }

      if (!payment && !booking) {
        throw new ApiError(404, 'Receipt not found');
      }

      const parentName =
        (booking?.parent && typeof booking.parent === 'object' && booking.parent.name)
          ? booking.parent.name
          : (req.user?.name || 'Parent User');
      const sitterName =
        (booking?.babysitter && typeof booking.babysitter === 'object' && booking.babysitter.name)
          ? booking.babysitter.name
          : 'Caregiver';

      const durationHours = Number(booking?.durationHours) > 0 ? Number(booking.durationHours) : 4.0;
      const hourlyRate = Number(booking?.hourlyRate) > 0 ? Number(booking.hourlyRate) : 1500.0;
      const subtotal = Number(booking?.subtotal) > 0 ? Number(booking.subtotal) : Math.round(durationHours * hourlyRate);
      const serviceFee = Number(booking?.serviceFee) || 0;
      const totalAmount = Number(payment?.amount) > 0
        ? Number(payment.amount)
        : (Number(booking?.totalAmount) > 0 ? Number(booking.totalAmount) : (Number(booking?.total) > 0 ? Number(booking.total) : subtotal + serviceFee));

      const receipt = {
        receiptId: payment ? (payment._id || payment.id) : `rcpt-${Date.now()}`,
        transactionId: payment ? payment.paymentIntentId : `pi_test_${Date.now()}`,
        bookingId: booking ? (booking.bookingId || booking._id) : (payment ? payment.bookingId : paymentId),
        parentName,
        babysitterName: sitterName,
        bookingDate: booking?.date || new Date(),
        startTime: booking?.startTime || '09:00 AM',
        endTime: booking?.endTime || '01:00 PM',
        durationHours,
        hourlyRate,
        subtotal,
        serviceFee,
        totalAmount,
        currency: payment?.currency || 'lkr',
        provider: payment?.provider || 'stripe',
        paymentStatus: payment?.status || booking?.paymentStatus || 'succeeded',
        paidAt: payment?.paidAt || new Date(),
      };

      return ApiResponse.success(res, receipt, 'Receipt retrieved successfully');
    }

    // Memory fallback
    payment = memoryPayments.get(paymentId);
    if (!payment) {
      booking = memoryBookings.get(paymentId);
      if (booking) {
        for (const p of memoryPayments.values()) {
          if (p.bookingId === booking._id || p.bookingId === booking.id) {
            payment = p;
            break;
          }
        }
      }
    } else {
      booking = memoryBookings.get(payment.bookingId);
    }

    const parentName =
      (booking?.parent && typeof booking.parent === 'object' && booking.parent.name)
        ? booking.parent.name
        : (req.user?.name || 'Parent User');
    const sitterName =
      (booking?.babysitter && typeof booking.babysitter === 'object' && booking.babysitter.name)
        ? booking.babysitter.name
        : 'Caregiver';

    const durationHours = Number(booking?.durationHours) > 0 ? Number(booking.durationHours) : 4.0;
    const hourlyRate = Number(booking?.hourlyRate) > 0 ? Number(booking.hourlyRate) : 1500.0;
    const subtotal = Number(booking?.subtotal) > 0 ? Number(booking.subtotal) : Math.round(durationHours * hourlyRate);
    const serviceFee = Number(booking?.serviceFee) || 0;
    const totalAmount = Number(payment?.amount) > 0
      ? Number(payment.amount)
      : (Number(booking?.totalAmount) > 0 ? Number(booking.totalAmount) : (Number(booking?.total) > 0 ? Number(booking.total) : subtotal + serviceFee));

    const receipt = {
      receiptId: payment ? (payment._id || payment.id) : `rcpt-${Date.now()}`,
      transactionId: payment ? payment.paymentIntentId : `pi_test_${Date.now()}`,
      bookingId: booking ? (booking.bookingId || booking._id || booking.id) : (payment ? payment.bookingId : paymentId),
      parentName,
      babysitterName: sitterName,
      bookingDate: booking?.date || new Date(),
      startTime: booking?.startTime || '09:00 AM',
      endTime: booking?.endTime || '01:00 PM',
      durationHours,
      hourlyRate,
      subtotal,
      serviceFee,
      totalAmount,
      currency: payment?.currency || 'lkr',
      provider: payment?.provider || 'stripe',
      paymentStatus: payment?.status || booking?.paymentStatus || 'succeeded',
      paidAt: payment?.paidAt || new Date(),
    };

    return ApiResponse.success(res, receipt, 'Receipt retrieved successfully');
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/v1/payments/webhook
 * Handles incoming Stripe webhooks (e.g., payment_intent.succeeded)
 */
async function handleWebhook(req, res, next) {
  try {
    const sig = req.headers['stripe-signature'];
    const payload = req.rawBody || req.body;

    let event;
    try {
      event = stripeService.verifyWebhookSignature(payload, sig, process.env.STRIPE_WEBHOOK_SECRET);
    } catch (err) {
      console.warn('[Webhook] Signature verification failed:', err.message);
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    const eventType = event.type || event.event;

    if (eventType === 'payment_intent.succeeded') {
      const intent = event.data.object;
      const intentId = intent.id;

      if (isDbConnected()) {
        const payment = await Payment.findOne({ paymentIntentId: intentId });
        if (payment) {
          payment.status = 'succeeded';
          payment.paidAt = new Date();
          await payment.save();

          await Booking.findByIdAndUpdate(payment.bookingId, {
            paymentStatus: 'paid',
            status: 'confirmed',
          });
        }
      } else {
        const payment = memoryPayments.get(intentId);
        if (payment) {
          payment.status = 'succeeded';
          payment.paidAt = new Date();
          const booking = memoryBookings.get(payment.bookingId);
          if (booking) {
            booking.paymentStatus = 'paid';
            booking.status = 'confirmed';
          }
        }
      }
    } else if (eventType === 'payment_intent.payment_failed') {
      const intent = event.data.object;
      const intentId = intent.id;

      if (isDbConnected()) {
        const payment = await Payment.findOne({ paymentIntentId: intentId });
        if (payment) {
          payment.status = 'failed';
          await payment.save();

          await Booking.findByIdAndUpdate(payment.bookingId, {
            paymentStatus: 'failed',
          });
        }
      } else {
        const payment = memoryPayments.get(intentId);
        if (payment) {
          payment.status = 'failed';
          const booking = memoryBookings.get(payment.bookingId);
          if (booking) {
            booking.paymentStatus = 'failed';
          }
        }
      }
    }

    return res.status(200).json({ received: true });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  createPaymentIntent,
  confirmPayment,
  getPaymentByBooking,
  getReceipt,
  handleWebhook,
  memoryPayments,
};
