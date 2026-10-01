import 'package:flutter/material.dart';

class ProfileBadge extends StatelessWidget {
  const ProfileBadge({super.key, required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Chip(label: Text(label));
}
