const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const app = require('../src/app');
const generateToken = require('../src/utils/generateToken');
const ROLES = require('../src/constants/roles');

test('Agency Statistics: aggregate platform users, bookings, compliance, and revenue metrics', async () => {
  const agencyUser = {
    _id: 'agency-admin-1',
    id: 'agency-admin-1',
    name: 'Executive Analytics Officer',
    email: 'analytics@littlehands.lk',
    role: ROLES.AGENCY,
  };
  const token = generateToken(agencyUser);

  const res = await request(app)
    .get('/api/v1/agency/statistics')
    .set('Authorization', `Bearer ${token}`);

  assert.equal(res.status, 200);
  assert.equal(res.body.success, true);
  assert.ok(res.body.data != null);

  const d = res.body.data;

  // Users metrics
  assert.ok(d.users != null);
  assert.ok(typeof d.users.total === 'number');
  assert.ok(typeof d.users.parents === 'number');
  assert.ok(typeof d.users.babysitters === 'number');

  // Bookings metrics
  assert.ok(d.bookings != null);
  assert.ok(typeof d.bookings.total === 'number');
  assert.ok(typeof d.bookings.completed === 'number');

  // Verifications metrics
  assert.ok(d.verifications != null);
  assert.ok(typeof d.verifications.pending === 'number');

  // Reports metrics
  assert.ok(d.reports != null);
  assert.ok(typeof d.reports.total === 'number');

  // Payments metrics
  assert.ok(d.payments != null);
  assert.ok(typeof d.payments.totalVolume === 'number');
  assert.ok(typeof d.payments.platformRevenue === 'number');
});
