const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const app = require('../src/app');

test('Phone Number Validation: exactly 10 digits and digits only', async (t) => {
  const rand = Math.floor(100000 + Math.random() * 900000);

  await t.test('1. Reject phone number with fewer than 10 digits', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'Short Phone User',
        email: `shortphone${rand}@example.com`,
        phone: '07712345', // 8 digits
        password: 'Password123!',
        role: 'parent',
      });
    assert.equal(res.status, 400);
    assert.match(res.body.message || '', /10 digits/i);
  });

  await t.test('2. Reject phone number with more than 10 digits', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'Long Phone User',
        email: `longphone${rand}@example.com`,
        phone: '0771234567890', // 13 digits
        password: 'Password123!',
        role: 'parent',
      });
    assert.equal(res.status, 400);
    assert.match(res.body.message || '', /10 digits/i);
  });

  await t.test('3. Reject phone number with letters/invalid characters', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'Letter Phone User',
        email: `letterphone${rand}@example.com`,
        phone: '077123abcd',
        password: 'Password123!',
        role: 'parent',
      });
    assert.equal(res.status, 400);
    assert.match(res.body.message || '', /10 digits/i);
  });

  await t.test('4. Accept valid 10-digit phone number', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'Valid Phone User',
        email: `validphone${rand}@example.com`,
        phone: '0771234567', // 10 digits
        password: 'Password123!',
        role: 'parent',
      });
    assert.equal(res.status, 201);
    assert.equal(res.body.data.user.phone, '0771234567');
  });
});
