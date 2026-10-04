import 'package:flutter/material.dart';

import 'config/routes.dart';
import 'config/theme.dart';

class ChildcareApp extends StatelessWidget {
  const ChildcareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nurture',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
