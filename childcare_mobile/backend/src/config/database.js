const mongoose = require('mongoose');
const env = require('./env');
const logger = require('../utils/logger');

async function connectDatabase() {
  if (!env.mongodbUri) {
    logger('info', 'MONGODB_URI is not configured; running without a database connection');
    return null;
  }
  await mongoose.connect(env.mongodbUri);
  logger('info', 'MongoDB connected');
  return mongoose.connection;
}

module.exports = connectDatabase;
