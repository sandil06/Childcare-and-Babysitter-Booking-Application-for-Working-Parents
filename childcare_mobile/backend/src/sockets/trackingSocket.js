function trackingSocket(socket) {
  socket.on('tracking:join', (bookingId) => socket.join(`booking:${bookingId}`));
}
module.exports = trackingSocket;
