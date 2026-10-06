import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

enum AdminActionType { approve, reject, requestChanges, suspend, resolve }

class AdminActionDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmText;
  final Color confirmColor;
  final bool requireReason;
  final String? reasonLabel;
  final String? reasonHint;
  final IconData? icon;

  const AdminActionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    this.confirmColor = AppColors.teal,
    this.requireReason = false,
    this.reasonLabel,
    this.reasonHint,
    this.icon,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    Color confirmColor = AppColors.teal,
    bool requireReason = false,
    String? reasonLabel,
    String? reasonHint,
    IconData? icon,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminActionDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        confirmColor: confirmColor,
        requireReason: requireReason,
        reasonLabel: reasonLabel,
        reasonHint: reasonHint,
        icon: icon,
      ),
    );
  }

  @override
  State<AdminActionDialog> createState() => _AdminActionDialogState();
}

class _AdminActionDialogState extends State<AdminActionDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon Header
              if (widget.icon != null) ...[
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: widget.confirmColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      size: 28,
                      color: widget.confirmColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Title
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Reason input field if required or optional
              if (widget.requireReason || widget.reasonLabel != null) ...[
                Text(
                  widget.reasonLabel ?? 'Notes / Reason',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _controller,
                  maxLines: 3,
                  autofocus: widget.requireReason,
                  validator: (val) {
                    if (widget.requireReason && (val == null || val.trim().isEmpty)) {
                      return 'Please provide a reason or instructions.';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: widget.reasonHint ?? 'Enter administrative notes...',
                    hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: widget.confirmColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? true) {
                          Navigator.pop(context, _controller.text.trim());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.confirmColor,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        widget.confirmText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
