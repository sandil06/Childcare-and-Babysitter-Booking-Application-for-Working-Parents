const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const app = require('../src/app');
const generateToken = require('../src/utils/generateToken');
const ROLES = require('../src/constants/roles');

test('Booking Reschedule & Cancellation Flow and Avatar Upload', async () => {
  const ts = Date.now();
  const parentId = `p_test_${ts}`;
  const sitterId = `s_test_${ts}`;

  const parentToken = generateToken({
    _id: parentId,
    id: parentId,
    email: `parent_${ts}@test.com`,
    role: ROLES.PARENT,
  });

  const sitterToken = generateToken({
    _id: sitterId,
    id: sitterId,
    email: `sitter_${ts}@test.com`,
    role: ROLES.BABYSITTER,
  });

  // 1. Avatar upload for Parent (via JSON imageUrl)
  const avatarRes = await request(app)
    .post('/api/v1/auth/avatar')
    .set('Authorization', `Bearer ${parentToken}`)
    .send({ imageUrl: 'https://images.unsplash.com/photo-parent.jpg' });

  assert.equal(avatarRes.status, 200);
  assert.equal(avatarRes.body.success, true);
  assert.equal(avatarRes.body.data.avatarUrl, 'https://images.unsplash.com/photo-parent.jpg');

  // 2. Create a booking
  const createRes = await request(app)
    .post('/api/v1/bookings')
    .set('Authorization', `Bearer ${parentToken}`)
    .send({
      parent: parentId,
      babysitter: sitterId,
      date: '2026-11-20',
      startTime: '10:00',
      endTime: '14:00',
      location: 'No. 12, Galle Face, Colombo',
      children: [{ name: 'Nethmi', age: 4 }],
    });

  assert.equal(createRes.status, 201);
  const booking = createRes.body.data;
  const bookingId = booking._id || booking.id;
  assert.ok(bookingId);

  // 3. Reschedule booking with invalid times (endTime <= startTime) -> 400
  const invalidTimeRes = await request(app)
    .patch(`/api/v1/bookings/${bookingId}/reschedule`)
    .set('Authorization', `Bearer ${parentToken}`)
    .send({
      date: '2026-11-21',
      startTime: '15:00',
      endTime: '12:00',
    });

  assert.equal(invalidTimeRes.status, 400);

  // 4. Reschedule booking successfully
  const validRescheduleRes = await request(app)
    .patch(`/api/v1/bookings/${bookingId}/reschedule`)
    .set('Authorization', `Bearer ${parentToken}`)
    .send({
      date: '2026-11-21',
      startTime: '11:00',
      endTime: '16:00',
      reason: 'Doctor appointment moved',
    });

  assert.equal(validRescheduleRes.status, 200);
  assert.equal(validRescheduleRes.body.success, true);
  assert.equal(validRescheduleRes.body.data.startTime, '11:00');
  assert.equal(validRescheduleRes.body.data.endTime, '16:00');
  assert.equal(validRescheduleRes.body.data.durationHours || validRescheduleRes.body.data.hours, 5);

  // 5. Unauthorized cancel attempt (another user) -> 403
  const strangerToken = generateToken({
    _id: `stranger_${ts}`,
    id: `stranger_${ts}`,
    email: `stranger_${ts}@test.com`,
    role: ROLES.PARENT,
  });
  const unauthCancelRes = await request(app)
    .patch(`/api/v1/bookings/${bookingId}/cancel`)
    .set('Authorization', `Bearer ${strangerToken}`)
    .send({ reason: 'Malicious cancel' });

  assert.equal(unauthCancelRes.status, 403);

  // 6. Authorized cancel attempt by Parent
  const cancelRes = await request(app)
    .patch(`/api/v1/bookings/${bookingId}/cancel`)
    .set('Authorization', `Bearer ${parentToken}`)
    .send({ reason: 'Family emergency' });

  assert.equal(cancelRes.status, 200);
  assert.equal(cancelRes.body.success, true);
  assert.equal(cancelRes.body.data.status, 'cancelled');
  assert.equal(cancelRes.body.data.cancellationReason, 'Family emergency');

  // 7. Trying to cancel already cancelled booking -> 400
  const reCancelRes = await request(app)
    .patch(`/api/v1/bookings/${bookingId}/cancel`)
    .set('Authorization', `Bearer ${parentToken}`)
    .send({ reason: 'Repeat cancel' });

  assert.equal(reCancelRes.status, 400);

  // 8. Trying to reschedule cancelled booking -> 400
  const rescheduleCancelledRes = await request(app)
    .patch(`/api/v1/bookings/${bookingId}/reschedule`)
    .set('Authorization', `Bearer ${parentToken}`)
    .send({
      date: '2026-11-22',
      startTime: '10:00',
      endTime: '12:00',
    });

  assert.equal(rescheduleCancelledRes.status, 400);
});
