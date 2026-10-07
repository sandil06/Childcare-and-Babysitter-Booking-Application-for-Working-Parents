const mongoose = require('mongoose');
const TrackingLocation = require('../models/TrackingLocation');
const { memoryBookingLocations } = require('../controllers/trackingController');

function isDbConnected() {
  return mongoose.connection.readyState === 1;
}

function trackingSocket(socket) {
  // 1. Join Tracking Room
  const handleJoin = (bookingId, ack) => {
    if (!bookingId) return;
    const room = `booking:${bookingId}`;
    socket.join(room);
    if (typeof ack === 'function') {
      ack({ success: true, room: bookingId });
    }
  };

  socket.on('tracking:join', handleJoin);
  socket.on('join_tracking', handleJoin);

  // 2. Leave Tracking Room
  const handleLeave = (bookingId, ack) => {
    if (!bookingId) return;
    socket.leave(`booking:${bookingId}`);
    if (typeof ack === 'function') {
      ack({ success: true, room: bookingId });
    }
  };

  socket.on('tracking:leave', handleLeave);
  socket.on('leave_tracking', handleLeave);

  // 3. Babysitter Location Broadcast
  socket.on('tracking:update', async (data, ack) => {
    try {
      const { bookingId, latitude, longitude, heading = 0, speed = 0, status = 'travelling', etaMinutes } = data || {};
      if (!bookingId || latitude === undefined || longitude === undefined) {
        if (typeof ack === 'function') ack({ success: false, error: 'bookingId, latitude, and longitude are required' });
        return;
      }

      const numLat = Number(latitude);
      const numLng = Number(longitude);

      if (isDbConnected() && mongoose.Types.ObjectId.isValid(bookingId)) {
        await TrackingLocation.create({
          booking: bookingId,
          user: socket.user?.sub || socket.user?.id || null,
          latitude: numLat,
          longitude: numLng,
          heading: Number(heading),
          speed: Number(speed),
          status,
          recordedAt: new Date(),
        }).catch(() => {});
      } else {
        memoryBookingLocations.set(bookingId, {
          bookingId,
          latitude: numLat,
          longitude: numLng,
          heading: Number(heading),
          speed: Number(speed),
          status,
          etaMinutes: etaMinutes || 10,
          recordedAt: new Date(),
        });
      }

      const payload = {
        bookingId,
        latitude: numLat,
        longitude: numLng,
        heading: Number(heading),
        speed: Number(speed),
        status,
        etaMinutes: etaMinutes || 10,
        timestamp: new Date().toISOString(),
      };

      // Broadcast to all clients watching this booking (Parents)
      socket.to(`booking:${bookingId}`).emit('sitter_location_update', payload);
      socket.to(`booking:${bookingId}`).emit('tracking:update', payload);

      if (typeof ack === 'function') {
        ack({ success: true, data: payload });
      }
    } catch (err) {
      if (typeof ack === 'function') ack({ success: false, error: err.message });
    }
  });

  // 4. Status Transition Broadcast (e.g. travelling -> arrived -> in_progress -> completed)
  socket.on('tracking:status_change', (data, ack) => {
    const { bookingId, status } = data || {};
    if (!bookingId || !status) return;

    const payload = {
      bookingId,
      status,
      timestamp: new Date().toISOString(),
    };

    socket.to(`booking:${bookingId}`).emit('sitter_status_update', payload);
    socket.to(`booking:${bookingId}`).emit('tracking:status_change', payload);

    if (typeof ack === 'function') {
      ack({ success: true, status });
    }
  });
}

module.exports = trackingSocket;
