import 'dart:async';
import 'dart:io';

import 'package:dudulan/fun/up.dart';
import 'package:dudulan/k/database/app_data.dart';
import 'package:dudulan/k/mod/window_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dudulan/src/rust/frb_generated.dart';
import 'package:dudulan/app.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';

void main() async {
  BindingBase.debugZoneErrorsAreFatal = true;

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await AppDatabase().init();
      AppInfoUtil.init();
      await RustLib.init();

      if (!kIsWeb &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        await WindowManagerUtils.initializeWindow();
      }

      await SentryFlutter.init((options) {
        options.dsn =
            'https://8ddef9dc25ba468431473fc15187df30@o4509285217402880.ingest.de.sentry.io/4509285224087632';
      });

      runApp(const AuthGate());
    },
    (exception, stackTrace) async {
      await Sentry.captureException(exception, stackTrace: stackTrace);
    },
  );
}

/// AuthGate handles login state and session polling.
class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoggedIn = false;
  Timer? _sessionTimer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _startSessionPoll() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      final authService = AuthService();
      final result = await authService.checkSession();
      if (result == 'InvalidSession') {
        _sessionTimer?.cancel();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => LoginScreen()),
            (route) => false,
          );
        }
      }
    });
  }

  Future<void> _checkLogin() async {
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _loading = false;
      });
      if (isLoggedIn) _startSessionPoll();
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return _isLoggedIn ? const KevinApp() : MaterialApp(home: LoginScreen());
  }
}
