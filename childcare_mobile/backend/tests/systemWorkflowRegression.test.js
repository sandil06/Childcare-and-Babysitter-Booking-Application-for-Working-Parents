const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const app = require('../src/app');
const generateToken = require('../src/utils/generateToken');
const ROLES = require('../src/constants/roles');

test('Comprehensive System & Shared Backend Workflows: Auth, Verification, Users, Reports, Stats, and Audit', async (t) => {
  const agencyAdmin = {
    _id: 'agency-admin-1',
    id: 'agency-admin-1',
    name: 'Super Admin',
    email: 'admin@littlehands.lk',
    role: ROLES.AGENCY,
  };
  const agencyToken = generateToken(agencyAdmin);

  const parentUser = {
    _id: 'parent-reg-1',
    id: 'parent-reg-1',
    name: 'Kasun Bandara',
    email: 'kasun.b@example.com',
    role: ROLES.PARENT,
  };
  const parentToken = generateToken(parentUser);

  const sitterUser = {
    _id: 'sitter-reg-1',
    id: 'sitter-reg-1',
    name: 'Hiruni Perera',
    email: 'hiruni.p@example.com',
    role: ROLES.BABYSITTER,
  };
  const sitterToken = generateToken(sitterUser);

  await t.test('1. Authentication & Role-Based Access Control', async () => {
    // 1.1 Missing token
    const noToken = await request(app).get('/api/v1/agency/dashboard');
    assert.equal(noToken.status, 401);
    assert.equal(noToken.body.success, false);

    // 1.2 Invalid role: Parent accessing agency dashboard
    const forbidden = await request(app)
      .get('/api/v1/agency/dashboard')
      .set('Authorization', `Bearer ${parentToken}`);
    assert.equal(forbidden.status, 403);
    assert.equal(forbidden.body.success, false);

    // 1.3 Valid agency access
    const allowed = await request(app)
      .get('/api/v1/agency/dashboard')
      .set('Authorization', `Bearer ${agencyToken}`);
    assert.equal(allowed.status, 200);
    assert.equal(allowed.body.success, true);
    const statsData = allowed.body.data.stats || allowed.body.data.metrics;
    assert.ok(statsData != null);
    assert.ok(statsData.totalUsers !== undefined);
  });

  await t.test('2. Babysitter Verification Workflow & Sitter Security', async () => {
    // 2.1 Sitter submits documents
    const submitRes = await request(app)
      .post('/api/v1/verifications/submit')
      .set('Authorization', `Bearer ${sitterToken}`)
      .send({
        documents: [
          { type: 'id', name: 'NIC Front/Back', url: 'https://cdn.example.com/nic.jpg' },
          { type: 'police_check', name: 'Clearance', url: 'https://cdn.example.com/police.pdf' },
        ],
      });
    assert.equal(submitRes.status, 201);
    const vId = submitRes.body.data._id || submitRes.body.data.id;

    // 2.2 Sitter cannot approve their own verification
    const selfApprove = await request(app)
      .patch(`/api/v1/agency/verifications/${vId}/approve`)
      .set('Authorization', `Bearer ${sitterToken}`)
      .send({ notes: 'Self approve attempt' });
    assert.equal(selfApprove.status, 403);

    // 2.3 Agency approves verification
    const agencyApprove = await request(app)
      .patch(`/api/v1/agency/verifications/${vId}/approve`)
      .set('Authorization', `Bearer ${agencyToken}`)
      .send({ notes: 'Verified and approved by agency' });
    assert.equal(agencyApprove.status, 200);
    assert.equal(agencyApprove.body.data.status, 'verified');

    // 2.4 Sitter status reflects verified
    const statusRes = await request(app)
      .get('/api/v1/verifications/my-status')
      .set('Authorization', `Bearer ${sitterToken}`);
    assert.equal(statusRes.status, 200);
    assert.equal(statusRes.body.data.status, 'verified');
  });

  await t.test('3. User Management, Suspension & Reactivation with Audit Log', async () => {
    // 3.1 List users with pagination and search
    const usersRes = await request(app)
      .get('/api/v1/agency/users?role=all&search=Amaya')
      .set('Authorization', `Bearer ${agencyToken}`);
    assert.equal(usersRes.status, 200);
    assert.ok(Array.isArray(usersRes.body.data));

    // 3.2 Suspend user requires reason
    const badSuspend = await request(app)
      .patch('/api/v1/agency/users/u-2/suspend')
      .set('Authorization', `Bearer ${agencyToken}`)
      .send({});
    assert.equal(badSuspend.status, 400);

    // 3.3 Suspend user with reason
    const suspendRes = await request(app)
      .patch('/api/v1/agency/users/u-2/suspend')
      .set('Authorization', `Bearer ${agencyToken}`)
      .send({ reason: 'Investigation into policy violation' });
    assert.equal(suspendRes.status, 200);
    assert.equal(suspendRes.body.data.accountStatus, 'suspended');

    // 3.4 Reactivate user
    const reactivateRes = await request(app)
      .patch('/api/v1/agency/users/u-2/reactivate')
      .set('Authorization', `Bearer ${agencyToken}`);
    assert.equal(reactivateRes.status, 200);
    assert.equal(reactivateRes.body.data.accountStatus, 'active');

    // 3.5 Verify audit logs contain these actions
    const auditRes = await request(app)
      .get('/api/v1/agency/audit-logs')
      .set('Authorization', `Bearer ${agencyToken}`);
    assert.equal(auditRes.status, 200);
    assert.ok(Array.isArray(auditRes.body.data));
    assert.ok(auditRes.body.data.some((log) => log.action === 'suspend_user'));
  });

  await t.test('4. Booking Monitoring & Admin Cancellation', async () => {
    // 4.1 Monitor bookings
    const bookingsRes = await request(app)
      .get('/api/v1/agency/bookings?status=all')
      .set('Authorization', `Bearer ${agencyToken}`);
    assert.equal(bookingsRes.status, 200);
    assert.ok(Array.isArray(bookingsRes.body.data));

    // 4.2 Non-agency blocked from admin cancellation
    const badCancel = await request(app)
      .patch('/api/v1/agency/bookings/bk-902/cancel')
      .set('Authorization', `Bearer ${parentToken}`)
      .send({ reason: 'Hacking attempt' });
    assert.equal(badCancel.status, 403);

    // 4.3 Admin cancellation requires reason
    const noReasonCancel = await request(app)
      .patch('/api/v1/agency/bookings/bk-902/cancel')
      .set('Authorization', `Bearer ${agencyToken}`)
      .send({});
    assert.equal(noReasonCancel.status, 400);

    // 4.4 Admin cancellation with reason
    const validCancel = await request(app)
      .patch('/api/v1/agency/bookings/bk-902/cancel')
      .set('Authorization', `Bearer ${agencyToken}`)
      .send({ reason: 'Emergency medical reason provided by client' });
    assert.equal(validCancel.status, 200);
    assert.equal(validCancel.body.data.status, 'cancelled');
  });

  await t.test('5. Complaints, Safety Reports & Resolution Workflow', async () => {
    // 5.1 Parent files safety report
    const fileRes = await request(app)
      .post('/api/v1/reports')
      .set('Authorization', `Bearer ${parentToken}`)
      .send({
        reportedUserId: 'u-3',
        category: 'Safety',
        description: 'Babysitter left toddler unattended on balcony for 15 minutes.',
        priority: 'urgent',
      });
    assert.equal(fileRes.status, 201);
    const repId = fileRes.body.data._id || fileRes.body.data.id;

    // 5.2 Agency views complaints
    const agencyRep = await request(app)
      .get(`/api/v1/agency/reports/${repId}`)
      .set('Authorization', `Bearer ${agencyToken}`);
    assert.equal(agencyRep.status, 200);
    assert.equal(agencyRep.body.data.priority, 'urgent');

    // 5.3 Agency resolves complaint
    const resolveRep = await request(app)
      .patch(`/api/v1/agency/reports/${repId}/resolve`)
      .set('Authorization', `Bearer ${agencyToken}`)
      .send({ resolutionNotes: 'Caregiver interviewed, suspension issued, full refund given.' });
    assert.equal(resolveRep.status, 200);
    assert.equal(resolveRep.body.data.status, 'resolved');
  });

  await t.test('6. System Statistics Aggregation', async () => {
    const statsRes = await request(app)
      .get('/api/v1/agency/statistics')
      .set('Authorization', `Bearer ${agencyToken}`);
    assert.equal(statsRes.status, 200);
    assert.ok(statsRes.body.data.users != null);
    assert.ok(statsRes.body.data.bookings != null);
    assert.ok(statsRes.body.data.verifications != null);
    assert.ok(statsRes.body.data.payments != null);
  });
});
