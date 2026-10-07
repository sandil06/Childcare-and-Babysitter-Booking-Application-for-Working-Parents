const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const app = require('../src/app');
const generateToken = require('../src/utils/generateToken');
const ROLES = require('../src/constants/roles');

test('Agency User Management: list, filter, getById, suspend, and reactivate', async () => {
  const agencyUser = {
    _id: 'agency-admin-1',
    id: 'agency-admin-1',
    email: 'admin@littlehands.lk',
    role: ROLES.AGENCY,
  };
  const token = generateToken(agencyUser);

  // 1. List users
  const listRes = await request(app)
    .get('/api/v1/agency/users?role=all')
    .set('Authorization', `Bearer ${token}`);

  assert.equal(listRes.status, 200);
  assert.equal(listRes.body.success, true);
  assert.ok(Array.isArray(listRes.body.data));
  assert.ok(listRes.body.data.length >= 1);

  // 2. Filter by role=parent
  const parentsRes = await request(app)
    .get('/api/v1/agency/users?role=parent')
    .set('Authorization', `Bearer ${token}`);

  assert.equal(parentsRes.status, 200);
  assert.ok(parentsRes.body.data.every((u) => u.role === 'parent'));

  // 3. Retrieve specific user
  const userRes = await request(app)
    .get('/api/v1/agency/users/u-1')
    .set('Authorization', `Bearer ${token}`);

  assert.equal(userRes.status, 200);
  assert.equal(userRes.body.data.name, 'Dulani Senanayake');

  // 4. Suspend user without reason should fail
  const badSuspend = await request(app)
    .patch('/api/v1/agency/users/u-1/suspend')
    .set('Authorization', `Bearer ${token}`)
    .send({});

  assert.equal(badSuspend.status, 400);

  // 5. Suspend user with valid reason
  const suspendRes = await request(app)
    .patch('/api/v1/agency/users/u-1/suspend')
    .set('Authorization', `Bearer ${token}`)
    .send({ reason: 'Terms of service breach' });

  assert.equal(suspendRes.status, 200);
  assert.equal(suspendRes.body.success, true);
  assert.equal(suspendRes.body.data.accountStatus, 'suspended');
  assert.equal(suspendRes.body.data.isActive, false);

  // 6. Reactivate user
  const reactivateRes = await request(app)
    .patch('/api/v1/agency/users/u-1/reactivate')
    .set('Authorization', `Bearer ${token}`);

  assert.equal(reactivateRes.status, 200);
  assert.equal(reactivateRes.body.success, true);
  assert.equal(reactivateRes.body.data.accountStatus, 'active');
  assert.equal(reactivateRes.body.data.isActive, true);
});
