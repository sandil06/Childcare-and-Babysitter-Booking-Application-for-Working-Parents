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

test('Babysitter module CRUD: profile, availability slots, booking lifecycle, earnings, and messages', async () => {
  const ts = Date.now();
  const sitterEmail = `sitter_crud_${ts}@example.com`;
  const parentEmail = `parent_crud_${ts}@example.com`;

  // 1. Register Babysitter
  const regSitterRes = await makeRequest('/api/v1/auth/register', {
    method: 'POST',
    body: {
      name: 'Nadeeka Perera',
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
  assert.ok(sitterToken, 'Sitter token should exist');

  // 2. Register Parent
  const regParentRes = await makeRequest('/api/v1/auth/register', {
    method: 'POST',
    body: {
      name: 'Ruwan Silva',
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

  // 3. Mode switching: Parent can access Babysitter /me without 403 error
  const modeSwitchRes = await makeRequest('/api/v1/babysitters/me', {
    method: 'GET',
    headers: parentAuth,
  });
  assert.equal(modeSwitchRes.status, 200, 'Parent should be able to switch to babysitter mode smoothly');
  assert.equal(modeSwitchRes.body.success, true);
  assert.ok(modeSwitchRes.body.data, 'Auto-created babysitter profile for parent should exist');

  // 4. Babysitter Profile GET & PATCH
  const getMeRes = await makeRequest('/api/v1/babysitters/me', {
    method: 'GET',
    headers: sitterAuth,
  });
  assert.equal(getMeRes.status, 200);
  assert.equal(getMeRes.body.success, true);

  const updateProfileRes = await makeRequest('/api/v1/babysitters/me', {
    method: 'PATCH',
    headers: sitterAuth,
    body: {
      bio: 'Experienced certified early childhood babysitter with CPR training.',
      hourlyRate: 1800.0,
      experienceYears: 5,
      skills: ['Infant care', 'First aid & CPR', 'Creative Arts'],
      languages: ['English', 'Sinhala'],
      address: 'Colombo 07, Sri Lanka',
    },
  });
  assert.equal(updateProfileRes.status, 200);
  assert.equal(updateProfileRes.body.data.bio, 'Experienced certified early childhood babysitter with CPR training.');
  assert.equal(updateProfileRes.body.data.hourlyRate, 1800.0);
  assert.equal(updateProfileRes.body.data.experienceYears, 5);

  // 5. Availability Slots Full CRUD
  const slotDate = new Date(Date.now() + 86400000).toISOString().split('T')[0];

  // 5a. Create slot
  const createSlotRes = await makeRequest('/api/v1/babysitters/me/availability', {
    method: 'POST',
    headers: sitterAuth,
    body: {
      date: slotDate,
      startTime: '09:00',
      endTime: '13:00',
      available: true,
      isRecurring: false,
    },
  });
  assert.equal(createSlotRes.status, 201);
  const createdSlot = createSlotRes.body.data;
  const slotId = createdSlot._id || createdSlot.id;
  assert.ok(slotId, 'Slot ID should exist');
  assert.equal(createdSlot.startTime, '09:00');
  assert.equal(createdSlot.endTime, '13:00');

  // 5b. Overlap validation check (should reject overlapping slot)
  const overlapRes = await makeRequest('/api/v1/babysitters/me/availability', {
    method: 'POST',
    headers: sitterAuth,
    body: {
      date: slotDate,
      startTime: '11:00',
      endTime: '15:00',
      available: true,
    },
  });
  assert.equal(overlapRes.status, 400, 'Overlapping availability slot must be rejected with 400');

  // 5c. Read slots
  const getSlotsRes = await makeRequest('/api/v1/babysitters/me/availability', {
    method: 'GET',
    headers: sitterAuth,
  });
  assert.equal(getSlotsRes.status, 200);
  assert.ok(Array.isArray(getSlotsRes.body.data));
  const hasSlot = getSlotsRes.body.data.some((s) => (s._id || s.id) === slotId);
  assert.ok(hasSlot, 'Created slot should appear in list');

  // 5d. Update slot
  const updateSlotRes = await makeRequest(`/api/v1/availability/${slotId}`, {
    method: 'PATCH',
    headers: sitterAuth,
    body: {
      startTime: '08:30',
      endTime: '12:30',
    },
  });
  assert.equal(updateSlotRes.status, 200);
  assert.equal(updateSlotRes.body.data.startTime, '08:30');
  assert.equal(updateSlotRes.body.data.endTime, '12:30');

  // 5e. Delete slot
  const deleteSlotRes = await makeRequest(`/api/v1/availability/${slotId}`, {
    method: 'DELETE',
    headers: sitterAuth,
  });
  assert.equal(deleteSlotRes.status, 200);

  // Verify deleted
  const getSlotsAfterDel = await makeRequest('/api/v1/babysitters/me/availability', {
    method: 'GET',
    headers: sitterAuth,
  });
  assert.equal(getSlotsAfterDel.status, 200);
  const stillExists = getSlotsAfterDel.body.data.some((s) => (s._id || s.id) === slotId);
  assert.equal(stillExists, false, 'Slot should no longer exist after deletion');

  // 6. Booking Lifecycle & Status Transitions
  // 6a. Parent creates booking for babysitter
  const bookingDate = new Date(Date.now() + 2 * 86400000).toISOString().split('T')[0];
  const sitterId = sitterUser._id || sitterUser.id;
  const parentId = parentUser._id || parentUser.id;

  const createBookingRes = await makeRequest('/api/v1/bookings', {
    method: 'POST',
    headers: parentAuth,
    body: {
      parent: parentId,
      babysitter: sitterId,
      date: bookingDate,
      startTime: '10:00',
      endTime: '14:00',
      durationHours: 4.0,
      hourlyRate: 1800.0,
      total: 7200.0,
      location: 'No. 12, Park Road, Colombo 05',
      children: [{ name: 'Aiden', age: 4, gender: 'Male' }],
      specialNotes: 'Please read storybook before lunch.',
    },
  });
  assert.equal(createBookingRes.status, 201);
  const createdBooking = createBookingRes.body.data;
  const bookingId = createdBooking._id || createdBooking.id;
  assert.ok(bookingId);
  assert.equal(createdBooking.status, 'pending');

  // 6b. Babysitter retrieves new booking requests
  const getRequestsRes = await makeRequest('/api/v1/babysitters/me/booking-requests', {
    method: 'GET',
    headers: sitterAuth,
  });
  assert.equal(getRequestsRes.status, 200);
  const foundRequest = getRequestsRes.body.data.some((b) => (b._id || b.id) === bookingId);
  assert.ok(foundRequest, 'New booking should appear in sitter booking requests');

  // 6c. Babysitter accepts booking
  const acceptRes = await makeRequest(`/api/v1/bookings/${bookingId}/accept`, {
    method: 'PATCH',
    headers: sitterAuth,
  });
  assert.equal(acceptRes.status, 200);
  assert.equal(acceptRes.body.data.status, 'accepted');

  // 6d. Status transition: accepted -> travelling
  const travRes = await makeRequest(`/api/v1/bookings/${bookingId}/status`, {
    method: 'PATCH',
    headers: sitterAuth,
    body: { status: 'travelling' },
  });
  assert.equal(travRes.status, 200);
  assert.equal(travRes.body.data.status, 'travelling');

  // 6e. Status transition: travelling -> arrived
  const arrRes = await makeRequest(`/api/v1/bookings/${bookingId}/status`, {
    method: 'PATCH',
    headers: sitterAuth,
    body: { status: 'arrived' },
  });
  assert.equal(arrRes.status, 200);
  assert.equal(arrRes.body.data.status, 'arrived');

  // 6f. Status transition: arrived -> in_progress
  const progRes = await makeRequest(`/api/v1/bookings/${bookingId}/status`, {
    method: 'PATCH',
    headers: sitterAuth,
    body: { status: 'in_progress' },
  });
  assert.equal(progRes.status, 200);
  assert.equal(progRes.body.data.status, 'in_progress');

  // 6g. Status transition: in_progress -> completed
  const compRes = await makeRequest(`/api/v1/bookings/${bookingId}/status`, {
    method: 'PATCH',
    headers: sitterAuth,
    body: { status: 'completed' },
  });
  assert.equal(compRes.status, 200);
  assert.equal(compRes.body.data.status, 'completed');

  // 7. Earnings & Payout
  const earningsRes = await makeRequest('/api/v1/babysitters/me/earnings', {
    method: 'GET',
    headers: sitterAuth,
  });
  assert.equal(earningsRes.status, 200);
  assert.equal(earningsRes.body.success, true);
  assert.ok(earningsRes.body.data.completedBookings >= 1, 'Should have at least 1 completed booking');
  assert.ok(earningsRes.body.data.totalEarnings > 0, 'Total earnings should be positive');

  const historyRes = await makeRequest('/api/v1/babysitters/me/earnings/history', {
    method: 'GET',
    headers: sitterAuth,
  });
  assert.equal(historyRes.status, 200);
  assert.ok(Array.isArray(historyRes.body.data));
  assert.ok(historyRes.body.data.length >= 1, 'Earnings history should contain completed booking');

  const payoutRes = await makeRequest('/api/v1/babysitters/me/earnings/payout', {
    method: 'POST',
    headers: sitterAuth,
  });
  assert.equal(payoutRes.status, 200);
  assert.ok(payoutRes.body.data.payoutId);
  assert.equal(payoutRes.body.data.status, 'processing');

  // 8. Notifications
  const notifRes = await makeRequest('/api/v1/notifications', {
    method: 'GET',
    headers: sitterAuth,
  });
  assert.equal(notifRes.status, 200);
  assert.ok(Array.isArray(notifRes.body.data));

  const markAllRes = await makeRequest('/api/v1/notifications/read-all', {
    method: 'PATCH',
    headers: sitterAuth,
  });
  assert.equal(markAllRes.status, 200);

  // 9. Messages
  const sendMsgRes = await makeRequest('/api/v1/messages', {
    method: 'POST',
    headers: parentAuth,
    body: {
      recipientId: sitterId,
      text: 'Hello Nadeeka, look forward to seeing you tomorrow!',
    },
  });
  assert.equal(sendMsgRes.status, 201);

  const getConvRes = await makeRequest('/api/v1/messages/conversations', {
    method: 'GET',
    headers: sitterAuth,
  });
  assert.equal(getConvRes.status, 200);
  assert.ok(Array.isArray(getConvRes.body.data));
  assert.ok(getConvRes.body.data.length >= 1);
  const conv = getConvRes.body.data[0];
  assert.ok(conv.parentName, 'Conversation should have parentName');
  assert.ok(conv.parentId, 'Conversation should have parentId');
});
