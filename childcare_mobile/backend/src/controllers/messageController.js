const mongoose = require('mongoose');
const Conversation = require('../models/Conversation');
const Message = require('../models/Message');
const ApiResponse = require('../utils/ApiResponse');
const ApiError = require('../utils/ApiError');

// Memory store fallback
const memoryConversations = new Map();
const memoryMessages = new Map();

function isDbConnected() {
  return mongoose.connection.readyState === 1;
}

function getUserId(req) {
  return req.user?.sub || req.user?.id;
}

function initMemoryData(userId) {
  if (memoryConversations.size === 0) {
    const c1 = {
      _id: 'conv-1',
      id: 'conv-1',
      participants: [userId, 'parent-1'],
      parentId: 'parent-1',
      parentName: 'Sarah Jenkins',
      parentAvatar: null,
      lastMessage: 'Hi, can you please arrive 10 minutes early today?',
      lastMessageAt: new Date(Date.now() - 15 * 60 * 1000),
      unreadCount: 1,
    };
    const c2 = {
      _id: 'conv-2',
      id: 'conv-2',
      participants: [userId, 'parent-2'],
      parentId: 'parent-2',
      parentName: 'Michael Chang',
      parentAvatar: null,
      lastMessage: 'Thank you! Lucas had a wonderful time building blocks.',
      lastMessageAt: new Date(Date.now() - 2 * 3600 * 1000),
      unreadCount: 0,
    };
    const c3 = {
      _id: 'conv-3',
      id: 'conv-3',
      participants: [userId, 'parent-3'],
      parentId: 'parent-3',
      parentName: 'Emily Watson',
      parentAvatar: null,
      lastMessage: 'Payment sent! Thanks so much for caring for Chloe.',
      lastMessageAt: new Date(Date.now() - 24 * 3600 * 1000),
      unreadCount: 0,
    };

    memoryConversations.set(c1.id, c1);
    memoryConversations.set(c2.id, c2);
    memoryConversations.set(c3.id, c3);

    memoryMessages.set('conv-1', [
      {
        _id: 'm-1',
        id: 'm-1',
        conversation: 'conv-1',
        sender: 'parent-1',
        senderName: 'Sarah Jenkins',
        text: 'Hi, looking forward to your visit today!',
        createdAt: new Date(Date.now() - 45 * 60 * 1000),
      },
      {
        _id: 'm-2',
        id: 'm-2',
        conversation: 'conv-1',
        sender: userId,
        senderName: 'You',
        text: 'Hello Sarah! Yes, I am preparing now and excited to meet Leo and Mia.',
        createdAt: new Date(Date.now() - 30 * 60 * 1000),
      },
      {
        _id: 'm-3',
        id: 'm-3',
        conversation: 'conv-1',
        sender: 'parent-1',
        senderName: 'Sarah Jenkins',
        text: 'Hi, can you please arrive 10 minutes early today?',
        createdAt: new Date(Date.now() - 15 * 60 * 1000),
      },
    ]);
  }
}

async function getConversations(req, res, next) {
  try {
    const userId = getUserId(req);

    if (isDbConnected()) {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 15;
      const skip = (page - 1) * limit;

      const conversations = await Conversation.find({ participants: userId })
        .populate('participants', 'name email phone avatar')
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
          parent: other || null,
          parentId: other ? (other._id || other.id || other).toString() : '',
          parentName: other ? (other.name || 'Parent') : (doc.parentName || 'Parent'),
          parentAvatar: other ? (other.avatar || null) : (doc.parentAvatar || null),
        };
      });

      return ApiResponse.success(res, formatted, 'Conversations retrieved');
    }

    initMemoryData(userId);
    const list = Array.from(memoryConversations.values()).map((c) => {
      const other = (c.participants || []).find((p) => p.toString() !== userId.toString());
      return {
        ...c,
        parentId: c.parentId || (other ? other.toString() : ''),
        parentName: c.parentName || 'Parent',
      };
    });
    return ApiResponse.success(res, list, 'Conversations retrieved');
  } catch (err) {
    next(err);
  }
}

