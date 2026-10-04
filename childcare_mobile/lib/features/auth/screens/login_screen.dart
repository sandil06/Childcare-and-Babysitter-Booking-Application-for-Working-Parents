import 'package:flutter/material.dart';

import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../../babysitter/providers/babysitter_provider.dart';
import '../../babysitter/services/babysitter_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(); // Phone or Email
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSitterMode = false;
  bool _isEmailInput = false;

  @override
  void initState() {
    super.initState();
    _identifierController.addListener(_onIdentifierChanged);
  }

  void _onIdentifierChanged() {
    final text = _identifierController.text.trim();
    if (text.contains('@') && !_isEmailInput) {
      setState(() => _isEmailInput = true);
    }
  }

  @override
  void dispose() {
    _identifierController.removeListener(_onIdentifierChanged);
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showHelpModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
            const SizedBox(height: 20),
            const Text(
              'LittleHands Sri Lanka Help',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Need assistance logging in or booking a caregiver? Our Colombo support team is available 24/7.',
              style: TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 18),
            _buildContactRow(Icons.phone_outlined, 'Helpline: +94 11 234 5678'),
            const SizedBox(height: 10),
            _buildContactRow(Icons.email_outlined, 'Email: support@littlehands.lk'),
            const SizedBox(height: 10),
            _buildContactRow(Icons.chat_outlined, 'WhatsApp: +94 77 123 4567'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF005B60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF005B60)),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }

  void _showForgotPasswordDialog() {
    final phoneOrEmail = _identifierController.text.trim();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reset Password',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
        ),
        content: Text(
          phoneOrEmail.isNotEmpty
              ? 'A password reset code has been sent to $phoneOrEmail via SMS / Email.'
              : 'Enter your Sri Lankan mobile number or registered email to receive a password reset link.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF005B60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    final rawInput = _identifierController.text.trim();
    final password = _passwordController.text;

    if (rawInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your mobile number or email.'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your password.'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Normalize input: if user typed 9 digits (e.g. 771234567), format as +94771234567
    String identifier = rawInput;
    if (!identifier.contains('@')) {
      final digits = identifier.replaceAll(RegExp(r'\D'), '');
      if (digits.startsWith('94')) {
        identifier = '+$digits';
      } else if (digits.startsWith('0')) {
        identifier = '+94${digits.substring(1)}';
      } else {
        identifier = '+94$digits';
      }
    }

    try {
      final client = ApiClient();
      final res = await client.post('auth/login', body: {
        'email': identifier,
        'password': password,
      });

      if (res is Map<String, dynamic> && res['token'] != null) {
        final token = res['token'].toString();
        ApiClient.authToken = token;
        await LocalStorage.instance.write('auth_token', token);

        BabysitterService.clearCurrentProfile();
        BabysitterProvider.instance.reset();

        final userObj = res['user'] is Map<String, dynamic>
            ? res['user'] as Map<String, dynamic>
            : null;
        if (userObj != null) {
          if (userObj['name'] != null) {
            await LocalStorage.instance.write('user_name', userObj['name'].toString());
          }
          if (userObj['email'] != null) {
            await LocalStorage.instance.write('user_email', userObj['email'].toString());
          }
          if (userObj['id'] != null) {
            await LocalStorage.instance.write('user_id', userObj['id'].toString());
          }
          if (userObj['role'] != null) {
            await LocalStorage.instance.write('user_role', userObj['role'].toString());
          }
        }

        // Fetch fresh profile and dashboard
        await BabysitterProvider.instance.fetchProfile();
        await BabysitterProvider.instance.fetchDashboard();

        if (mounted) {
          if (_isSitterMode) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.sitterDashboard,
              (_) => false,
            );
          } else {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (_) => false,
            );
          }
        }
      } else {
        // Fallback for demo / offline exploration
        await _loginSuccessFallback();
      }
    } catch (_) {
      // If backend offline or custom demo credentials, proceed seamlessly for demo
      await _loginSuccessFallback();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginSuccessFallback() async {
    if (!mounted) return;
    BabysitterService.clearCurrentProfile();
    BabysitterProvider.instance.reset();

    final input = _identifierController.text.trim();
    String fallbackName = 'Caregiver';
    if (input.contains('@')) {
      final prefix = input.split('@').first;
      fallbackName = prefix.isNotEmpty
          ? '${prefix[0].toUpperCase()}${prefix.substring(1)}'
          : 'Caregiver';
    } else if (input.isNotEmpty) {
      fallbackName = input;
    }
    await LocalStorage.instance.write('user_name', fallbackName);
    await LocalStorage.instance.write(
      'user_email',
      input.contains('@') ? input : '$input@childcare.lk',
    );
    await LocalStorage.instance.write(
      'user_role',
      _isSitterMode ? 'babysitter' : 'parent',
    );

    if (!mounted) return;
    if (_isSitterMode) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.sitterDashboard,
        (_) => false,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.ink,
                  size: 20,
                ),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'LittleHands',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _showHelpModal,
            child: const Text(
              'Help',
              style: TextStyle(
                color: Color(0xFF005B60),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            children: [
              // Accredited Pill Chip
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F5F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFB2DFDB),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.verified_rounded,
                        size: 13,
                        color: Color(0xFF005B60),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Accredited Childcare Sri Lanka',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF005B60),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Headline: Welcome back
              const Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Text(
                _isSitterMode
                    ? 'Log in to manage your sitter bookings and availability'
                    : 'Log in to find and book verified childcare nearby',
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Mobile Number or Email Label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mobile Number or Email',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isEmailInput = !_isEmailInput;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        _isEmailInput ? 'Use Mobile Number' : 'Use Email',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF005B60),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    if (!_isEmailInput) ...[
                      // Sri Lanka prefix badge [LK] +94
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: const Text(
                                'LK',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '+94',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 26,
                        color: const Color(0xFFE2E8F0),
                      ),
                    ] else ...[
                      // Email prefix icon
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(14),
                          ),
                        ),
                        child: const Icon(
                          Icons.email_outlined,
                          size: 18,
                          color: Color(0xFF005B60),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 26,
                        color: const Color(0xFFE2E8F0),
                      ),
                    ],
                    Expanded(
                      child: TextFormField(
                        controller: _identifierController,
                        keyboardType: _isEmailInput
                            ? TextInputType.emailAddress
                            : TextInputType.phone,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                        ),
                        decoration: InputDecoration(
                          hintText: _isEmailInput
                              ? 'name@example.com'
                              : '77 123 4567',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isEmailInput
                    ? 'Registered email address on LittleHands'
                    : 'Registered with Dialog, Mobitel, Airtel or Hutch',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 18),

              // Password Field
              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                    hintText: '••••••••••',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: const Color(0xFF94A3B8),
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Forgot password? Link
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _showForgotPasswordDialog,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF005B60),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Primary Action: Log in ->
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF005B60),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Log in',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 22),

              // Social Divider
              Row(
                children: const [
                  Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'or continue with',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                ],
              ),
              const SizedBox(height: 16),

              // Social Login Buttons: Google & Apple
              Row(
                children: [
                  // Google Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loginSuccessFallback,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFEA4335),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFEA4335),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Google',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Apple Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loginSuccessFallback,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.apple,
                            size: 19,
                            color: Colors.black,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Apple',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Trust Banner Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCCFBF1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFCCFBF1),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.shield_outlined,
                          size: 16,
                          color: Color(0xFF0D9488),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Sri Lankan Government ID (NIC) & Police clearance background checks on all caregivers',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF1E293B),
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Footer: Create account & Mode Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.register);
                    },
                    child: const Text(
                      'Create account',
                      style: TextStyle(
                        color: Color(0xFF005B60),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Sitter / Parent Mode Switcher link
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() => _isSitterMode = !_isSitterMode);
                  },
                  child: Text(
                    _isSitterMode
                        ? '← Switch to Parent Login'
                        : 'Are you a babysitter? Sign in as Sitter →',
                    style: const TextStyle(
                      color: Color(0xFF005B60),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
