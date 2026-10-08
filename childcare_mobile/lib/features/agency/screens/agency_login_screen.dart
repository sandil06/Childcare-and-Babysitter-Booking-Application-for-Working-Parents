import 'package:flutter/material.dart';

import '../../auth/screens/login_screen.dart';

/// Legacy AgencyLoginScreen adapter.
/// All administrative and user logins now route through the unified [LoginScreen].
class AgencyLoginScreen extends StatelessWidget {
  const AgencyLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen();
  }
}
