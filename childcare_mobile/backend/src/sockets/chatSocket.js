const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const env = require('../config/env');
const Conversation = require('../models/Conversation');
const Message = require('../models/Message');
const { memoryConversations, memoryMessages } = require('../controllers/messageController');

function isDbConnected() {
  return mongoose.connection.readyState === 1;
}

function chatSocket(io, socket) {
  // Extract authenticated user if available
  let currentUser = socket.user;
  if (!currentUser) {
    const rawToken =
      socket.handshake.auth?.token ||
      socket.handshake.query?.token ||
      socket.handshake.headers?.authorization?.replace('Bearer ', '');

    if (rawToken) {
      try {
        currentUser = jwt.verify(rawToken, env.jwtSecret);
        socket.user = currentUser;
      } catch (_) {
        // Token verification failed or unauthenticated
      }
    }
  }

  const currentUserId = currentUser?.sub || currentUser?.id || socket.id;
  socket.join(`user:${currentUserId}`);

  // 1. Join Conversation Room
  const handleJoin = (conversationId, ack) => {
    if (!conversationId) return;
    const room = `conversation:${conversationId}`;
    socket.join(room);
    if (typeof ack === 'function') {
      ack({ success: true, room: conversationId });
    }
  };

  socket.on('join_conversation', handleJoin);
  socket.on('chat:join', handleJoin);

  // 2. Leave Conversation Room
  const handleLeave = (conversationId, ack) => {
    if (!conversationId) return;
    socket.leave(`conversation:${conversationId}`);
    if (typeof ack === 'function') {
      ack({ success: true, room: conversationId });
    }
  };

  socket.on('leave_conversation', handleLeave);
  socket.on('chat:leave', handleLeave);

  // 3. Send Message
  socket.on('send_message', async (data, ack) => {
    try {
      const { conversationId, text, type = 'text', recipientId } = data || {};
      if (!conversationId || !text || !text.trim()) {
        if (typeof ack === 'function') ack({ success: false, error: 'conversationId and text are required' });
        return;
      }

      const cleanText = text.trim();
      let savedMsg = null;

      if (isDbConnected() && mongoose.Types.ObjectId.isValid(conversationId)) {
        savedMsg = await Message.create({
          conversation: conversationId,
          sender: currentUserId,
          receiver: recipientId || null,
          text: cleanText,
          type,
          status: 'sent',
        });

        await Conversation.findByIdAndUpdate(conversationId, {
          lastMessage: cleanText,
          lastMessageAt: new Date(),
        });
      } else {
        const msgId = `m-${Date.now()}`;
        savedMsg = {
          _id: msgId,
          id: msgId,
          conversation: conversationId,
          sender: currentUserId,
          senderName: currentUser?.name || 'You',
          receiver: recipientId,
          text: cleanText,
          type,
          status: 'sent',
          createdAt: new Date(),
        };

        const list = memoryMessages.get(conversationId) || [];
        list.push(savedMsg);
        memoryMessages.set(conversationId, list);

        const conv = memoryConversations.get(conversationId);
        if (conv) {
          conv.lastMessage = cleanText;
          conv.lastMessageAt = new Date();
        }
      }

      const room = `conversation:${conversationId}`;
      const payload = {
        message: savedMsg,
        conversationId,
        senderId: currentUserId,
      };

      // Broadcast to room and specific recipient
      io.to(room).emit('receive_message', payload);
      io.to(room).emit('new_message', payload);
      if (recipientId) {
        io.to(`user:${recipientId}`).emit('new_message', payload);
      }

      if (typeof ack === 'function') {
        ack({ success: true, message: savedMsg });
      }
    } catch (err) {
      if (typeof ack === 'function') {
        ack({ success: false, error: err.message });
      }
    }
  });

  // 4. Typing Start
  socket.on('typing_start', (data) => {
    const { conversationId, userName } = data || {};
    if (!conversationId) return;
    socket.to(`conversation:${conversationId}`).emit('typing_start', {
      conversationId,
      userId: currentUserId,
      userName: userName || currentUser?.name || 'User',
    });
  });

  // 5. Typing Stop
  socket.on('typing_stop', (data) => {
    const { conversationId } = data || {};
    if (!conversationId) return;
    socket.to(`conversation:${conversationId}`).emit('typing_stop', {
      conversationId,
      userId: currentUserId,
    });
  });

  // 6. Message Read Acknowledgement
  socket.on('message_read', async (data) => {
    const { conversationId, messageId } = data || {};
    if (!conversationId) return;

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(conversationId)) {
      await Message.updateMany(
        { conversation: conversationId, sender: { $ne: currentUserId } },
        { status: 'read', readAt: new Date() }
      );
    } else {
      const conv = memoryConversations.get(conversationId);
      if (conv) conv.unreadCount = 0;
    }

    socket.to(`conversation:${conversationId}`).emit('message_read', {
      conversationId,
      messageId,
      readBy: currentUserId,
    });
  });

  // 7. Cleanup on Disconnect
  socket.on('disconnect', () => {
    // Socket automatically leaves rooms
  });
}

module.exports = chatSocket;
