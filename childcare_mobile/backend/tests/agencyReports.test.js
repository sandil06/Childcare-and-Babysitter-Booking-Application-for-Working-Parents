const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const app = require('../src/app');
const generateToken = require('../src/utils/generateToken');
const ROLES = require('../src/constants/roles');

test('Agency Reports Management: list, filter, search, resolve, escalate, and dismiss', async () => {
  const agencyUser = {
    _id: 'agency-admin-1',
    id: 'agency-admin-1',
    name: 'Chief Compliance Officer',
    email: 'compliance@littlehands.lk',
    role: ROLES.AGENCY,
  };
  const token = generateToken(agencyUser);

  // 1. List all reports
  const listRes = await request(app)
    .get('/api/v1/agency/reports?status=all')
    .set('Authorization', `Bearer ${token}`);

  assert.equal(listRes.status, 200);
  assert.equal(listRes.body.success, true);
  assert.ok(Array.isArray(listRes.body.data));
  assert.ok(listRes.body.data.length >= 3);

  // 2. Filter by status
  const openRes = await request(app)
    .get('/api/v1/agency/reports?status=open')
    .set('Authorization', `Bearer ${token}`);

  assert.equal(openRes.status, 200);
  assert.ok(openRes.body.data.every((r) => r.status === 'open'));

  // 3. Filter by priority
  const urgentRes = await request(app)
    .get('/api/v1/agency/reports?priority=urgent')
    .set('Authorization', `Bearer ${token}`);

  assert.equal(urgentRes.status, 200);
  assert.ok(urgentRes.body.data.every((r) => r.priority === 'urgent'));

  // 4. Search reports by query
  const searchRes = await request(app)
    .get('/api/v1/agency/reports?search=toddler')
    .set('Authorization', `Bearer ${token}`);

  assert.equal(searchRes.status, 200);
  assert.ok(searchRes.body.data.length >= 1);

  // 5. Get report details by ID
  const detailRes = await request(app)
    .get('/api/v1/agency/reports/rep-401')
    .set('Authorization', `Bearer ${token}`);

  assert.equal(detailRes.status, 200);
  assert.equal(detailRes.body.data._id, 'rep-401');

  // 6. Update report status directly
  const statusRes = await request(app)
    .patch('/api/v1/agency/reports/rep-401/status')
    .set('Authorization', `Bearer ${token}`)
    .send({ status: 'under_review', resolutionNotes: 'Contacting babysitter for explanation' });

  assert.equal(statusRes.status, 200);
  assert.equal(statusRes.body.data.status, 'under_review');

  // 7. Escalate report to urgent
  const escRes = await request(app)
    .patch('/api/v1/agency/reports/rep-402/escalate')
    .set('Authorization', `Bearer ${token}`)
    .send({ notes: 'Escalated by supervisor' });

  assert.equal(escRes.status, 200);
  assert.equal(escRes.body.data.priority, 'urgent');

  // 8. Resolve report
  const resolveRes = await request(app)
    .patch('/api/v1/agency/reports/rep-401/resolve')
    .set('Authorization', `Bearer ${token}`)
    .send({ resolutionNotes: 'Warning issued to sitter. Refund credited to parent.' });

  assert.equal(resolveRes.status, 200);
  assert.equal(resolveRes.body.data.status, 'resolved');
  assert.ok(resolveRes.body.data.resolvedAt != null);

  // 9. Dismiss report
  const dismissRes = await request(app)
    .patch('/api/v1/agency/reports/rep-403/dismiss')
    .set('Authorization', `Bearer ${token}`)
    .send({ reason: 'False alarm after review of camera logs' });

  assert.equal(dismissRes.status, 200);
  assert.equal(dismissRes.body.data.status, 'dismissed');
});
