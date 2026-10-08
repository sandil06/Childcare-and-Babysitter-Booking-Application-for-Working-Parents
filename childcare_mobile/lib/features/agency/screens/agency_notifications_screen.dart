import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/agency_notification_model.dart';
import '../providers/agency_provider.dart';

class AgencyNotificationsScreen extends StatefulWidget {
  const AgencyNotificationsScreen({super.key});

  @override
  State<AgencyNotificationsScreen> createState() => _AgencyNotificationsScreenState();
}

class _AgencyNotificationsScreenState extends State<AgencyNotificationsScreen> {
  final AgencyProvider _provider = AgencyProvider.instance;
  String _selectedCategory = 'all';

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'label': 'All Alerts'},
    {'id': 'verification', 'label': 'Verifications'},
    {'id': 'safety', 'label': 'Safety & Reports'},
    {'id': 'system', 'label': 'System Logs'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.loadAgencyNotifications(refresh: true);
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _provider.setNotificationFilter(category);
  }

  void _showBroadcastDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedAudience = 'all';
    String selectedPriority = 'normal';
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 20,
                top: 24,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.campaign_rounded, color: AppColors.teal, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dispatch System Broadcast',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                'Broadcast announcement to app users',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Target Audience Selector
                    const Text(
                      'Target Audience',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildAudienceChip('all', 'All Users', selectedAudience, (val) {
                          setDialogState(() => selectedAudience = val);
                        }),
                        const SizedBox(width: 8),
                        _buildAudienceChip('parents', 'Parents Only', selectedAudience, (val) {
                          setDialogState(() => selectedAudience = val);
                        }),
                        const SizedBox(width: 8),
                        _buildAudienceChip('babysitters', 'Sitters Only', selectedAudience, (val) {
                          setDialogState(() => selectedAudience = val);
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Broadcast Title
                    const Text(
                      'Announcement Title',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Platform Maintenance Notice',
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Broadcast Message
                    const Text(
                      'Message Body',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: messageController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Type your message details here...',
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Priority Selector
                    Row(
                      children: [
                        const Text(
                          'Priority Level: ',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Normal'),
                          selected: selectedPriority == 'normal',
                          selectedColor: AppColors.teal.withValues(alpha: 0.15),
                          onSelected: (_) => setDialogState(() => selectedPriority = 'normal'),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('High / Urgent'),
                          selected: selectedPriority == 'high',
                          selectedColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          onSelected: (_) => setDialogState(() => selectedPriority = 'high'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSending
                            ? null
                            : () async {
                                final title = titleController.text.trim();
                                final message = messageController.text.trim();

                                if (title.isEmpty || message.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter both title and message.'),
                                      backgroundColor: Color(0xFFEF4444),
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() => isSending = true);

                                final messenger = ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(context);

                                final ok = await _provider.broadcastNotification(
                                  title: title,
                                  message: message,
                                  targetAudience: selectedAudience,
                                  priority: selectedPriority,
                                );

                                if (!mounted) return;
                                navigator.pop();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? 'Broadcast dispatched successfully to $selectedAudience.'
                                          : 'Failed to dispatch broadcast. Please try again.',
                                    ),
                                    backgroundColor:
                                        ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  ),
                                );
                              },
                        child: isSending
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Send Broadcast Now',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAudienceChip(
    String id,
    String label,
    String current,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = id == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.teal : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'System Alerts & Broadcasts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined, color: AppColors.teal),
            tooltip: 'Broadcast Alert',
            onPressed: _showBroadcastDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.campaign_rounded),
        label: const Text(
          'Broadcast Alert',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: _showBroadcastDialog,
      ),
      body: AnimatedBuilder(
        animation: _provider,
        builder: (context, _) {
          final notifications = _provider.agencyNotifications;
          final isLoading = _provider.isInitialLoading;

          return Column(
            children: [
              // Category Filter Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = cat['id'] == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            cat['label']!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? Colors.white : AppColors.ink,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.teal,
                          backgroundColor: const Color(0xFFF3F4F6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppColors.teal : Colors.transparent,
                            ),
                          ),
                          onSelected: (_) => _onCategorySelected(cat['id']!),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Notification List
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.teal),
                      )
                    : RefreshIndicator(
                        color: AppColors.teal,
                        onRefresh: () => _provider.loadAgencyNotifications(refresh: true),
                        child: notifications.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                                itemCount: notifications.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final notif = notifications[index];
                                  return _buildNotificationCard(notif);
                                },
                              ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(AgencyNotificationModel notif) {
    Color iconBg;
    Color iconColor;
    IconData iconData;

    switch (notif.category) {
      case 'verification':
        iconBg = const Color(0xFF005B60).withValues(alpha: 0.12);
        iconColor = const Color(0xFF005B60);
        iconData = Icons.verified_user_rounded;
        break;
      case 'safety':
        iconBg = const Color(0xFFEF4444).withValues(alpha: 0.12);
        iconColor = const Color(0xFFEF4444);
        iconData = Icons.warning_amber_rounded;
        break;
      default:
        iconBg = const Color(0xFF3B82F6).withValues(alpha: 0.12);
        iconColor = const Color(0xFF3B82F6);
        iconData = Icons.notifications_active_rounded;
        break;
    }

    final timeStr = notif.createdAt != null
        ? '${notif.createdAt!.day}/${notif.createdAt!.month} '
          '${notif.createdAt!.hour.toString().padLeft(2, '0')}:${notif.createdAt!.minute.toString().padLeft(2, '0')}'
        : 'Recent';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notif.isRead ? const Color(0xFFE5E7EB) : AppColors.teal.withValues(alpha: 0.3),
          width: notif.isRead ? 1 : 1.5,
        ),
        boxShadow: [
          BoxSideEffect.cardShadow,
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Avatar
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notif.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (!notif.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: const BoxDecoration(
                          color: AppColors.teal,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notif.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4B5563),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Target: ${notif.targetAudience.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 48,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Alerts Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'All platform services are operating smoothly with no pending alerts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BoxSideEffect {
  static BoxShadow get cardShadow => BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 10,
        offset: const Offset(0, 3),
      );
}
