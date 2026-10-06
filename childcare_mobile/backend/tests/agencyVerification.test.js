const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const app = require('../src/app');
const generateToken = require('../src/utils/generateToken');
const ROLES = require('../src/constants/roles');

test('Agency Verification Workflow: list, getById, approve, reject, and request-changes', async () => {
  // Agency admin token
  const agencyUser = {
    _id: 'agency-admin-1',
    id: 'agency-admin-1',
    email: 'admin@littlehands.lk',
    role: ROLES.AGENCY,
  };
  const token = generateToken(agencyUser);

  // 1. List verification requests
  const listRes = await request(app)
    .get('/api/v1/agency/verifications?status=all')
    .set('Authorization', `Bearer ${token}`);

  assert.equal(listRes.status, 200);
  assert.equal(listRes.body.success, true);
  assert.ok(Array.isArray(listRes.body.data));
  assert.ok(listRes.body.data.length >= 1);

  // 2. Retrieve verification details
  const detailRes = await request(app)
    .get('/api/v1/agency/verifications/ver-101')
    .set('Authorization', `Bearer ${token}`);

  assert.equal(detailRes.status, 200);
  assert.equal(detailRes.body.success, true);
  assert.equal(detailRes.body.data.id || detailRes.body.data._id, 'ver-101');

  // 3. Request Changes on ver-102
  const changesRes = await request(app)
    .patch('/api/v1/agency/verifications/ver-102/request-changes')
    .set('Authorization', `Bearer ${token}`)
    .send({ notes: 'Please provide high-resolution scan of police certificate' });

  assert.equal(changesRes.status, 200);
  assert.equal(changesRes.body.success, true);
  assert.equal(changesRes.body.data.status, 'changes_requested');

  // 4. Reject ver-102 without reason (should fail)
  const badRejectRes = await request(app)
    .patch('/api/v1/agency/verifications/ver-102/reject')
    .set('Authorization', `Bearer ${token}`)
    .send({});

  assert.equal(badRejectRes.status, 400);

  // 5. Reject ver-102 with reason
  const rejectRes = await request(app)
    .patch('/api/v1/agency/verifications/ver-102/reject')
    .set('Authorization', `Bearer ${token}`)
    .send({ reason: 'Verification documentation is fraudulent' });

  assert.equal(rejectRes.status, 200);
  assert.equal(rejectRes.body.success, true);
  assert.equal(rejectRes.body.data.status, 'rejected');

  // 6. Approve ver-101
  const approveRes = await request(app)
    .patch('/api/v1/agency/verifications/ver-101/approve')
    .set('Authorization', `Bearer ${token}`)
    .send({ notes: 'All documents verified and validated' });

  assert.equal(approveRes.status, 200);
  assert.equal(approveRes.body.success, true);
  assert.equal(approveRes.body.data.status, 'verified');
});
