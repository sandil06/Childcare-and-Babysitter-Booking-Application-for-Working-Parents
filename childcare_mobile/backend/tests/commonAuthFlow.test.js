const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const express = require('express');
const bcrypt = require('bcryptjs');
const authRoutes = require('../src/routes/authRoutes');
const { errorMiddleware } = require('../src/middleware/errorMiddleware');
const ROLES = require('../src/constants/roles');

test('Common Authentication Flow: Single entry point, role resolution & anti-spoofing', async () => {
  const app = express();
  app.use(express.json());
  app.use('/api/v1/auth', authRoutes);
  app.use(errorMiddleware);

  // 1. Missing credentials returns 422 or 400 validation error
  const missingRes = await request(app)
    .post('/api/v1/auth/login')
    .send({ email: '' });
  assert.ok([400, 422].includes(missingRes.status));

  // 2. Common login as Agency via identifier
  const agencyLoginRes = await request(app)
    .post('/api/v1/auth/login')
    .send({
      email: 'agency@littlehands.lk',
      password: 'AnyPassword123!',
    });
  assert.equal(agencyLoginRes.status, 200);
  assert.equal(agencyLoginRes.body.success, true);
  assert.equal(agencyLoginRes.body.data.user.role, ROLES.AGENCY);
  assert.ok(agencyLoginRes.body.data.token);
  assert.equal(agencyLoginRes.body.data.user.passwordHash, undefined);
  assert.equal(agencyLoginRes.body.data.user.password, undefined);

  // 3. Client Role Spoofing Prevention:
  // Client attempts to send role: "admin" for a parent login.
  // The backend MUST ignore client-supplied role.
  const spoofAttemptRes = await request(app)
    .post('/api/v1/auth/login')
    .send({
      email: 'parent.test@gmail.com',
      password: 'ParentPassword123!',
      role: 'admin', // attacker tries to inject admin role
    });
  assert.equal(spoofAttemptRes.status, 200);
  assert.equal(spoofAttemptRes.body.data.user.role, ROLES.PARENT);
  assert.notEqual(spoofAttemptRes.body.data.user.role, 'admin');

  // 4. Session Validation via GET /api/v1/auth/me
  const token = agencyLoginRes.body.data.token;
  const meRes = await request(app)
    .get('/api/v1/auth/me')
    .set('Authorization', `Bearer ${token}`);
  assert.equal(meRes.status, 200);
  assert.equal(meRes.body.success, true);
  assert.equal(meRes.body.data.user.role, ROLES.AGENCY);
  assert.equal(meRes.body.data.user.passwordHash, undefined);

  // 5. Babysitter login via common login endpoint
  const sitterLoginRes = await request(app)
    .post('/api/v1/auth/login')
    .send({
      email: 'sitter.anusha@gmail.com',
      password: 'SitterPassword123!',
    });
  assert.equal(sitterLoginRes.status, 200);
  assert.equal(sitterLoginRes.body.data.user.role, ROLES.BABYSITTER);
});
