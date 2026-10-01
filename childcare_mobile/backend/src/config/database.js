const dns = require('node:dns');
const mongoose = require('mongoose');
const env = require('./env');

function resolveMongoHost(hostname, options, callback) {
  dns.promises.resolve4(hostname)
    .then((addresses) => {
      if (options.all) {
        callback(null, addresses.map((address) => ({ address, family: 4 })));
        return;
      }
      callback(null, addresses[0], 4);
    })
    .catch(callback);
}

async function connectDatabase() {
  if (!env.mongodbUri) {
    console.log('MONGODB_URI is not configured; running without a database connection');
    return null;
  }
  if (env.mongodbDnsServers.length > 0) {
    dns.setServers(env.mongodbDnsServers);
  }
  await mongoose.connect(env.mongodbUri, {
    lookup: resolveMongoHost,
    serverSelectionTimeoutMS: 5000,
  });
  console.log('MongoDB connected');
  return mongoose.connection;
}

module.exports = connectDatabase;
