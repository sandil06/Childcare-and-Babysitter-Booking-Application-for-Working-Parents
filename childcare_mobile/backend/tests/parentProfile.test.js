const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const app = require('../src/app');

function makeRequest(path, options = {}) {
  return new Promise((resolve, reject) => {
    const server = app.listen(0, () => {
      const port = server.address().port;
      const headers = {
        'Content-Type': 'application/json',
        ...(options.headers || {}),
      };
      const req = http.request(
        `http://127.0.0.1:${port}${path}`,
        { ...options, headers },
        (response) => {
          let body = '';
          response.on('data', (chunk) => {
            body += chunk;
          });
          response.on('end', () => {
            server.close();
            try {
              resolve({
                status: response.statusCode,
                body: body ? JSON.parse(body) : null,
              });
            } catch {
              resolve({ status: response.statusCode, body });
            }
          });
        }
      );
      req.on('error', (err) => {
        server.close();
        reject(err);
      });
      if (options.body) {
        req.write(JSON.stringify(options.body));
      }
      req.end();
    });
  });
}

test('Parent profile lifecycle: register, retrieve, update, and persist', async () => {
  const ts = Date.now();
  const testEmail = `parent_${ts}@example.com`;
  const testPhone = `+9477${Math.floor(1000000 + Math.random() * 9000000)}`;

  // 1. Register parent
  const registerRes = await makeRequest('/api/v1/auth/register', {
    method: 'POST',
    body: {
      name: 'Chamari Atapattu',
      email: testEmail,
      phone: testPhone,
      password: 'SecurePassword123!',
      role: 'parent',
    },
  });

  assert.equal(registerRes.status, 201);
  assert.equal(registerRes.body.success, true);
  const token = registerRes.body.data.token;
  assert.ok(token);

  // 2. Fetch parent profile
  const profileRes = await makeRequest('/api/v1/parents/profile', {
    method: 'GET',
    headers: { Authorization: `Bearer ${token}` },
  });

  assert.equal(profileRes.status, 200);
  assert.equal(profileRes.body.success, true);
  assert.equal(profileRes.body.data.name, 'Chamari Atapattu');
  assert.equal(profileRes.body.data.email, testEmail);
  assert.equal(profileRes.body.data.phone, testPhone);
  assert.deepEqual(profileRes.body.data.children, []);

  // 3. Update parent profile with authentic details & children
  const updateRes = await makeRequest('/api/v1/parents/profile', {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${token}` },
    body: {
      address: 'No 15, Kandy Road, Kiribathgoda',
      emergencyContact: '+94719998877',
      children: [
        { name: 'Dinuka Atapattu', age: '5', notes: 'Allergic to peanuts' },
      ],
    },
  });

  assert.equal(updateRes.status, 200);
  assert.equal(updateRes.body.success, true);
  assert.equal(updateRes.body.data.address, 'No 15, Kandy Road, Kiribathgoda');
  assert.equal(updateRes.body.data.emergencyContact, '+94719998877');
  assert.equal(updateRes.body.data.children.length, 1);
  assert.equal(updateRes.body.data.children[0].name, 'Dinuka Atapattu');

  // 4. Retrieve again to verify persistence
  const verifyRes = await makeRequest('/api/v1/parents/profile', {
    method: 'GET',
    headers: { Authorization: `Bearer ${token}` },
  });

  assert.equal(verifyRes.status, 200);
  assert.equal(verifyRes.body.data.address, 'No 15, Kandy Road, Kiribathgoda');
  assert.equal(verifyRes.body.data.children.length, 1);
  assert.equal(verifyRes.body.data.children[0].name, 'Dinuka Atapattu');
});
