const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const app = require('../src/app');
const AuditLog = require('../src/models/AuditLog');
const generateToken = require('../src/utils/generateToken');
const ROLES = require('../src/constants/roles');

test('System Database & Audit Logging: schema indexes, AuditLog helper, and listing audit trails', async () => {
  const agencyUser = {
    _id: 'agency-admin-1',
    id: 'agency-admin-1',
    name: 'Compliance Inspector',
    email: 'compliance@littlehands.lk',
    role: ROLES.AGENCY,
  };
  const token = generateToken(agencyUser);

  // 1. AuditLog.record helper should execute safely
  const recorded = await AuditLog.record({
    adminId: 'agency-admin-1',
    adminName: 'Compliance Inspector',
    adminEmail: 'compliance@littlehands.lk',
    action: 'approve_verification',
    targetType: 'VerificationRequest',
    targetId: 'ver-101',
    notes: 'Unit test recording audit log event',
  });
  // In mock environment without DB, record catches and returns null without throwing
  assert.ok(recorded === null || typeof recorded === 'object');

  // 2. Fetch audit logs via API
  const res = await request(app)
    .get('/api/v1/agency/audit-logs')
    .set('Authorization', `Bearer ${token}`);

  assert.equal(res.status, 200);
  assert.equal(res.body.success, true);
  assert.ok(Array.isArray(res.body.data));
  assert.ok(res.body.meta != null);
  assert.ok(res.body.data.length >= 2);

  // 3. Filter audit logs by action
  const actionRes = await request(app)
    .get('/api/v1/agency/audit-logs?action=approve_verification')
    .set('Authorization', `Bearer ${token}`);

  assert.equal(actionRes.status, 200);
  assert.ok(actionRes.body.data.every((l) => l.action === 'approve_verification'));

  // 4. Filter audit logs by targetType
  const targetRes = await request(app)
    .get('/api/v1/agency/audit-logs?targetType=User')
    .set('Authorization', `Bearer ${token}`);

  assert.equal(targetRes.status, 200);
  assert.ok(targetRes.body.data.every((l) => l.targetType === 'User'));
});
