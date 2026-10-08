const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');
const app = require('../src/app');
const generateToken = require('../src/utils/generateToken');
const ROLES = require('../src/constants/roles');

test('Babysitter Verification Security & Fine-Grained Document Reviews', async (t) => {
  const agencyUser = {
    _id: 'agency-admin-sec-1',
    id: 'agency-admin-sec-1',
    name: 'Verification Officer',
    email: 'officer@littlehands.lk',
    role: ROLES.AGENCY,
  };
  const agencyToken = generateToken(agencyUser);

  const sitterUser = {
    _id: 'sitter-sec-101',
    id: 'sitter-sec-101',
    name: 'Kavindi Silva',
    email: 'kavindi.silva@example.com',
    role: ROLES.BABYSITTER,
  };
  const sitterToken = generateToken(sitterUser);

  await t.test('1. Sitter CANNOT self-assign verificationStatus or review fields', async () => {
    // 1.1 Sitter attempts to set verificationStatus = 'verified'
    const res1 = await request(app)
      .patch('/api/v1/babysitters/me')
      .set('Authorization', `Bearer ${sitterToken}`)
      .send({ verificationStatus: 'verified' });
    assert.equal(res1.status, 403);
    assert.equal(res1.body.success, false);

    // 1.2 Sitter attempts to set review fields
    const res2 = await request(app)
      .patch('/api/v1/babysitters/me')
      .set('Authorization', `Bearer ${sitterToken}`)
      .send({ reviewNotes: 'Pre-approved by internal team' });
    assert.equal(res2.status, 403);
    assert.equal(res2.body.success, false);
  });

  await t.test('2. Sitter adding document or qualification must start as pending and cannot claim verified', async () => {
    // 2.1 Attempting to pass status: 'verified' on add document must be forbidden
    const resForbidden = await request(app)
      .post('/api/v1/babysitters/me/verification-documents')
      .set('Authorization', `Bearer ${sitterToken}`)
      .send({
        type: 'national_id',
        name: 'National ID Card',
        url: 'https://example.com/nic.jpg',
        status: 'verified',
      });
    assert.equal(resForbidden.status, 403);

    // 2.2 Adding document normally creates it with status: 'pending'
    const resDoc = await request(app)
      .post('/api/v1/babysitters/me/verification-documents')
      .set('Authorization', `Bearer ${sitterToken}`)
      .send({
        type: 'national_id',
        name: 'National ID Card',
        url: 'https://example.com/nic.jpg',
      });
    assert.equal(resDoc.status, 201);
    assert.equal(resDoc.body.success, true);
    assert.equal(resDoc.body.data.document.status, 'pending');

    // 2.3 Adding qualification normally creates it with status: 'pending'
    const resQual = await request(app)
      .post('/api/v1/babysitters/me/qualifications')
      .set('Authorization', `Bearer ${sitterToken}`)
      .send({
        title: 'Diploma in Early Childhood Education',
        institution: 'Open University Sri Lanka',
      });
    assert.equal(resQual.status, 201);
    assert.equal(resQual.body.success, true);
    assert.equal(resQual.body.data.qualification.status, 'pending');
  });

  await t.test('3. Agency Admin can review individual documents and qualifications', async () => {
    // 3.1 First submit verification request
    const submitRes = await request(app)
      .post('/api/v1/verifications/submit')
      .set('Authorization', `Bearer ${sitterToken}`)
      .send({
        documents: [
          {
            _id: 'doc-nic-1',
            type: 'national_id',
            name: 'NIC Card Front/Back',
            url: 'https://example.com/nic.png',
            status: 'pending',
          },
          {
            _id: 'doc-police-1',
            type: 'police_check',
            name: 'Police Clearance Certificate',
            url: 'https://example.com/police.pdf',
            status: 'pending',
          },
        ],
        qualifications: [
          {
            _id: 'qual-cpr-1',
            title: 'First Aid & Pediatric CPR',
            institution: 'Red Cross Sri Lanka',
            status: 'pending',
          },
        ],
      });
    assert.equal(submitRes.status, 201);
    const verId = submitRes.body.data.id || submitRes.body.data._id;

    // 3.2 Agency requests changes on doc-nic-1 without reason -> 400
    const emptyNotes = await request(app)
      .patch(`/api/v1/agency/verifications/${verId}/documents/doc-nic-1/request-changes`)
      .set('Authorization', `Bearer ${agencyToken}`)
      .send({});
    assert.equal(emptyNotes.status, 400);

    // 3.3 Agency requests changes on doc-nic-1 with instructions -> 200
    const reqChanges = await request(app)
      .patch(`/api/v1/agency/verifications/${verId}/documents/doc-nic-1/request-changes`)
      .set('Authorization', `Bearer ${agencyToken}`)
      .send({ notes: 'Please upload a higher resolution photo' });
    assert.equal(reqChanges.status, 200);
    assert.equal(reqChanges.body.data.document.status, 'changes_requested');
    assert.equal(reqChanges.body.data.document.reviewNotes, 'Please upload a higher resolution photo');

    // 3.4 Sitter replaces doc-nic-1 -> resets to pending
    const resubmit = await request(app)
      .patch('/api/v1/babysitters/me/verification-documents/doc-nic-1')
      .set('Authorization', `Bearer ${sitterToken}`)
      .send({
        name: 'NIC Card High Res',
        url: 'https://example.com/nic_hd.png',
      });
    assert.equal(resubmit.status, 200);
    assert.equal(resubmit.body.data.status, 'pending');
    assert.equal(resubmit.body.data.reviewNotes, null);

    // 3.5 Agency approves doc-nic-1
    const appDoc1 = await request(app)
      .patch(`/api/v1/agency/verifications/${verId}/documents/doc-nic-1/approve`)
      .set('Authorization', `Bearer ${agencyToken}`)
      .send({});
    assert.equal(appDoc1.status, 200);
    assert.equal(appDoc1.body.data.document.status, 'verified');

    // 3.6 Agency approves doc-police-1
    const appDoc2 = await request(app)
      .patch(`/api/v1/agency/verifications/${verId}/documents/doc-police-1/approve`)
      .set('Authorization', `Bearer ${agencyToken}`)
      .send({});
    assert.equal(appDoc2.status, 200);
    assert.equal(appDoc2.body.data.document.status, 'verified');

    // 3.7 Agency approves qualification qual-cpr-1
    const appQual = await request(app)
      .patch(`/api/v1/agency/verifications/${verId}/qualifications/qual-cpr-1/approve`)
      .set('Authorization', `Bearer ${agencyToken}`)
      .send({});
    assert.equal(appQual.status, 200);
    assert.equal(appQual.body.data.qualification.status, 'verified');

    // 3.8 Overall sitter approval succeeds when documents are verified
    const overallApprove = await request(app)
      .patch(`/api/v1/agency/verifications/${verId}/approve`)
      .set('Authorization', `Bearer ${agencyToken}`)
      .send({ notes: 'All identity and certificate documents verified.' });
    assert.equal(overallApprove.status, 200);
    assert.equal(overallApprove.body.data.status, 'verified');
  });
});
