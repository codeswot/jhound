import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'presentation/providers/lock_provider.dart';
import 'presentation/screens/home_shell.dart';
import 'presentation/screens/lock_screen.dart';
import 'presentation/screens/pin_setup_screen.dart';
import 'presentation/widgets/expressive_loader.dart';

class _HapticObserver extends NavigatorObserver {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    HapticFeedback.selectionClick();
  }
}

class JHoundApp extends ConsumerWidget {
  const JHoundApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lock = ref.watch(lockProvider);

    Widget body;
    if (lock.loading) {
      body = const _Splash();
    } else if (!lock.hasPin) {
      body = const PinSetupScreen();
    } else if (!lock.isUnlocked) {
      body = const LockScreen();
    } else {
      body = const HomeShell();
    }

    return MaterialApp(
      title: 'jHound',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: body,
      navigatorObservers: [_HapticObserver()],
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: ExpressiveLoader()));
  }
}
