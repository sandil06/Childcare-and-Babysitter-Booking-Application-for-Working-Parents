const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const app = require('../src/app');

function makeRequest(path, options = {}) {
  return new Promise((resolve, reject) => {
    const server = app.listen(0, () => {
      const port = server.address().port;
      const headers = {
        'Content-Type': 'application/json',
        ...(options.headers || {}),
      };
      const req = http.request(
        `http://127.0.0.1:${port}${path}`,
        { ...options, headers },
        (response) => {
          let body = '';
          response.on('data', (chunk) => {
            body += chunk;
          });
          response.on('end', () => {
            server.close();
            try {
              resolve({
                status: response.statusCode,
                body: body ? JSON.parse(body) : null,
              });
            } catch {
              resolve({ status: response.statusCode, body });
            }
          });
        }
      );
      req.on('error', (err) => {
        server.close();
        reject(err);
      });
      if (options.body) {
        req.write(typeof options.body === 'string' ? options.body : JSON.stringify(options.body));
      }
      req.end();
    });
  });
}

test('Stripe Sandbox Payment flow: create PaymentIntent, confirm payment, receipt generation, and webhook', async () => {
  const ts = Date.now();
  const parentEmail = `stripe_parent_${ts}@example.com`;
  const sitterEmail = `stripe_sitter_${ts}@example.com`;

  // 1. Register Parent
  const parentRes = await makeRequest('/api/v1/auth/register', {
    method: 'POST',
    body: {
      name: 'Chamari Silva',
      email: parentEmail,
      phone: `+9477${Math.floor(1000000 + Math.random() * 9000000)}`,
      password: 'ParentSecure123!',
      role: 'parent',
    },
  });
  assert.equal(parentRes.status, 201);
  const parentToken = parentRes.body.data.token;
  const parentId = parentRes.body.data.user.id;

  // 2. Register Sitter
  const sitterRes = await makeRequest('/api/v1/auth/register', {
    method: 'POST',
    body: {
      name: 'Nadeeka Perera',
      email: sitterEmail,
      phone: `+9477${Math.floor(1000000 + Math.random() * 9000000)}`,
      password: 'SitterSecure123!',
      role: 'babysitter',
    },
  });
  assert.equal(sitterRes.status, 201);
  const sitterId = sitterRes.body.data.user.id;

  // 3. Create a Booking for payment
  const bookingRes = await makeRequest('/api/v1/bookings', {
    method: 'POST',
    headers: { Authorization: `Bearer ${parentToken}` },
    body: {
      babysitterId: sitterId,
      date: '2026-10-18',
      startTime: '09:00',
      endTime: '13:00',
      hourlyRate: 1500,
      location: '123 Havelock Road, Colombo 05',
      children: [{ name: 'Senuka', age: 4 }],
      specialNotes: 'Needs morning activities assistance',
    },
  });
  assert.equal(bookingRes.status, 201);
  const booking = bookingRes.body.data;
  const bookingId = booking.id || booking._id;
  assert.equal(booking.paymentStatus, 'pending');
  assert.equal(booking.totalAmount, 6000);

  // 4. Create Stripe PaymentIntent
  const intentRes = await makeRequest('/api/v1/payments/create-intent', {
    method: 'POST',
    headers: { Authorization: `Bearer ${parentToken}` },
    body: { bookingId },
  });
  assert.equal(intentRes.status, 200);
  assert.ok(intentRes.body.data.clientSecret, 'Should return clientSecret');
  assert.ok(intentRes.body.data.paymentIntentId, 'Should return paymentIntentId');
  assert.equal(intentRes.body.data.amount, 6000);
  assert.equal(intentRes.body.data.currency, 'lkr');
  const paymentIntentId = intentRes.body.data.paymentIntentId;

  // 5. Confirm Payment (simulating successful client charge in test mode)
  const confirmRes = await makeRequest('/api/v1/payments/confirm', {
    method: 'POST',
    headers: { Authorization: `Bearer ${parentToken}` },
    body: {
      bookingId,
      paymentIntentId,
    },
  });
  assert.equal(confirmRes.status, 200);
  assert.equal(confirmRes.body.data.payment.status, 'succeeded');
  assert.equal(confirmRes.body.data.booking.paymentStatus, 'paid');
  assert.equal(confirmRes.body.data.booking.status, 'confirmed');

  // 6. Verify duplicate payment attempt is rejected
  const dupIntentRes = await makeRequest('/api/v1/payments/create-intent', {
    method: 'POST',
    headers: { Authorization: `Bearer ${parentToken}` },
    body: { bookingId },
  });
  assert.equal(dupIntentRes.status, 400);

  // 7. Get Payment details by bookingId
  const getPayRes = await makeRequest(`/api/v1/payments/booking/${bookingId}`, {
    method: 'GET',
    headers: { Authorization: `Bearer ${parentToken}` },
  });
  assert.equal(getPayRes.status, 200);
  assert.equal(getPayRes.body.data.status, 'succeeded');

  // 8. Get Payment Receipt
  const receiptRes = await makeRequest(`/api/v1/payments/receipt/${paymentIntentId}`, {
    method: 'GET',
    headers: { Authorization: `Bearer ${parentToken}` },
  });
  assert.equal(receiptRes.status, 200);
  const receipt = receiptRes.body.data;
  assert.equal(receipt.totalAmount, 6000);
  assert.equal(receipt.provider, 'stripe');
  assert.equal(receipt.paymentStatus, 'succeeded');
  assert.ok(receipt.receiptId);
  assert.ok(receipt.transactionId);
  assert.equal(receipt.parentName, 'Chamari Silva');

  // 9. Webhook handler: payment_intent.succeeded
  const webhookRes = await makeRequest('/api/v1/payments/webhook', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: {
      type: 'payment_intent.succeeded',
      data: {
        object: {
          id: paymentIntentId,
          amount: 600000,
          currency: 'lkr',
        },
      },
    },
  });
  assert.equal(webhookRes.status, 200);
  assert.equal(webhookRes.body.received, true);
});
