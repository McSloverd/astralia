mport 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../screens/login_screen.dart';

class AuthService {
  static final _storage = FlutterSecureStorage();
  static const _apiBase = 'http://localhost:3000/api'; // Adjust to your server address

  // Check if user is logged in (token exists)
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    return token != null;
  }

  // Login with username and password
  Future login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_apiBase/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'kicked') {
        return 'kicked';
      }
      if (data['token'] != null) {
        await _storage.write(key: 'token', value: data['token']);
        return true;
      }
      return false;
    } else if (response.statusCode == 403) {
      final data = jsonDecode(response.body);
      return data['error'] ?? "Account not allowed to login.";
    } else if (response.statusCode == 401) {
      return "Invalid username or password.";
    }
    return false;
  }

  // Register a new user
  Future register(String username, String password, String confirm) async {
    if (password != confirm) return "Passwords do not match.";
    final response = await http.post(
      Uri.parse('$_apiBase/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 201) {
      return true;
    } else {
      final data = jsonDecode(response.body);
      return data['error'] ?? "Failed to register.";
    }
  }

  // Check if a username is available
  Future<bool> checkUsername(String username) async {
    final response = await http.get(
      Uri.parse('$_apiBase/check-username?username=$username'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['available'] == true;
    }
    return false;
  }

  // Logout user
  Future logout() async {
    await _storage.delete(key: 'token');
  }

  /// Logs out and navigates to the login screen, clearing the navigation stack.
  Future<void> logoutAndGoToLogin(BuildContext context) async {
    await logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    }
  }

  // Check session validity (for polling or background checks)
  Future<String?> checkSession() async {
    final token = await _storage.read(key: 'token');
    if (token == null) return 'NoToken';
    final response = await http.get(
      Uri.parse('$_apiBase/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return null; // Session OK
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      // Session invalid, deactivated, expired, or kicked out
      await logout();
      return 'InvalidSession';
    }
    return 'UnknownError';
  }

  /// Example of a protected API call that will log out and navigate to login if session is invalid
  Future<bool> someProtectedCall(BuildContext context) async {
    final token = await _storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('$_apiBase/some-protected-endpoint'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 401 || response.statusCode == 403) {
      await logoutAndGoToLogin(context);
      return false;
    }
    if (response.statusCode == 200) {
      // Handle your logic here
      return true;
    }
    // Optionally handle other status codes as needed
    return false;
  }
}
