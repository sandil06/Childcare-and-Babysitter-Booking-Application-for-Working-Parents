const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const express = require('express');
const ApiResponse = require('../src/utils/ApiResponse');
const ApiError = require('../src/utils/ApiError');
const { errorMiddleware, notFoundMiddleware } = require('../src/middleware/errorMiddleware');

test('System API Standardization: ApiResponse and ErrorMiddleware handling', async () => {
  const app = express();
  app.use(express.json());

  // Test endpoints
  app.get('/test/success', (req, res) => {
    return ApiResponse.success(res, { item: 'Sample Data' }, 'Operation succeeded');
  });

  app.get('/test/paginated', (req, res) => {
    const list = [{ id: 1 }, { id: 2 }];
    return ApiResponse.paginated(res, list, { page: 1, limit: 10, total: 2 }, 'List retrieved');
  });

  app.post('/test/created', (req, res) => {
    return ApiResponse.created(res, { id: 'new-id' }, 'Resource created');
  });

  app.get('/test/api-error', (req, res, next) => {
    next(new ApiError(403, 'Permission denied for this operation', ['ROLE_INSUFFICIENT']));
  });

  app.get('/test/cast-error', (req, res, next) => {
    const err = new Error('Cast to ObjectId failed');
    err.name = 'CastError';
    err.path = 'userId';
    next(err);
  });

  app.get('/test/validation-error', (req, res, next) => {
    const err = new Error('Validation failed');
    err.name = 'ValidationError';
    err.errors = {
      email: { message: 'Email address is invalid' },
      phone: { message: 'Phone number is required' },
    };
    next(err);
  });

  app.get('/test/duplicate-error', (req, res, next) => {
    const err = new Error('E11000 duplicate key');
    err.code = 11000;
    err.keyValue = { email: 'duplicate@test.com' };
    next(err);
  });

  app.use(notFoundMiddleware);
  app.use(errorMiddleware);

  // 1. Success envelope
  const res1 = await request(app).get('/test/success');
  assert.equal(res1.status, 200);
  assert.equal(res1.body.success, true);
  assert.equal(res1.body.message, 'Operation succeeded');
  assert.deepEqual(res1.body.data, { item: 'Sample Data' });

  // 2. Paginated envelope
  const res2 = await request(app).get('/test/paginated');
  assert.equal(res2.status, 200);
  assert.equal(res2.body.success, true);
  assert.equal(res2.body.meta.page, 1);
  assert.equal(res2.body.meta.limit, 10);
  assert.equal(res2.body.meta.total, 2);
  assert.equal(res2.body.meta.totalPages, 1);

  // 3. Created 201
  const res3 = await request(app).post('/test/created');
  assert.equal(res3.status, 201);
  assert.equal(res3.body.success, true);

  // 4. ApiError with details
  const res4 = await request(app).get('/test/api-error');
  assert.equal(res4.status, 403);
  assert.equal(res4.body.success, false);
  assert.equal(res4.body.message, 'Permission denied for this operation');
  assert.deepEqual(res4.body.details, ['ROLE_INSUFFICIENT']);

  // 5. CastError formatted to 400
  const res5 = await request(app).get('/test/cast-error');
  assert.equal(res5.status, 400);
  assert.equal(res5.body.success, false);
  assert.ok(res5.body.message.includes('Invalid resource identifier'));

  // 6. ValidationError formatted to 400
  const res6 = await request(app).get('/test/validation-error');
  assert.equal(res6.status, 400);
  assert.equal(res6.body.success, false);
  assert.ok(res6.body.message.includes('Email address is invalid'));
  assert.ok(Array.isArray(res6.body.details));

  // 7. Duplicate Key 11000 formatted to 409
  const res7 = await request(app).get('/test/duplicate-error');
  assert.equal(res7.status, 409);
  assert.equal(res7.body.success, false);
  assert.ok(res7.body.message.includes('Duplicate value entered'));

  // 8. 404 Route Not Found
  const res8 = await request(app).get('/non-existent-route-path');
  assert.equal(res8.status, 404);
  assert.equal(res8.body.success, false);
  assert.ok(res8.body.message.includes('Route not found'));
});
