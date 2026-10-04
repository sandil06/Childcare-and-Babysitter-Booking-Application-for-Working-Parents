const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const app = require('../src/app');

test('POST /api/v1/auth/send-verification generates 6-digit OTP code', async () => {
  const email = `test.parent.${Date.now()}@gmail.com`;
  const res = await request(app)
    .post('/api/v1/auth/send-verification')
    .send({ email, name: 'Ananya' });

  assert.equal(res.status, 200);
  assert.equal(res.body.success, true);
  assert.ok(res.body.data.devCode);
  assert.equal(res.body.data.devCode.length, 6);
  assert.equal(res.body.data.email, email);
});

test('POST /api/v1/auth/verify-code validates OTP code correctly', async () => {
  const email = `test.verify.${Date.now()}@gmail.com`;
  const sendRes = await request(app)
    .post('/api/v1/auth/send-verification')
    .send({ email, name: 'Ananya' });

  const code = sendRes.body.data.devCode;

  // Invalid code fails
  const badRes = await request(app)
    .post('/api/v1/auth/verify-code')
    .send({ email, code: '000000' });
  assert.equal(badRes.status, 400);

  // Correct code succeeds
  const goodRes = await request(app)
    .post('/api/v1/auth/verify-code')
    .send({ email, code });
  assert.equal(goodRes.status, 200);
  assert.equal(goodRes.body.data.verified, true);
});

test('POST /api/v1/auth/register creates user with email verified', async () => {
  const email = `test.registered.${Date.now()}@gmail.com`;
  const sendRes = await request(app)
    .post('/api/v1/auth/send-verification')
    .send({ email, name: 'Kasun Silva' });

  const code = sendRes.body.data.devCode;

  const regRes = await request(app)
    .post('/api/v1/auth/register')
    .send({
      name: 'Kasun Silva',
      email,
      password: 'StrongPassword123!',
      role: 'parent',
      verificationCode: code,
    });

  assert.equal(regRes.status, 201);
  assert.equal(regRes.body.success, true);
  assert.ok(regRes.body.data.user.email);
  assert.equal(regRes.body.data.user.isEmailVerified, true);
  assert.ok(regRes.body.data.token);
});
