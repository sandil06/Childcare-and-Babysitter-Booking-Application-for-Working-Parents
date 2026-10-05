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
        req.write(JSON.stringify(options.body));
      }
      req.end();
    });
  });
}

test('Booking Engine API: price calculation, creation, conflict check, and status flow', async () => {
  const ts = Date.now();
  const sitterEmail = `sitter_engine_${ts}@example.com`;
  const parentEmail = `parent_engine_${ts}@example.com`;

  // 1. Register Babysitter
  const regSitterRes = await makeRequest('/api/v1/auth/register', {
    method: 'POST',
    body: {
      name: 'Amaya Fernando',
      email: sitterEmail,
      phone: `+9477${Math.floor(1000000 + Math.random() * 9000000)}`,
      password: 'SecurePassword123!',
      role: 'babysitter',
    },
  });
  assert.equal(regSitterRes.status, 201);
  const sitterToken = regSitterRes.body.data.token;
  const sitterUser = regSitterRes.body.data.user;
  const sitterAuth = { Authorization: `Bearer ${sitterToken}` };
  const sitterId = sitterUser._id || sitterUser.id;

  // 2. Register Parent
  const regParentRes = await makeRequest('/api/v1/auth/register', {
    method: 'POST',
    body: {
      name: 'Kavindu Perera',
      email: parentEmail,
      phone: `+9471${Math.floor(1000000 + Math.random() * 9000000)}`,
      password: 'SecurePassword123!',
      role: 'parent',
    },
  });
  assert.equal(regParentRes.status, 201);
  const parentToken = regParentRes.body.data.token;
  const parentUser = regParentRes.body.data.user;
  const parentAuth = { Authorization: `Bearer ${parentToken}` };
  const parentId = parentUser._id || parentUser.id;

  // 3. POST /api/v1/bookings/calculate-price
  const priceRes = await makeRequest('/api/v1/bookings/calculate-price', {
    method: 'POST',
    headers: parentAuth,
    body: {
      babysitterId: sitterId,
      date: '2026-10-15',
      startTime: '09:00',
      endTime: '13:00',
    },
  });
  assert.equal(priceRes.status, 200);
  assert.equal(priceRes.body.success, true);
  assert.equal(priceRes.body.data.duration, 4);
  assert.ok(priceRes.body.data.hourlyRate > 0);
  assert.equal(priceRes.body.data.subtotal, priceRes.body.data.duration * priceRes.body.data.hourlyRate);
  assert.equal(priceRes.body.data.totalAmount, priceRes.body.data.subtotal + priceRes.body.data.serviceFee);

  // 4. POST /api/v1/bookings: Create Booking 1
  const createRes1 = await makeRequest('/api/v1/bookings', {
    method: 'POST',
    headers: parentAuth,
    body: {
      parent: parentId,
      babysitter: sitterId,
      date: '2026-10-15',
      startTime: '09:00',
      endTime: '13:00',
      location: 'No. 45, Flower Road, Colombo 07',
      children: [{ name: 'Senuk', age: 3, gender: 'Male' }],
      specialNotes: 'Allergic to peanuts.',
    },
  });
  assert.equal(createRes1.status, 201);
  const booking1 = createRes1.body.data;
  const booking1Id = booking1._id || booking1.id;
  assert.ok(booking1Id);
  assert.equal(booking1.status, 'pending');
  assert.equal(booking1.durationHours, 4);

  // 5. Conflict Validation: Attempt to book overlapping time slot (e.g. 10:00 - 12:00 on same day)
  const conflictRes = await makeRequest('/api/v1/bookings', {
    method: 'POST',
    headers: parentAuth,
    body: {
      parent: parentId,
      babysitter: sitterId,
      date: '2026-10-15',
      startTime: '10:00',
      endTime: '12:00',
      location: 'No. 10, Galle Road, Colombo 03',
    },
  });
  assert.equal(conflictRes.status, 400, 'Conflicting booking time slot must be rejected');

  // 6. Valid Status Transition: Accept Booking 1
  const acceptRes = await makeRequest(`/api/v1/bookings/${booking1Id}/accept`, {
    method: 'PATCH',
    headers: sitterAuth,
  });
  assert.equal(acceptRes.status, 200);
  assert.equal(acceptRes.body.data.status, 'accepted');

  // 7. Invalid Status Transition: Cannot jump from accepted to completed directly
  const invalidTransitionRes = await makeRequest(`/api/v1/bookings/${booking1Id}/status`, {
    method: 'PATCH',
    headers: sitterAuth,
    body: { status: 'completed' },
  });
  assert.equal(invalidTransitionRes.status, 400, 'Invalid status transition must return 400');
});
