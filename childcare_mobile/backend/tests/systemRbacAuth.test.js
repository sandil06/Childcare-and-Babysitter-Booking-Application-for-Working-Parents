const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const express = require('express');
const authMiddleware = require('../src/middleware/authMiddleware');
const roleMiddleware = require('../src/middleware/roleMiddleware');
const { errorMiddleware } = require('../src/middleware/errorMiddleware');
const generateToken = require('../src/utils/generateToken');
const ROLES = require('../src/constants/roles');

test('RBAC & Auth Hardening: missing/invalid tokens, role guards, and suspended accounts', async () => {
  const app = express();
  app.use(express.json());

  // Agency only protected endpoint
  app.get(
    '/api/v1/protected/agency-only',
    authMiddleware,
    roleMiddleware(ROLES.AGENCY),
    (req, res) => res.json({ success: true, message: 'Agency granted' })
  );

  // Parent or Babysitter protected endpoint
  app.get(
    '/api/v1/protected/parent-or-sitter',
    authMiddleware,
    roleMiddleware(ROLES.PARENT, ROLES.BABYSITTER),
    (req, res) => res.json({ success: true, message: 'Parent or sitter granted' })
  );

  app.use(errorMiddleware);

  // 1. Missing Authorization header
  const res1 = await request(app).get('/api/v1/protected/agency-only');
  assert.equal(res1.status, 401);
  assert.equal(res1.body.success, false);

  // 2. Malformed Authorization header
  const res2 = await request(app)
    .get('/api/v1/protected/agency-only')
    .set('Authorization', 'InvalidTokenString');
  assert.equal(res2.status, 401);

  // 3. Suspended user token
  const suspendedUser = {
    _id: 'user-susp',
    id: 'user-susp',
    email: 'suspended@test.com',
    role: ROLES.AGENCY,
    accountStatus: 'suspended',
  };
  const suspendedToken = generateToken(suspendedUser);
  const res3 = await request(app)
    .get('/api/v1/protected/agency-only')
    .set('Authorization', `Bearer ${suspendedToken}`);
  assert.equal(res3.status, 403);
  assert.ok(res3.body.message.includes('suspended'));

  // 4. Role mismatch: Parent accessing agency-only route
  const parentUser = {
    _id: 'user-parent',
    id: 'user-parent',
    email: 'parent@test.com',
    role: ROLES.PARENT,
  };
  const parentToken = generateToken(parentUser);
  const res4 = await request(app)
    .get('/api/v1/protected/agency-only')
    .set('Authorization', `Bearer ${parentToken}`);
  assert.equal(res4.status, 403);
  assert.ok(res4.body.message.includes('Access denied'));

  // 5. Authorized Agency user accessing agency-only route
  const agencyUser = {
    _id: 'user-agency',
    id: 'user-agency',
    email: 'agency@test.com',
    role: ROLES.AGENCY,
  };
  const agencyToken = generateToken(agencyUser);
  const res5 = await request(app)
    .get('/api/v1/protected/agency-only')
    .set('Authorization', `Bearer ${agencyToken}`);
  assert.equal(res5.status, 200);
  assert.equal(res5.body.success, true);
  assert.equal(res5.body.message, 'Agency granted');

  // 6. Super Admin override on agency-only route
  const adminUser = {
    _id: 'user-admin',
    id: 'user-admin',
    email: 'admin@test.com',
    role: ROLES.ADMIN,
  };
  const adminToken = generateToken(adminUser);
  const res6 = await request(app)
    .get('/api/v1/protected/agency-only')
    .set('Authorization', `Bearer ${adminToken}`);
  assert.equal(res6.status, 200);
  assert.equal(res6.body.success, true);

  // 7. Parent accessing parent-or-sitter route
  const res7 = await request(app)
    .get('/api/v1/protected/parent-or-sitter')
    .set('Authorization', `Bearer ${parentToken}`);
  assert.equal(res7.status, 200);
  assert.equal(res7.body.success, true);
});
