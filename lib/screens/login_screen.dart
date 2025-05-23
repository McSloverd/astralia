import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final authService = AuthService();
      final result = await authService.login(
        _usernameController.text,
        _passwordController.text,
      );
      if (result == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainScreen()),
        );
      } else if (result == 'kicked') {
        setState(() {
          _error =
              'You have been logged out because your account was used elsewhere.';
        });
      } else {
        setState(() {
          _error = "Invalid username or password.";
        });
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('登录')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null)
                  Text(_error!, style: TextStyle(color: Colors.red)),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: "用户名"),
                  validator: (v) =>
                      v == null || v.isEmpty ? "请填写您的用户名" : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: "密码"),
                  obscureText: true,
                  validator: (v) =>
                      v == null || v.isEmpty ? "请填写您的密码" : null,
                ),
                SizedBox(height: 24),
                _loading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login, child: Text("登录")),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => RegisterScreen()),
                    );
                  },
                  child: Text("还没有账户？这里注册一个吧！"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
