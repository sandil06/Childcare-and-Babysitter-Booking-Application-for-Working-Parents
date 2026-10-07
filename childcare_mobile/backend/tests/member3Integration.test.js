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

test('Member 3 Full E2E Flow: Booking, Stripe Payment, Chat, Tracking, and Lifecycle Transitions', async () => {
  const ts = Date.now();
  const parentEmail = `m3_parent_${ts}@example.com`;
  const sitterEmail = `m3_sitter_${ts}@example.com`;

  // 1. Register Parent
  const parentRes = await makeRequest('/api/v1/auth/register', {
    method: 'POST',
    body: {
      name: 'Nirosha Jayawardena',
      email: parentEmail,
      phone: `+9477${Math.floor(1000000 + Math.random() * 9000000)}`,
      password: 'ParentSecure123!',
      role: 'parent',
    },
  });
  assert.equal(parentRes.status, 201);
  const parentToken = parentRes.body.data.token;
  const parentId = parentRes.body.data.user.id;

  // 2. Register Babysitter
  const sitterRes = await makeRequest('/api/v1/auth/register', {
    method: 'POST',
    body: {
      name: 'Amaya Fernando',
      email: sitterEmail,
      phone: `+9477${Math.floor(1000000 + Math.random() * 9000000)}`,
      password: 'SitterSecure123!',
      role: 'babysitter',
    },
  });
  assert.equal(sitterRes.status, 201);
  const sitterToken = sitterRes.body.data.token;
  const sitterId = sitterRes.body.data.user.id;

  // 3. Price Calculation Endpoint
  const priceRes = await makeRequest('/api/v1/bookings/calculate-price', {
    method: 'POST',
    headers: { Authorization: `Bearer ${parentToken}` },
    body: {
      babysitterId: sitterId,
      date: '2026-10-20',
      startTime: '09:00',
      endTime: '13:00',
    },
  });
  assert.equal(priceRes.status, 200);
  assert.equal(priceRes.body.data.duration, 4);
  assert.equal(priceRes.body.data.subtotal, 6000);
  assert.equal(priceRes.body.data.totalAmount, 6000);

  // 4. Create Booking
  const createBookingRes = await makeRequest('/api/v1/bookings', {
    method: 'POST',
    headers: { Authorization: `Bearer ${parentToken}` },
    body: {
      babysitterId: sitterId,
      date: '2026-10-20',
      startTime: '09:00',
      endTime: '13:00',
      hourlyRate: 1500,
      location: '123 Havelock Road, Colombo 05',
      children: [{ name: 'Kavindu', age: 3, gender: 'male' }],
      specialNotes: 'Needs assistance with morning activities',
    },
  });
  assert.equal(createBookingRes.status, 201);
  const booking = createBookingRes.body.data;
  const bookingId = booking.id || booking._id;
  assert.equal(booking.status, 'pending');
  assert.equal(booking.paymentStatus, 'pending');

  // 5. Stripe Sandbox PaymentIntent Creation
  const intentRes = await makeRequest('/api/v1/payments/create-intent', {
    method: 'POST',
    headers: { Authorization: `Bearer ${parentToken}` },
    body: { bookingId },
  });
  assert.equal(intentRes.status, 200);
  assert.ok(intentRes.body.data.clientSecret);
  const paymentIntentId = intentRes.body.data.paymentIntentId;

  // 6. Confirm Stripe Test Payment
  const confirmPayRes = await makeRequest('/api/v1/payments/confirm', {
    method: 'POST',
    headers: { Authorization: `Bearer ${parentToken}` },
    body: {
      bookingId,
      paymentIntentId,
    },
  });
  assert.equal(confirmPayRes.status, 200);
  assert.equal(confirmPayRes.body.data.payment.status, 'succeeded');
  assert.equal(confirmPayRes.body.data.booking.paymentStatus, 'paid');

  // 7. Verify Payment Receipt Breakdown
  const receiptRes = await makeRequest(`/api/v1/payments/receipt/${paymentIntentId}`, {
    method: 'GET',
    headers: { Authorization: `Bearer ${parentToken}` },
  });
  assert.equal(receiptRes.status, 200);
  assert.equal(receiptRes.body.data.totalAmount, 6000);
  assert.equal(receiptRes.body.data.provider, 'stripe');
  assert.equal(receiptRes.body.data.paymentStatus, 'succeeded');

  // 8. 1-on-1 Chat Flow
  const convRes = await makeRequest('/api/v1/conversations', {
    method: 'POST',
    headers: { Authorization: `Bearer ${parentToken}` },
    body: { recipientId: sitterId, bookingId },
  });
  assert.equal(convRes.status, 200);
  const convId = convRes.body.data._id || convRes.body.data.id;

  const sendMsgRes = await makeRequest(`/api/v1/conversations/${convId}/messages`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${parentToken}` },
    body: { text: 'Hello Amaya! Looking forward to your visit.' },
  });
  assert.equal(sendMsgRes.status, 201);
  assert.equal(sendMsgRes.body.data.text, 'Hello Amaya! Looking forward to your visit.');

  const getMsgsRes = await makeRequest(`/api/v1/conversations/${convId}/messages`, {
    method: 'GET',
    headers: { Authorization: `Bearer ${sitterToken}` },
  });
  assert.equal(getMsgsRes.status, 200);
  assert.equal(getMsgsRes.body.data.length, 1);

  // 9. Live GPS Tracking update
  const trackUpdateRes = await makeRequest(`/api/v1/tracking/booking/${bookingId}/location`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${sitterToken}` },
    body: {
      latitude: 6.8950,
      longitude: 79.8588,
      heading: 25.0,
      speed: 30.0,
      status: 'travelling',
    },
  });
  assert.equal(trackUpdateRes.status, 201);

  const trackGetRes = await makeRequest(`/api/v1/tracking/booking/${bookingId}/location`, {
    method: 'GET',
    headers: { Authorization: `Bearer ${parentToken}` },
  });
  assert.equal(trackGetRes.status, 200);
  assert.equal(trackGetRes.body.data.latitude, 6.8950);

  // 10. Service Progress Lifecycle Transitions
  // confirmed -> travelling
  const travelRes = await makeRequest(`/api/v1/bookings/${bookingId}/status`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${sitterToken}` },
    body: { status: 'travelling' },
  });
  assert.equal(travelRes.status, 200);
  assert.equal(travelRes.body.data.status, 'travelling');

  // travelling -> arrived
  const arrivedRes = await makeRequest(`/api/v1/bookings/${bookingId}/status`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${sitterToken}` },
    body: { status: 'arrived' },
  });
  assert.equal(arrivedRes.status, 200);
  assert.equal(arrivedRes.body.data.status, 'arrived');

  // arrived -> in_progress
  const progressRes = await makeRequest(`/api/v1/bookings/${bookingId}/status`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${sitterToken}` },
    body: { status: 'in_progress' },
  });
  assert.equal(progressRes.status, 200);
  assert.equal(progressRes.body.data.status, 'in_progress');

  // in_progress -> completed
  const completedRes = await makeRequest(`/api/v1/bookings/${bookingId}/status`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${sitterToken}` },
    body: { status: 'completed' },
  });
  assert.equal(completedRes.status, 200);
  assert.equal(completedRes.body.data.status, 'completed');

  // 11. Backend Status Validation: Invalid transition (completed -> accepted) MUST BE REJECTED
  const invalidTransitionRes = await makeRequest(`/api/v1/bookings/${bookingId}/status`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${sitterToken}` },
    body: { status: 'accepted' },
  });
  assert.equal(invalidTransitionRes.status, 400);

  // 12. Notifications check
  const notifRes = await makeRequest('/api/v1/notifications', {
    method: 'GET',
    headers: { Authorization: `Bearer ${parentToken}` },
  });
  assert.equal(notifRes.status, 200);
  assert.ok(Array.isArray(notifRes.body.data));
});
