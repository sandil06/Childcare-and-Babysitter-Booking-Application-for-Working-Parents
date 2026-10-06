const mongoose = require('mongoose');
const Conversation = require('../models/Conversation');
const Message = require('../models/Message');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');
const { memoryConversations, memoryMessages } = require('./messageController');

function isDbConnected() {
  return mongoose.connection.readyState === 1;
}

function getUserId(req) {
  return req.user?.sub || req.user?.id;
}

/**
 * GET /api/v1/conversations
 * List all conversations for the authenticated user
 */
async function list(req, res, next) {
  try {
    const userId = getUserId(req);

    if (isDbConnected()) {
      const page = Math.max(1, parseInt(req.query.page) || 1);
      const limit = Math.min(50, parseInt(req.query.limit) || 20);
      const skip = (page - 1) * limit;

      const conversations = await Conversation.find({ participants: userId })
        .populate('participants', 'name email phone avatar role')
        .populate('bookingId', 'bookingId date startTime endTime status')
        .sort({ lastMessageAt: -1 })
        .skip(skip)
        .limit(limit);

      const formatted = conversations.map((c) => {
        const doc = c.toObject ? c.toObject() : { ...c };
        const other = (doc.participants || []).find((p) => {
          const pId = p._id ? p._id.toString() : p.toString();
          return pId !== userId.toString();
        });

        return {
          ...doc,
          id: doc._id.toString(),
          otherUser: other || null,
          otherUserId: other ? (other._id || other.id || other).toString() : '',
          otherUserName: other ? (other.name || 'User') : 'User',
          otherUserAvatar: other ? (other.avatar || null) : null,
          otherUserRole: other ? (other.role || 'user') : 'user',
          unreadCount: (doc.unreadCounts && doc.unreadCounts[userId.toString()]) || 0,
        };
      });

      return ApiResponse.success(res, formatted, 'Conversations retrieved successfully');
    }

    // Memory fallback
    let list = Array.from(memoryConversations.values()).filter((c) =>
      c.participants && c.participants.includes(userId)
    );

    if (list.length === 0 && memoryConversations.size > 0) {
      list = Array.from(memoryConversations.values());
    }

    const formatted = list.map((c) => {
      const otherId = (c.participants || []).find((p) => p.toString() !== userId.toString()) || c.parentId;
      return {
        ...c,
        id: c._id || c.id,
        otherUserId: otherId || '',
        otherUserName: c.parentName || c.otherUserName || 'User',
        otherUserAvatar: c.parentAvatar || null,
        otherUserRole: 'babysitter',
        unreadCount: c.unreadCount || 0,
      };
    });

    return ApiResponse.success(res, formatted, 'Conversations retrieved successfully');
  } catch (err) {
    next(err);
  }
}

/**
 * POST /api/v1/conversations
 * Get or create a conversation between current user and recipient
 */
async function getOrCreate(req, res, next) {
  try {
    const userId = getUserId(req);
    const { recipientId, bookingId } = req.body;

    if (!recipientId) {
      throw new ApiError(400, 'recipientId is required');
    }

    if (isDbConnected()) {
      let conv = await Conversation.findOne({
        participants: { $all: [userId, recipientId] },
      }).populate('participants', 'name email phone avatar role');

      if (!conv) {
        conv = await Conversation.create({
          participants: [userId, recipientId],
          bookingId: bookingId || null,
          lastMessage: '',
          lastMessageAt: new Date(),
        });
        await conv.populate('participants', 'name email phone avatar role');
      }

      return ApiResponse.success(res, conv, 'Conversation ready', 200);
    }

    // Memory fallback
    let found = Array.from(memoryConversations.values()).find(
      (c) => c.participants && c.participants.includes(userId) && c.participants.includes(recipientId)
    );

    if (!found) {
      const id = `conv-${Date.now()}`;
      found = {
        _id: id,
        id,
        participants: [userId, recipientId],
        parentId: recipientId,
        parentName: 'User',
        lastMessage: '',
        lastMessageAt: new Date(),
        unreadCount: 0,
        bookingId: bookingId || null,
      };
      memoryConversations.set(id, found);
    }

    return ApiResponse.success(res, found, 'Conversation ready', 200);
  } catch (err) {
    next(err);
  }
}

/**
 * GET /api/v1/conversations/:id/messages
 * Get paginated messages for conversation
 */
async function getMessages(req, res, next) {
  try {
    const { id } = req.params;
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(100, parseInt(req.query.limit) || 40);
    const skip = (page - 1) * limit;

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(id)) {
      const messages = await Message.find({ conversation: id })
        .populate('sender', 'name email avatar role')
        .sort({ createdAt: 1 })
        .skip(skip)
        .limit(limit);

      return ApiResponse.success(res, messages, 'Messages retrieved');
    }

    // Memory fallback
    const msgs = memoryMessages.get(id) || [];
    return ApiResponse.success(res, msgs, 'Messages retrieved');
  } catch (err) {
    next(err);
  }
}

/**
 * POST /api/v1/conversations/:id/messages
 * Send a message inside a conversation
 */
async function sendMessage(req, res, next) {
  try {
    const userId = getUserId(req);
    const { id } = req.params;
    const { text, type = 'text', recipientId } = req.body;

    if (!text || !text.trim()) {
      throw new ApiError(400, 'Message text is required');
    }

    if (isDbConnected()) {
      const msg = await Message.create({
        conversation: id,
        sender: userId,
        receiver: recipientId || null,
        text: text.trim(),
        type,
        status: 'sent',
      });

      await Conversation.findByIdAndUpdate(id, {
        lastMessage: text.trim(),
        lastMessageAt: new Date(),
      });

      return ApiResponse.success(res, msg, 'Message sent', 201);
    }

    // Memory fallback
    const msgId = `m-${Date.now()}`;
    const newMsg = {
      _id: msgId,
      id: msgId,
      conversation: id,
      sender: userId,
      senderName: req.user?.name || 'You',
      text: text.trim(),
      type,
      status: 'sent',
      createdAt: new Date(),
    };

    const list = memoryMessages.get(id) || [];
    list.push(newMsg);
    memoryMessages.set(id, list);

    const conv = memoryConversations.get(id);
    if (conv) {
      conv.lastMessage = text.trim();
      conv.lastMessageAt = new Date();
    }

    return ApiResponse.success(res, newMsg, 'Message sent', 201);
  } catch (err) {
    next(err);
  }
}

/**
 * PATCH /api/v1/conversations/:id/read
 * Mark all messages in conversation as read
 */
async function markAsRead(req, res, next) {
  try {
    const userId = getUserId(req);
    const { id } = req.params;

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(id)) {
      await Message.updateMany(
        { conversation: id, sender: { $ne: userId }, status: { $ne: 'read' } },
        { status: 'read', readAt: new Date() }
      );

      return ApiResponse.success(res, { markedRead: true }, 'Messages marked as read');
    }

    // Memory fallback
    const conv = memoryConversations.get(id);
    if (conv) {
      conv.unreadCount = 0;
    }
    return ApiResponse.success(res, { markedRead: true }, 'Messages marked as read');
  } catch (err) {
    next(err);
  }
}

module.exports = {
  list,
  getOrCreate,
  getMessages,
  sendMessage,
  markAsRead,
};
