import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../../babysitter/providers/babysitter_provider.dart';
import '../../babysitter/services/babysitter_service.dart';

class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  // Retain data during refresh - do not clear to null
  final Map<String, dynamic> _parentProfile = {
    'name': 'Parent',
    'email': '',
    'phone': '',
    'address': '',
    'childrenCount': 0,
    'emergencyContact': '',
    'isNicVerified': false,
    'children': <dynamic>[],
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final name = await LocalStorage.instance.read('user_name');
    final email = await LocalStorage.instance.read('user_email');
    final phone = await LocalStorage.instance.read('user_phone');
    if (mounted) {
      setState(() {
        if (name != null && name.toString().isNotEmpty) {
          _parentProfile['name'] = name.toString();
        }
        if (email != null && email.toString().isNotEmpty) {
          _parentProfile['email'] = email.toString();
        }
        if (phone != null && phone.toString().isNotEmpty) {
          _parentProfile['phone'] = phone.toString();
        }
      });
    }

    try {
      final token = await LocalStorage.instance.read('auth_token');
      if (token != null && token.toString().isNotEmpty) {
        ApiClient.authToken = token.toString();
      }
      final res = await ApiClient().get('parents/profile');
      final data = (res is Map<String, dynamic> && res['data'] != null)
          ? res['data'] as Map<String, dynamic>
          : (res is Map<String, dynamic> ? res : null);

      if (data != null && mounted) {
        setState(() {
          if (data['name'] != null && data['name'].toString().isNotEmpty) {
            _parentProfile['name'] = data['name'].toString();
          }
          if (data['email'] != null && data['email'].toString().isNotEmpty) {
            _parentProfile['email'] = data['email'].toString();
          }
          if (data['phone'] != null) {
            _parentProfile['phone'] = data['phone'].toString();
          }
          if (data['address'] != null) {
            _parentProfile['address'] = data['address'].toString();
          }
          if (data['emergencyContact'] != null) {
            _parentProfile['emergencyContact'] = data['emergencyContact'].toString();
          }
          if (data['isNicVerified'] != null) {
            _parentProfile['isNicVerified'] = data['isNicVerified'] == true;
          }
          if (data['children'] is List) {
            _parentProfile['children'] = List<dynamic>.from(data['children'] as List);
            _parentProfile['childrenCount'] = (_parentProfile['children'] as List).length;
          }
        });

        if (data['name'] != null && data['name'].toString().isNotEmpty) {
          await LocalStorage.instance.write('user_name', data['name'].toString());
        }
        if (data['phone'] != null && data['phone'].toString().isNotEmpty) {
          await LocalStorage.instance.write('user_phone', data['phone'].toString());
        }
      }
    } catch (e) {
      debugPrint('Failed to load parent profile from API: $e');
    }
  }

  Future<void> _handleRefresh() async {
    // Keep existing data visible, do not clear to null, do not show full-screen loader
    await Future.delayed(const Duration(milliseconds: 300));
    await _loadProfile();
  }

  Future<void> _updateProfileOnServer(Map<String, dynamic> updateData) async {
    try {
      final token = await LocalStorage.instance.read('auth_token');
      if (token != null && token.toString().isNotEmpty) {
        ApiClient.authToken = token.toString();
      }
      final res = await ApiClient().patch('parents/profile', body: updateData);
      final data = (res is Map<String, dynamic> && res['data'] != null)
          ? res['data'] as Map<String, dynamic>
          : (res is Map<String, dynamic> ? res : null);

      if (data != null && mounted) {
        setState(() {
          if (data['name'] != null && data['name'].toString().isNotEmpty) {
            _parentProfile['name'] = data['name'].toString();
          }
          if (data['email'] != null && data['email'].toString().isNotEmpty) {
            _parentProfile['email'] = data['email'].toString();
          }
          if (data['phone'] != null) {
            _parentProfile['phone'] = data['phone'].toString();
          }
          if (data['address'] != null) {
            _parentProfile['address'] = data['address'].toString();
          }
          if (data['emergencyContact'] != null) {
            _parentProfile['emergencyContact'] = data['emergencyContact'].toString();
          }
          if (data['isNicVerified'] != null) {
            _parentProfile['isNicVerified'] = data['isNicVerified'] == true;
          }
          if (data['children'] is List) {
            _parentProfile['children'] = List<dynamic>.from(data['children'] as List);
            _parentProfile['childrenCount'] = (_parentProfile['children'] as List).length;
          }
        });

        if (data['name'] != null && data['name'].toString().isNotEmpty) {
          await LocalStorage.instance.write('user_name', data['name'].toString());
        }
        if (data['phone'] != null && data['phone'].toString().isNotEmpty) {
          await LocalStorage.instance.write('user_phone', data['phone'].toString());
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: AppColors.teal,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    }
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _parentProfile['name'] as String? ?? '');
    final phoneCtrl = TextEditingController(text: _parentProfile['phone'] as String? ?? '');
    final addressCtrl = TextEditingController(text: _parentProfile['address'] as String? ?? '');
    final emergencyCtrl = TextEditingController(text: _parentProfile['emergencyContact'] as String? ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Family Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.sand),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      hintText: '+94 77 123 4567',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Home Address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      hintText: 'City / Street Address',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: emergencyCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Contact Phone',
                      prefixIcon: Icon(Icons.contact_phone_outlined),
                      hintText: '+94 71 234 5678',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        Navigator.pop(ctx);
                        await _updateProfileOnServer({
                          'name': nameCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'address': addressCtrl.text.trim(),
                          'emergencyContact': emergencyCtrl.text.trim(),
                        });
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddChildDialog() {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Add Child',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Child's Name",
                    prefixIcon: Icon(Icons.child_care_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Enter child's name" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age (years)',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Routines',
                    prefixIcon: Icon(Icons.notes_rounded),
                    hintText: 'e.g., Needs afternoon nap',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                final currentChildren = List<dynamic>.from((_parentProfile['children'] as List?) ?? []);
                currentChildren.add({
                  'name': nameCtrl.text.trim(),
                  'age': ageCtrl.text.trim(),
                  'notes': notesCtrl.text.trim(),
                });
                await _updateProfileOnServer({'children': currentChildren});
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _confirmRemoveChild(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove Child',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        content: const Text(
          'Are you sure you want to remove this child from your family profile?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final currentChildren = List<dynamic>.from((_parentProfile['children'] as List?) ?? []);
              if (index < currentChildren.length) {
                currentChildren.removeAt(index);
                await _updateProfileOnServer({'children': currentChildren});
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.coral,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log Out',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
        ),
        content: const Text('Are you sure you want to log out of LittleHands?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await LocalStorage.instance.remove('auth_token');
              await LocalStorage.instance.remove('user_name');
              await LocalStorage.instance.remove('user_email');
              await LocalStorage.instance.remove('user_phone');
              await LocalStorage.instance.remove('user_id');
              await LocalStorage.instance.remove('user_role');
              ApiClient.authToken = null;
              BabysitterService.clearCurrentProfile();
              BabysitterProvider.instance.reset();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (_) => false,
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.coral,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  String _initialsFromName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'P';
    final parts = trimmed.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Family Profile',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.coral),
            tooltip: 'Log Out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: RefreshIndicator(
          displacement: 20,
          edgeOffset: 0,
          onRefresh: _handleRefresh,
          color: AppColors.teal,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.pagePadding,
              vertical: 16,
            ),
            children: [
              // Profile Header Card
              _buildHeaderCard(),
              const SizedBox(height: 16),

              // Verification Badge Card
              _buildVerificationCard(),
              const SizedBox(height: 16),

              // Children Section
              _buildChildrenCard(),
              const SizedBox(height: 16),

              // Contact & Address Card
              _buildContactCard(),
              const SizedBox(height: 24),

              // Sitter Mode Switcher
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.sitterDashboard),
                  icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.teal),
                  label: const Text(
                    'Switch to Sitter Mode',
                    style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.teal),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final name = (_parentProfile['name'] as String?)?.trim() ?? 'Parent';
    final email = (_parentProfile['email'] as String?)?.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.mint,
            child: Text(
              _initialsFromName(name),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.teal,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'Parent',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F5F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Parent Account • Sri Lanka',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF005B60),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    final isNicVerified = _parentProfile['isNicVerified'] == true;
    final phone = (_parentProfile['phone'] as String?)?.trim() ?? '';
    final hasPhone = phone.isNotEmpty;
    final emergency = (_parentProfile['emergencyContact'] as String?)?.trim() ?? '';
    final hasEmergency = emergency.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security_rounded, size: 20, color: AppColors.teal),
              SizedBox(width: 8),
              Text(
                'Trust & Verification',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.sand),
          _buildStatusRow(
            'National Identity Card (NIC)',
            isNicVerified ? 'Verified' : 'Pending',
            isVerified: isNicVerified,
          ),
          const SizedBox(height: 10),
          _buildStatusRow(
            'Sri Lanka Phone Number',
            hasPhone ? 'Verified' : 'Not Linked',
            isVerified: hasPhone,
          ),
          const SizedBox(height: 10),
          _buildStatusRow(
            'Emergency Contact Linked',
            hasEmergency ? 'Verified' : 'Not Linked',
            isVerified: hasEmergency,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status, {bool isVerified = true}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isVerified ? const Color(0xFFE6F5F2) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isVerified ? const Color(0xFF005B60) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChildrenCard() {
    final children = (_parentProfile['children'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Children Information',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Row(
                children: [
                  Text(
                    children.isEmpty
                        ? '0 registered'
                        : (children.length == 1
                            ? '1 registered'
                            : '${children.length} registered'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showAddChildDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.sand),
          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.child_care_rounded, size: 20, color: AppColors.muted),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No children registered yet. Tap + to add child details.',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            )
          else
            ...children.asMap().entries.map((entry) {
              final index = entry.key;
              final child = entry.value;
              final childMap = child is Map ? child : <String, dynamic>{};
              final name = childMap['name']?.toString() ?? 'Child';
              final age = childMap['age']?.toString() ?? '';
              final notes = childMap['notes']?.toString() ?? '';
              final ageText = age.isNotEmpty ? '$age years old' : '';
              final sub = [ageText, notes].where((s) => s.isNotEmpty).join(' · ');

              return Padding(
                padding: EdgeInsets.only(bottom: index < children.length - 1 ? 12.0 : 0),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.child_care_rounded, size: 20, color: AppColors.teal),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sub.isNotEmpty ? sub : 'No notes provided',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.coral),
                      tooltip: 'Remove Child',
                      onPressed: () => _confirmRemoveChild(index),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    final phone = (_parentProfile['phone'] as String?)?.trim() ?? '';
    final address = (_parentProfile['address'] as String?)?.trim() ?? '';
    final emergency = (_parentProfile['emergencyContact'] as String?)?.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Contact Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              InkWell(
                onTap: _showEditProfileDialog,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 14, color: AppColors.teal),
                      SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.sand),
          _buildDetailRow(
            Icons.phone_outlined,
            'Phone',
            phone.isNotEmpty ? phone : 'Not provided',
          ),
          const SizedBox(height: 14),
          _buildDetailRow(
            Icons.location_on_outlined,
            'Home Address',
            address.isNotEmpty ? address : 'Not provided',
          ),
          const SizedBox(height: 14),
          _buildDetailRow(
            Icons.contact_phone_outlined,
            'Emergency Contact',
            emergency.isNotEmpty ? emergency : 'Not provided',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.teal),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
