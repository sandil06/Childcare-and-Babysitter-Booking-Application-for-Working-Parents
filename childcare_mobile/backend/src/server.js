const http = require('node:http');
const { Server } = require('socket.io');
const app = require('./app');
const env = require('./config/env');
const connectDatabase = require('./config/database');
const configureSocket = require('./config/socket');
const logger = require('./utils/logger');

async function startServer() {
  await connectDatabase();
  const server = http.createServer(app);
  const io = new Server(server, { cors: { origin: env.clientOrigin === '*' ? true : env.clientOrigin } });
  configureSocket(io);
  server.listen(env.port, () => logger('info', `Nurture backend listening on port ${env.port}`));
  return server;
}

if (require.main === module) startServer().catch((error) => { console.error(error); process.exit(1); });

module.exports = { startServer };
