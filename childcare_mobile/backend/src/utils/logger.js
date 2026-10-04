function logger(level, message, metadata = {}) {
  const entry = { timestamp: new Date().toISOString(), level, message, ...metadata };
  level === 'error' ? console.error(JSON.stringify(entry)) : console.log(JSON.stringify(entry));
}

logger.info = (message, metadata) => logger('info', message, metadata);
logger.error = (message, metadata) => logger('error', message, metadata);
logger.warn = (message, metadata) => logger('warn', message, metadata);
logger.debug = (message, metadata) => logger('debug', message, metadata);

module.exports = logger;
