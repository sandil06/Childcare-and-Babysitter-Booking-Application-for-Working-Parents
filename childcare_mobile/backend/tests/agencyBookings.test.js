const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const app = require('../src/app');
const generateToken = require('../src/utils/generateToken');
const ROLES = require('../src/constants/roles');

test('Agency Booking Monitoring: list, filter, and admin emergency cancellation', async () => {
  const agencyUser = {
    _id: 'agency-admin-1',
    id: 'agency-admin-1',
    email: 'admin@littlehands.lk',
    role: ROLES.AGENCY,
  };
  const token = generateToken(agencyUser);

  // 1. List bookings
  const listRes = await request(app)
    .get('/api/v1/agency/bookings?status=all')
    .set('Authorization', `Bearer ${token}`);

  assert.equal(listRes.status, 200);
  assert.equal(listRes.body.success, true);
  assert.ok(Array.isArray(listRes.body.data));
  assert.ok(listRes.body.data.length >= 1);

  // 2. Filter by status
  const confirmedRes = await request(app)
    .get('/api/v1/agency/bookings?status=confirmed')
    .set('Authorization', `Bearer ${token}`);

  assert.equal(confirmedRes.status, 200);
  assert.ok(confirmedRes.body.data.every((b) => b.status === 'confirmed'));

  // 3. Admin cancel without reason should fail
  const badCancel = await request(app)
    .patch('/api/v1/agency/bookings/bk-901/cancel')
    .set('Authorization', `Bearer ${token}`)
    .send({});

  assert.equal(badCancel.status, 400);

  // 4. Admin emergency cancel with reason
  const cancelRes = await request(app)
    .patch('/api/v1/agency/bookings/bk-901/cancel')
    .set('Authorization', `Bearer ${token}`)
    .send({ reason: 'Emergency parent request due to medical evacuation' });

  assert.equal(cancelRes.status, 200);
  assert.equal(cancelRes.body.success, true);
  assert.equal(cancelRes.body.data.status, 'cancelled');
  assert.equal(cancelRes.body.data.cancellationReason, 'Emergency parent request due to medical evacuation');
});
