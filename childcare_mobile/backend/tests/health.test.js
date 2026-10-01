const test = require('node:test');
const assert = require('node:assert/strict');
const app = require('../src/app');

function request(path) {
  return new Promise((resolve, reject) => {
    const server = app.listen(0, () => {
      const port = server.address().port;
      require('http').get(`http://127.0.0.1:${port}${path}`, (response) => {
        let body = '';
        response.on('data', (chunk) => { body += chunk; });
        response.on('end', () => { server.close(); resolve({ status: response.statusCode, body: JSON.parse(body) }); });
      }).on('error', (error) => { server.close(); reject(error); });
    });
  });
}

test('health endpoint responds', async () => {
  const response = await request('/api/v1/health');
  assert.equal(response.status, 200);
  assert.equal(response.body.status, 'ok');
});
