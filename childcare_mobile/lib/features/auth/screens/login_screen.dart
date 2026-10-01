import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 30),
          const Text(
            'Welcome back',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign in to keep your care plans close.',
            style: TextStyle(color: AppColors.muted, fontSize: 16),
          ),
          const SizedBox(height: 36),
          const AppTextField(label: 'Email address', hint: 'you@example.com'),
          const SizedBox(height: 16),
          const AppTextField(label: 'Password'),
          const SizedBox(height: 24),
          AppButton(
            label: 'Sign in',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (_) => false,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('Forgot password?'),
            ),
          ),
        ],
      ),
    );
  }
}
