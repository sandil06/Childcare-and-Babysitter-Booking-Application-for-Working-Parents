const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const app = require('../src/app');
const generateToken = require('../src/utils/generateToken');
const ROLES = require('../src/constants/roles');

test('Agency Notifications & Platform Broadcasts: list, category filter, validation, and dispatch', async () => {
  const agencyAdmin = {
    _id: 'agency-admin-1',
    id: 'agency-admin-1',
    name: 'Chief Compliance Officer',
    email: 'compliance@littlehands.lk',
    role: ROLES.AGENCY,
  };
  const token = generateToken(agencyAdmin);

  // 1. Retrieve all administrative notifications
  const allRes = await request(app)
    .get('/api/v1/agency/notifications?category=all')
    .set('Authorization', `Bearer ${token}`);

  assert.equal(allRes.status, 200);
  assert.equal(allRes.body.success, true);
  assert.ok(Array.isArray(allRes.body.data));
  assert.ok(allRes.body.data.length >= 3);
  assert.ok(allRes.headers['x-unread-count'] !== undefined);

  // 2. Filter by verification category
  const verifRes = await request(app)
    .get('/api/v1/agency/notifications?category=verification')
    .set('Authorization', `Bearer ${token}`);

  assert.equal(verifRes.status, 200);
  assert.ok(
    verifRes.body.data.every(
      (n) => n.category === 'verification' || n.type.startsWith('verification_')
    )
  );

  // 3. Filter by safety category
  const safetyRes = await request(app)
    .get('/api/v1/agency/notifications?category=safety')
    .set('Authorization', `Bearer ${token}`);

  assert.equal(safetyRes.status, 200);
  assert.ok(
    safetyRes.body.data.every(
      (n) => n.category === 'safety' || n.type === 'safety_report' || n.type === 'high_priority_complaint'
    )
  );

  // 4. Broadcast validation - missing title should fail
  const badBroadcast1 = await request(app)
    .post('/api/v1/agency/notifications/broadcast')
    .set('Authorization', `Bearer ${token}`)
    .send({
      message: 'Maintenance will start at midnight.',
    });

  assert.equal(badBroadcast1.status, 400);

  // 5. Broadcast validation - invalid target audience should fail
  const badBroadcast2 = await request(app)
    .post('/api/v1/agency/notifications/broadcast')
    .set('Authorization', `Bearer ${token}`)
    .send({
      title: 'Emergency Advisory',
      message: 'Severe weather advisory for coastal regions.',
      targetAudience: 'invalid_group',
    });

  assert.equal(badBroadcast2.status, 400);

  // 6. Successful broadcast dispatch
  const broadcastRes = await request(app)
    .post('/api/v1/agency/notifications/broadcast')
    .set('Authorization', `Bearer ${token}`)
    .send({
      title: 'Platform Maintenance Notice',
      message: 'Scheduled infrastructure update tonight between 2:00 AM and 3:00 AM UTC.',
      targetAudience: 'all',
      priority: 'high',
    });

  assert.equal(broadcastRes.status, 201);
  assert.equal(broadcastRes.body.success, true);
  assert.equal(broadcastRes.body.data.title, 'Platform Maintenance Notice');
  assert.ok(broadcastRes.body.data.recipientCount > 0);
  assert.ok(broadcastRes.body.data.broadcastId);

  // 7. Verify the dispatched broadcast appears in the agency notification stream
  const refreshedAll = await request(app)
    .get('/api/v1/agency/notifications?category=all')
    .set('Authorization', `Bearer ${token}`);

  assert.equal(refreshedAll.status, 200);
  const found = refreshedAll.body.data.find(
    (n) => n.title === 'Platform Maintenance Notice'
  );
  assert.ok(found);
  assert.equal(found.targetAudience, 'all');
});
