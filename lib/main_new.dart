import 'package:flutter/material.dart';
import 'dart:async';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DUDU LAN',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoggedIn = false;
  Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _startSessionPoll() {
    // Poll every 20 seconds
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(Duration(seconds: 20), (_) async {
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
    return _isLoggedIn ? MainScreen() : LoginScreen();
  }
}
