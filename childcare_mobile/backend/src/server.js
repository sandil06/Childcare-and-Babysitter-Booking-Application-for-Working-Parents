const http = require('node:http');
const { Server } = require('socket.io');
const app = require('./app');
const env = require('./config/env');
const connectDatabase = require('./config/database');
const configureSocket = require('./config/socket');

async function startServer() {
  try {
    await connectDatabase();
    const seedAgencyUsers = require('./utils/seedAgencyUsers');
    await seedAgencyUsers();
  } catch (error) {
    console.error(`MongoDB connection failed: ${error.message}`);
    console.error('Backend starting without a database connection');
  }
  const server = http.createServer(app);
  const io = new Server(server, {
    cors: {
      origin: (origin, callback) => {
        if (env.isAllowedClientOrigin(origin)) return callback(null, true);
        return callback(null, false);
      },
    },
  });
  configureSocket(io);
  server.listen(env.port);
  return server;
}

if (require.main === module) startServer().catch((error) => { console.error(error); process.exit(1); });

module.exports = { startServer };
