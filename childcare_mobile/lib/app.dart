import 'package:flutter/material.dart';

import 'config/routes.dart';
import 'config/theme.dart';

class ChildcareApp extends StatelessWidget {
  const ChildcareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LittleHands',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      scrollBehavior: const AppScrollBehavior(),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
