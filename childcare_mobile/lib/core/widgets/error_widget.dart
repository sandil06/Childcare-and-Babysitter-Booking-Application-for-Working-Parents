import 'package:flutter/material.dart';

class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({super.key, this.message = 'Something went wrong.'});

  final String message;

  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}
