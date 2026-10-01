function chatSocket(socket) {
  socket.on('chat:join', (conversationId) => socket.join(`conversation:${conversationId}`));
}
module.exports = chatSocket;
