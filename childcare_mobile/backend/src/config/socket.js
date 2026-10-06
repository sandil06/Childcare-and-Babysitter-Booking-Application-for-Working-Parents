const chatSocket = require('../sockets/chatSocket');
const trackingSocket = require('../sockets/trackingSocket');

function configureSocket(io) {
  io.on('connection', (socket) => {
    socket.emit('connected', { socketId: socket.id });

    // Mount real-time chat listeners
    chatSocket(io, socket);

    // Mount real-time tracking listeners
    trackingSocket(socket);
  });
}

module.exports = configureSocket;
