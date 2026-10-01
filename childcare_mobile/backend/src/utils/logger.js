function logger(level, message, metadata = {}) {
  const entry = { timestamp: new Date().toISOString(), level, message, ...metadata };
  level === 'error' ? console.error(JSON.stringify(entry)) : console.log(JSON.stringify(entry));
}

module.exports = logger;
