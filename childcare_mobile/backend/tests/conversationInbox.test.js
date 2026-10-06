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
        req.write(typeof options.body === 'string' ? options.body : JSON.stringify(options.body));
      }
      req.end();
    });
  });
}

test('Conversation Inbox and Message APIs: list, create, send, retrieve, and mark as read', async () => {
  const ts = Date.now();
  const parentEmail = `chat_parent_${ts}@example.com`;
  const sitterEmail = `chat_sitter_${ts}@example.com`;

  // 1. Register Parent
  const parentRes = await makeRequest('/api/v1/auth/register', {
    method: 'POST',
    body: {
      name: 'Roshani De Silva',
      email: parentEmail,
      phone: `+9477${Math.floor(1000000 + Math.random() * 9000000)}`,
      password: 'ChatSecure123!',
      role: 'parent',
    },
  });
  assert.equal(parentRes.status, 201);
  const parentToken = parentRes.body.data.token;
  const parentId = parentRes.body.data.user.id;

  // 2. Register Sitter
  const sitterRes = await makeRequest('/api/v1/auth/register', {
    method: 'POST',
    body: {
      name: 'Kasun Bandara',
      email: sitterEmail,
      phone: `+9477${Math.floor(1000000 + Math.random() * 9000000)}`,
      password: 'SitterChat123!',
      role: 'babysitter',
    },
  });
  assert.equal(sitterRes.status, 201);
  const sitterToken = sitterRes.body.data.token;
  const sitterId = sitterRes.body.data.user.id;

  // 3. Parent initiates/gets conversation with Sitter
  const convRes = await makeRequest('/api/v1/conversations', {
    method: 'POST',
    headers: { Authorization: `Bearer ${parentToken}` },
    body: {
      recipientId: sitterId,
    },
  });
  assert.equal(convRes.status, 200);
  const conv = convRes.body.data;
  const convId = conv._id || conv.id;
  assert.ok(convId, 'Should return a valid conversation ID');

  // 4. Send message in conversation
  const sendRes = await makeRequest(`/api/v1/conversations/${convId}/messages`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${parentToken}` },
    body: {
      text: 'Hello Kasun, will you be available this Saturday for 4 hours?',
    },
  });
  assert.equal(sendRes.status, 201);
  assert.equal(sendRes.body.data.text, 'Hello Kasun, will you be available this Saturday for 4 hours?');

  // 5. Retrieve messages in conversation
  const getMsgsRes = await makeRequest(`/api/v1/conversations/${convId}/messages`, {
    method: 'GET',
    headers: { Authorization: `Bearer ${parentToken}` },
  });
  assert.equal(getMsgsRes.status, 200);
  assert.ok(Array.isArray(getMsgsRes.body.data));
  assert.equal(getMsgsRes.body.data.length, 1);
  assert.equal(getMsgsRes.body.data[0].text, 'Hello Kasun, will you be available this Saturday for 4 hours?');

  // 6. Sitter retrieves conversation list
  const listRes = await makeRequest('/api/v1/conversations', {
    method: 'GET',
    headers: { Authorization: `Bearer ${sitterToken}` },
  });
  assert.equal(listRes.status, 200);
  assert.ok(Array.isArray(listRes.body.data));

  // 7. Mark conversation messages as read
  const readRes = await makeRequest(`/api/v1/conversations/${convId}/read`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${sitterToken}` },
  });
  assert.equal(readRes.status, 200);
  assert.equal(readRes.body.data.markedRead, true);
});
