const dotenv = require('dotenv');

dotenv.config({ quiet: true });

function parseClientOrigins(value) {
  return value
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
}

function isAllowedClientOrigin(origin) {
  if (!origin) return true;

  const configuredOrigins = parseClientOrigins(process.env.CLIENT_ORIGIN || '*');
  if (configuredOrigins.includes('*') || configuredOrigins.includes(origin)) {
    return true;
  }

  if (process.env.NODE_ENV !== 'production') {
    try {
      const url = new URL(origin);
      const isLocalHost = url.hostname === 'localhost' || url.hostname === '127.0.0.1';
      return isLocalHost && (url.protocol === 'http:' || url.protocol === 'https:');
    } catch {
      return false;
    }
  }

  return false;
}

const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: Number(process.env.PORT || 4000),
  mongodbUri: process.env.MONGODB_URI || '',
  mongodbDnsServers: (process.env.MONGODB_DNS_SERVERS || '')
    .split(',')
    .map((server) => server.trim())
    .filter(Boolean),
  jwtSecret: process.env.JWT_SECRET || 'development-secret',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  clientOrigin: process.env.CLIENT_ORIGIN || '*',
  isAllowedClientOrigin,
  googleClientId: process.env.GOOGLE_CLIENT_ID || process.env.Google_client_id || '',
};

module.exports = env;
