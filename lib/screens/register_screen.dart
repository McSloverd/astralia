import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

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
  bool? _usernameAvailable;
  bool _checkingUsername = false;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_usernameAvailable != true) {
      setState(() {
        _error = "Please check username availability first.";
      });
      return;
    }
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
        _error = result is String ? result : "Registration failed.";
      });
    }
    setState(() {
      _loading = false;
    });
  }

  void _checkUsername() async {
    String username = _usernameController.text;
    if (username.isEmpty) {
      setState(() {
        _usernameAvailable = null;
      });
      return;
    }
    setState(() {
      _checkingUsername = true;
      _usernameAvailable = null;
    });
    final authService = AuthService();
    final available = await authService.checkUsername(username);
    setState(() {
      _usernameAvailable = available;
      _checkingUsername = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Color? availabilityColor;
    String? availabilityText;
    if (_usernameAvailable != null) {
      availabilityColor = _usernameAvailable! ? Colors.green : Colors.red;
      availabilityText = _usernameAvailable!
          ? "Username is available."
          : "Username is already taken.";
    }
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
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
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(labelText: "Username"),
                        validator: (v) =>
                            v == null || v.isEmpty ? "Enter a username" : null,
                        onChanged: (_) {
                          setState(() {
                            _usernameAvailable = null;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    _checkingUsername
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : ElevatedButton(
                            onPressed: _checkUsername,
                            child: Text("Check"),
                          ),
                  ],
                ),
                if (availabilityText != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      availabilityText,
                      style: TextStyle(color: availabilityColor),
                    ),
                  ),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: "Password"),
                  obscureText: true,
                  validator: (v) =>
                      v == null || v.isEmpty ? "Enter a password" : null,
                ),
                TextFormField(
                  controller: _confirmController,
                  decoration: InputDecoration(labelText: "Confirm Password"),
                  obscureText: true,
                  validator: (v) => v != _passwordController.text
                      ? "Passwords do not match"
                      : null,
                ),
                SizedBox(height: 24),
                _loading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _register, child: Text("Register")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
