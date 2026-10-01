function socketHandler(io) {
  io.on('connection', (socket) => socket.emit('ready'));
}
module.exports = socketHandler;
