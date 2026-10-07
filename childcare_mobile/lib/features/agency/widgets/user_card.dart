import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/admin_user_model.dart';

class UserCard extends StatelessWidget {
  final AdminUserModel user;
  final VoidCallback onTap;
  final VoidCallback? onSuspend;
  final VoidCallback? onReactivate;

  const UserCard({
    super.key,
    required this.user,
    required this.onTap,
    this.onSuspend,
    this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final isSuspended = user.isSuspended;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(
          color: isSuspended ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: isSuspended ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Avatar, Name, Email, Status & Role
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _getRoleBgColor(user.role),
                      backgroundImage: user.avatar.isNotEmpty
                          ? NetworkImage(user.avatar)
                          : null,
                      child: user.avatar.isEmpty
                          ? Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _getRoleFgColor(user.role),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildRoleBadge(user.role),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user.email,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (user.phone.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              user.phone,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Status Chip
                    _buildStatusBadge(isSuspended),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Metrics row: Bookings, Rating, Member since
                Row(
                  children: [
                    _buildStatItem(
                      Icons.calendar_month_outlined,
                      '${user.totalBookings} Bookings',
                    ),
                    const SizedBox(width: 16),
                    if (user.isBabysitter) ...[
                      _buildStatItem(
                        Icons.star_rounded,
                        '${user.averageRating.toStringAsFixed(1)} Rating',
                        iconColor: const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 16),
                    ],
                    _buildStatItem(
                      Icons.history_rounded,
                      user.createdAt != null
                          ? 'Joined ${user.createdAt!.month}/${user.createdAt!.year}'
                          : 'Active',
                    ),
                  ],
                ),

                // Suspension Banner if suspended
                if (isSuspended && (user.suspensionReason?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFEE2E2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFDC2626)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Reason: ${user.suspensionReason}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFFB91C1C),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    final bg = _getRoleBgColor(role);
    final fg = _getRoleFgColor(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        user.displayRole,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isSuspended) {
    if (isSuspended) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'SUSPENDED',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFFB91C1C),
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'ACTIVE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xFF15803D),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, {Color? iconColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor ?? const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Color _getRoleBgColor(String role) {
    switch (role.toLowerCase()) {
      case 'babysitter':
        return AppColors.mint;
      case 'agency':
      case 'admin':
        return const Color(0xFFFEF3C7);
      case 'parent':
      default:
        return const Color(0xFFEEF2FF);
    }
  }

  Color _getRoleFgColor(String role) {
    switch (role.toLowerCase()) {
      case 'babysitter':
        return AppColors.teal;
      case 'agency':
      case 'admin':
        return const Color(0xFFB45309);
      case 'parent':
      default:
        return const Color(0xFF4338CA);
    }
  }
}
