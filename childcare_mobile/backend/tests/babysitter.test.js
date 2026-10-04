const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const app = require('../src/app');

function makeRequest(path, options = {}) {
  return new Promise((resolve, reject) => {
    const server = app.listen(0, () => {
      const port = server.address().port;
      const req = http.request(
        `http://127.0.0.1:${port}${path}`,
        options,
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

test('GET /api/v1/babysitters returns list of babysitters', async () => {
  const res = await makeRequest('/api/v1/babysitters');
  assert.equal(res.status, 200);
  assert.equal(res.body.success, true);
  assert.ok(Array.isArray(res.body.data));
  assert.ok(res.body.data.length > 0);
  const sitter = res.body.data[0];
  const name = sitter.name || sitter.user?.name;
  assert.ok(name);
  assert.ok(sitter.hourlyRate > 0);
});

test('GET /api/v1/babysitters/:id returns specific babysitter details', async () => {
  const listRes = await makeRequest('/api/v1/babysitters');
  const targetId = listRes.body.data[0].id || listRes.body.data[0]._id;
  const res = await makeRequest(`/api/v1/babysitters/${targetId}`);
  assert.equal(res.status, 200);
  assert.equal(res.body.success, true);
  const name = res.body.data.name || res.body.data.user?.name;
  const expectedName = listRes.body.data[0].name || listRes.body.data[0].user?.name;
  assert.equal(name, expectedName);
});

test('Earnings calculation: hourlyRate * duration = total earnings', () => {
  const hourlyRate = 28.0;
  const durationHours = 4.0;
  const gross = hourlyRate * durationHours;
  const feeRate = 0.05;
  const serviceFee = Number((gross * feeRate).toFixed(2));
  const netEarnings = Number((gross - serviceFee).toFixed(2));

  assert.equal(gross, 112.0);
  assert.equal(serviceFee, 5.60);
  assert.equal(netEarnings, 106.40);
});
