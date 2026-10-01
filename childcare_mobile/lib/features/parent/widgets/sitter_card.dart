import 'package:flutter/material.dart';

class SitterCard extends StatelessWidget {
  const SitterCard({super.key, required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => ListTile(title: Text(name));
}
