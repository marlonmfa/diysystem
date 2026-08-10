import 'package:flutter/material.dart';

import 'src/app_controller.dart';
import 'src/services/app_store.dart';
import 'src/theme.dart';
import 'src/ui/auth_screens.dart';
import 'src/ui/studio_screen.dart';
import 'src/ui/system_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await AppStore.open();
  final controller = AppController(store: store);
  runApp(DiySystemApp(controller: controller));
  await controller.initialize();
}

class DiySystemApp extends StatelessWidget {
  const DiySystemApp({required this.controller, super.key});
  final AppController controller;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DIY System',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    home: AnimatedBuilder(
      animation: controller,
      builder: (context, _) => switch (controller.phase) {
        AppPhase.loading => const _LoadingScreen(),
        AppPhase.setup => SetupScreen(controller: controller),
        AppPhase.login => LoginScreen(controller: controller),
        AppPhase.studio => StudioScreen(controller: controller),
        AppPhase.system => SystemScreen(controller: controller),
      },
    ),
  );
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: SizedBox.square(
        dimension: 34,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    ),
  );
}
