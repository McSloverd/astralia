import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _error;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final authService = AuthService();
    final result = await authService.register(
      _usernameController.text,
      _passwordController.text,
      _confirmController.text,
    );
    if (result == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    } else {
      setState(() {
        _error = result is String ? result : "注册失败了...";
      });
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('注册')),
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
                      v == null || v.isEmpty ? "填写您的用户名" : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: "密码"),
                  obscureText: true,
                  validator: (v) =>
                      v == null || v.isEmpty ? "填写您的密码" : null,
                ),
                TextFormField(
                  controller: _confirmController,
                  decoration: InputDecoration(labelText: "确认您的密码"),
                  obscureText: true,
                  validator: (v) => v != _passwordController.text
                      ? "两次密码输入不一致"
                      : null,
                ),
                SizedBox(height: 24),
                _loading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _register, child: Text("注册")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
