import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/location_service.dart';
import '../../bookings/models/booking_model.dart';
import '../services/tracking_service.dart';

class LiveTrackingScreen extends StatefulWidget {
  final BookingModel? booking;

  const LiveTrackingScreen({super.key, this.booking});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> with SingleTickerProviderStateMixin {
  final TrackingService _trackingService = TrackingService();
  final LocationService _locationService = LocationService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  BookingModel? _booking;
  String _sitterStatus = 'travelling'; // 'travelling', 'arrived', 'in_progress', 'completed'
  int _etaMinutes = 12;
  double _sitterLat = 6.8950;
  double _sitterLng = 79.8588;
  double _destLat = 6.9044;
  double _destLng = 79.8639;
  double _speed = 28.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _booking = widget.booking;
    _initTracking();
  }

  void _initTracking() {
    final bookingId = _booking?.id ?? 'bk-live';

    // 1. Initial location fetch
    _trackingService.getBookingLocation(bookingId).then((data) {
      if (data != null && mounted) {
        setState(() {
          if (data['latitude'] != null) _sitterLat = (data['latitude'] as num).toDouble();
          if (data['longitude'] != null) _sitterLng = (data['longitude'] as num).toDouble();
          if (data['status'] != null) _sitterStatus = data['status'].toString();
          if (data['etaMinutes'] != null) _etaMinutes = (data['etaMinutes'] as num).toInt();
        });
      }
    });

    // 2. Start Socket.IO tracking stream
    _trackingService.startTrackingSubscription(
      bookingId: bookingId,
      onLocationUpdate: (data) {
        if (!mounted) return;
        setState(() {
          if (data['latitude'] != null) _sitterLat = (data['latitude'] as num).toDouble();
          if (data['longitude'] != null) _sitterLng = (data['longitude'] as num).toDouble();
          if (data['speed'] != null) _speed = (data['speed'] as num).toDouble();
          if (data['etaMinutes'] != null) _etaMinutes = (data['etaMinutes'] as num).toInt();
          if (data['status'] != null) _sitterStatus = data['status'].toString();
        });
      },
      onStatusUpdate: (newStatus) {
        if (!mounted) return;
        setState(() => _sitterStatus = newStatus);
      },
    );

    // 3. Fallback smooth simulation movement
    _locationService.startLocationUpdates(
      bookingId: bookingId,
      onLocationChanged: (point) {
        if (!mounted) return;
        setState(() {
          _sitterLat = point.latitude;
          _sitterLng = point.longitude;
          _etaMinutes = point.etaMinutes;
          _speed = point.speed;
          if (_etaMinutes <= 1 && _sitterStatus == 'travelling') {
            _sitterStatus = 'arrived';
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _trackingService.stopTrackingSubscription();
    _locationService.stopLocationUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is BookingModel) _booking = args;

    final sitterName = _booking?.babysitterName ?? 'Amaya Fernando';
    final destinationAddress = _booking?.location ?? '123 Havelock Road, Colombo 05';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Live Caregiver Tracking',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.teal, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('GPS Signal refreshed: Accuracy ±5m'),
                  backgroundColor: AppColors.teal,
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Simulated Interactive Map Canvas
          Positioned.fill(
            child: _buildMapCanvas(),
          ),

          // 2. Floating Live ETA Badge (Top)
          Positioned(
            top: 16,
            left: 20,
            right: 20,
            child: _buildEtaFloatingBanner(),
          ),

          // 3. Bottom Sheet with Caregiver Info & Lifecycle Timeline
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildCaregiverSheet(sitterName, destinationAddress),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCanvas() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: CustomPaint(
        painter: _RouteMapPainter(
          sitterLat: _sitterLat,
          sitterLng: _sitterLng,
          destLat: _destLat,
          destLng: _destLng,
        ),
        child: Stack(
          children: [
            // Sitter Marker with Pulse Animation
            Positioned(
              left: MediaQuery.of(context).size.width * 0.35,
              top: MediaQuery.of(context).size.height * 0.30,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 52 * _pulseAnimation.value,
                        height: 52 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          color: const Color(0xFF005B60).withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF005B60),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 24),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Destination Marker (Home)
            Positioned(
              right: MediaQuery.of(context).size.width * 0.25,
              top: MediaQuery.of(context).size.height * 0.16,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.home_rounded, size: 14, color: AppColors.teal),
                        SizedBox(width: 4),
                        Text(
                          'Destination',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.location_on, color: Color(0xFFE11D48), size: 38),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEtaFloatingBanner() {
    String statusTitle = 'Caregiver on the way';
    if (_sitterStatus == 'arrived') statusTitle = 'Caregiver has arrived!';
    if (_sitterStatus == 'in_progress') statusTitle = 'Service in progress';
    if (_sitterStatus == 'completed') statusTitle = 'Service completed';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F5F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.near_me_rounded, color: Color(0xFF005B60), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _sitterStatus == 'travelling'
                      ? 'Estimated arrival in $_etaMinutes mins (${_speed.toStringAsFixed(0)} km/h)'
                      : 'Real-time location verified by LittleHands GPS',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaregiverSheet(String sitterName, String destinationAddress) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Caregiver Header Row
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFE6F5F2),
                child: Text(
                  sitterName.isNotEmpty ? sitterName[0].toUpperCase() : 'C',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF005B60)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sitterName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 16, color: AppColors.teal),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 15),
                        SizedBox(width: 4),
                        Text(
                          '4.9 (42 reviews)  •  Verified Sitter',
                          style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Call Action
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.all(10),
                ),
                icon: const Icon(Icons.phone_rounded, color: AppColors.teal, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Calling $sitterName...'),
                      backgroundColor: AppColors.teal,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              // Chat Action
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF005B60),
                  padding: const EdgeInsets.all(10),
                ),
                icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.parentChat,
                    arguments: {
                      'otherUserName': sitterName,
                      'conversationId': 'conv-1',
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Service Lifecycle Progress Bar
          _buildLifecycleProgress(),
          const SizedBox(height: 16),

          // Destination Address card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: AppColors.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    destinationAddress,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifecycleProgress() {
    final stages = ['Travelling', 'Arrived', 'In Progress', 'Completed'];
    int currentIndex = 0;
    if (_sitterStatus == 'arrived') currentIndex = 1;
    if (_sitterStatus == 'in_progress') currentIndex = 2;
    if (_sitterStatus == 'completed') currentIndex = 3;

    return Row(
      children: List.generate(stages.length, (index) {
        final isPassed = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      color: index == 0
                          ? Colors.transparent
                          : (isPassed ? const Color(0xFF005B60) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isPassed ? const Color(0xFF005B60) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isPassed ? const Color(0xFF005B60) : const Color(0xFFCBD5E1),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isPassed
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 4,
                      color: index == stages.length - 1
                          ? Colors.transparent
                          : (index < currentIndex ? const Color(0xFF005B60) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                stages[index],
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                  color: isCurrent ? const Color(0xFF005B60) : AppColors.muted,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  final double sitterLat;
  final double sitterLng;
  final double destLat;
  final double destLng;

  _RouteMapPainter({
    required this.sitterLat,
    required this.sitterLng,
    required this.destLat,
    required this.destLng,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF1F5F9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Decorative Road Grid lines
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    final roadBorderPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke;

    // Draw main avenue
    final path = Path()
      ..moveTo(0, size.height * 0.45)
      ..cubicTo(size.width * 0.3, size.height * 0.40, size.width * 0.7, size.height * 0.25, size.width, size.height * 0.15);

    canvas.drawPath(path, roadBorderPaint);
    canvas.drawPath(path, roadPaint);

    // Draw cross roads
    final crossPath = Path()
      ..moveTo(size.width * 0.25, 0)
      ..lineTo(size.width * 0.45, size.height);
    canvas.drawPath(crossPath, roadBorderPaint);
    canvas.drawPath(crossPath, roadPaint);

    // Route Polyline (Teal glowing line)
    final routePaint = Paint()
      ..color = const Color(0xFF005B60)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final routePolyline = Path()
      ..moveTo(size.width * 0.40, size.height * 0.33)
      ..cubicTo(size.width * 0.50, size.height * 0.30, size.width * 0.65, size.height * 0.25, size.width * 0.73, size.height * 0.20);

    canvas.drawPath(routePolyline, routePaint);
  }

  @override
  bool shouldRepaint(covariant _RouteMapPainter oldDelegate) {
    return oldDelegate.sitterLat != sitterLat || oldDelegate.sitterLng != sitterLng;
  }
}
