import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../providers/agency_provider.dart';
import '../widgets/admin_action_dialog.dart';

class BookingMonitoringScreen extends StatefulWidget {
  const BookingMonitoringScreen({super.key});

  @override
  State<BookingMonitoringScreen> createState() => _BookingMonitoringScreenState();
}

class _BookingMonitoringScreenState extends State<BookingMonitoringScreen> {
  late final AgencyProvider _provider;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _selectedStatus = 'all';

  final List<Map<String, String>> _statusTabs = const [
    {'label': 'All', 'value': 'all'},
    {'label': 'Confirmed', 'value': 'confirmed'},
    {'label': 'In Progress', 'value': 'in_progress'},
    {'label': 'Completed', 'value': 'completed'},
    {'label': 'Cancelled', 'value': 'cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _provider = AgencyProvider.instance;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.loadBookings(refresh: true);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _provider.loadBookings(status: _selectedStatus, search: query.trim());
    });
  }

  void _onStatusTabSelected(String status) {
    setState(() => _selectedStatus = status);
    _provider.loadBookings(status: status, search: _searchController.text.trim());
  }

  void _showBookingDetails(Map<String, dynamic> b) {
    final status = b['status']?.toString() ?? 'pending';
    final isCancelled = status == 'cancelled';
    final isActive = status == 'confirmed' || status == 'in_progress';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Booking Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b['bookingId'] ?? '#BK-900',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Scheduled for ${b['date'] ?? 'Upcoming'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusPill(status),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 12),

              // Parties Involved
              Row(
                children: [
                  Expanded(
                    child: _buildPartyTile(
                      role: 'Parent',
                      name: b['parentName'] ?? 'Parent',
                      phone: b['parentPhone'] ?? '+94 77 445 5667',
                      color: const Color(0xFF4338CA),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPartyTile(
                      role: 'Babysitter',
                      name: b['babysitterName'] ?? 'Babysitter',
                      phone: b['babysitterPhone'] ?? '+94 77 123 4567',
                      color: AppColors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Time & Address
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildRowDetail(
                      Icons.access_time_rounded,
                      'Time Window',
                      '${b['startTime'] ?? '09:00 AM'} - ${b['endTime'] ?? '01:00 PM'} (${b['durationHours'] ?? 4} hrs)',
                    ),
                    const SizedBox(height: 8),
                    _buildRowDetail(
                      Icons.location_on_outlined,
                      'Location',
                      b['address'] ?? 'Colombo 07, Sri Lanka',
                    ),
                    if (b['notes'] != null && b['notes'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildRowDetail(
                        Icons.notes_rounded,
                        'Parent Instructions',
                        b['notes'].toString(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Financial Breakdown Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  children: [
                    _buildFeeRow('Caregiver Subtotal', 'LKR ${b['subtotal'] ?? 6000}'),
                    const SizedBox(height: 6),
                    _buildFeeRow('Platform Service Fee (10%)', 'LKR ${b['serviceFee'] ?? 600}'),
                    const Divider(height: 14, color: Color(0xFF86EFAC)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Paid via Stripe',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF166534)),
                        ),
                        Text(
                          'LKR ${b['totalAmount'] ?? 6600}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF166534)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (isCancelled) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cancelled: ${b['cancellationReason'] ?? 'Cancelled by administrator'}',
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Admin Intervention
              if (isActive) ...[
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final reason = await AdminActionDialog.show(
                      context,
                      title: 'Cancel Booking',
                      message: 'Are you sure you want to cancel booking ${b['bookingId']}? Both parties will be notified and any test hold released.',
                      confirmText: 'Confirm Cancellation',
                      confirmColor: const Color(0xFFDC2626),
                      icon: Icons.cancel_schedule_send_rounded,
                      requireReason: true,
                      reasonLabel: 'Administrative Reason *',
                    );

                    if (reason != null && reason.isNotEmpty) {
                      final ok = await _provider.cancelBooking(b['id'] ?? b['_id'], reason: reason);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok ? 'Booking cancelled by admin.' : 'Failed to cancel booking.'),
                            backgroundColor: ok ? AppColors.teal : Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFDC2626)),
                  label: const Text('Admin Emergency Cancellation', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPartyTile({required String role, required String name, required String phone, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(role, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(
            name,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            phone,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRowDetail(IconData icon, String title, String val) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: '$title: ',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              children: [
                TextSpan(
                  text: val,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeeRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155))),
        Text(amount, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
      ],
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color fg;
    String text;

    switch (status.toLowerCase()) {
      case 'confirmed':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0284C7);
        text = 'CONFIRMED';
        break;
      case 'in_progress':
        bg = AppColors.mint;
        fg = AppColors.teal;
        text = 'IN PROGRESS';
        break;
      case 'completed':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        text = 'COMPLETED';
        break;
      case 'cancelled':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        text = 'CANCELLED';
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        text = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _provider,
      builder: (context, _) {
        final bookings = _provider.bookings;
        final isLoading = _provider.isInitialLoading;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text(
              'Booking Monitoring',
              style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 18),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.teal),
                onPressed: () => _provider.loadBookings(refresh: true, status: _selectedStatus),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search & Filter Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search by booking ID, parent, or sitter...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radius),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _statusTabs.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final tab = _statusTabs[index];
                          final isSelected = _selectedStatus == tab['value'];

                          return ChoiceChip(
                            label: Text(tab['label']!),
                            selected: isSelected,
                            onSelected: (_) => _onStatusTabSelected(tab['value']!),
                            selectedColor: AppColors.teal,
                            backgroundColor: const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 12.5,
                            ),
                            elevation: 0,
                            pressElevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: isSelected ? AppColors.teal : const Color(0xFFCBD5E1),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Counter Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFF1F5F9),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${bookings.length} Bookings found',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                    const Text('Live Activity Feed', style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),

              // Booking List
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                    : bookings.isEmpty
                        ? const Center(
                            child: Text('No bookings match your filter.', style: TextStyle(color: AppColors.muted)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: bookings.length,
                            itemBuilder: (context, index) {
                              final b = bookings[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppSizes.radius),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  onTap: () => _showBookingDetails(b),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              b['bookingId'] ?? '#BK-900',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _buildStatusPill(b['status']?.toString() ?? 'confirmed'),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.people_alt_outlined, size: 14, color: Color(0xFF64748B)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '${b['parentName'] ?? 'Parent'} ➔ ${b['babysitterName'] ?? 'Sitter'}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${b['date'] ?? 'Upcoming'} • ${b['startTime'] ?? '09:00 AM'}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'LKR ${b['totalAmount'] ?? 6000}',
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.teal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
