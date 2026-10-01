function health(req, res) {
  res.json({ success: true, status: 'ok', service: 'nurture-backend', timestamp: new Date().toISOString() });
}

module.exports = { health };
