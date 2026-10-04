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
          const SizedBox(height: 20),
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
            'Sign in to manage your care and booking services.',
            style: TextStyle(color: AppColors.muted, fontSize: 16),
          ),
          const SizedBox(height: 32),
          const AppTextField(label: 'Email address', hint: 'you@example.com'),
          const SizedBox(height: 16),
          const AppTextField(label: 'Password'),
          const SizedBox(height: 24),
          AppButton(
            label: 'Sign in as Babysitter',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.sitterDashboard,
              (_) => false,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (_) => false,
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: AppColors.teal),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'Sign in as Parent',
              style: TextStyle(
                color: AppColors.teal,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Are you a new babysitter? ',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.sitterRegistration),
                child: const Text(
                  'Register Here',
                  style: TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