async function getMessages(req, res, next) {
  try {
    const userId = getUserId(req);
    const { conversationId } = req.params;
    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 30));
    const skip = (page - 1) * limit;

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(conversationId)) {
      const total = await Message.countDocuments({ conversation: conversationId });
      const messages = await Message.find({ conversation: conversationId })
        .populate('sender', 'name email avatar')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit);

      // Return chronological order (oldest to newest within this page)
      const chronological = messages.reverse();
      return ApiResponse.paginated(
        res,
        chronological,
        { page, limit, total, hasMore: skip + messages.length < total },
        'Messages retrieved'
      );
    }

    initMemoryData(userId);
    const msgs = memoryMessages.get(conversationId) || [];
    const reversed = [...msgs].reverse();
    const paged = reversed.slice(skip, skip + limit).reverse();
    return ApiResponse.paginated(
      res,
      paged,
      { page, limit, total: msgs.length, hasMore: skip + limit < msgs.length },
      'Messages retrieved'
    );
  } catch (err) {
    next(err);
  }
}

async function sendMessage(req, res, next) {
  try {
    const userId = getUserId(req);
    const { conversationId, text, recipientId } = req.body;

    if (!text || !text.trim()) {
      return next(new ApiError(400, 'Message text is required'));
    }

    if (isDbConnected()) {
      let convId = conversationId;
      if (!convId && recipientId) {
        let conv = await Conversation.findOne({
          participants: { $all: [userId, recipientId] },
        });
        if (!conv) {
          conv = await Conversation.create({
            participants: [userId, recipientId],
            lastMessage: text,
            lastMessageAt: new Date(),
          });
        }
        convId = conv._id;
      }

      const msg = await Message.create({
        conversation: convId,
        sender: userId,
        text: text.trim(),
      });

      await Conversation.findByIdAndUpdate(convId, {
        lastMessage: text.trim(),
        lastMessageAt: new Date(),
      });

      return ApiResponse.success(res, msg, 'Message sent', 201);
    }

    // Memory fallback
    initMemoryData(userId);
    let convId = conversationId;
    if (!convId && recipientId) {
      let found = Array.from(memoryConversations.values()).find(
        (c) => c.participants.includes(userId) && c.participants.includes(recipientId)
      );
      if (!found) {
        convId = `conv-${Date.now()}`;
        found = {
          _id: convId,
          id: convId,
          participants: [userId, recipientId],
          parentId: recipientId,
          parentName: 'Parent',
          parentAvatar: null,
          lastMessage: text.trim(),
          lastMessageAt: new Date(),
          unreadCount: 0,
        };
        memoryConversations.set(convId, found);
      } else {
        convId = found.id;
      }
    }
    convId = convId || 'conv-1';
    const msgId = `m-${Date.now()}`;
    const newMsg = {
      _id: msgId,
      id: msgId,
      conversation: convId,
      sender: userId,
      senderName: req.user?.name || 'You',
      text: text.trim(),
      createdAt: new Date(),
    };

    const existingList = memoryMessages.get(convId) || [];
    existingList.push(newMsg);
    memoryMessages.set(convId, existingList);

    const conv = memoryConversations.get(convId);
    if (conv) {
      conv.lastMessage = text.trim();
      conv.lastMessageAt = new Date();
    }

    return ApiResponse.success(res, newMsg, 'Message sent', 201);
  } catch (err) {
    next(err);
  }
}

async function markAsRead(req, res, next) {
  try {
    const userId = getUserId(req);
    const { id } = req.params;

    if (isDbConnected() && mongoose.Types.ObjectId.isValid(id)) {
      await Message.updateMany(
        { $or: [{ conversation: id }, { _id: id }], sender: { $ne: userId } },
        { status: 'read', readAt: new Date() }
      );
      return ApiResponse.success(res, { markedRead: true }, 'Messages marked as read');
    }

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
  getConversations,
  getMessages,
  sendMessage,
  markAsRead,
  list: getConversations,
  create: sendMessage,
  memoryConversations,
  memoryMessages,
};

