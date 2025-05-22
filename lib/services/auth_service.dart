import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
// Conditional import for storage
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login_screen.dart';

// Cross-platform storage abstraction
class _CrossPlatformStorage {
  static final _secureStorage = FlutterSecureStorage();

  Future<void> write({required String key, required String value}) async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux) {
      await _secureStorage.write(key: key, value: value);
    } else if (Platform.isWindows) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    }
  }

  Future<String?> read({required String key}) async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux) {
      return await _secureStorage.read(key: key);
    } else if (Platform.isWindows) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
    return null;
  }

  Future<void> delete({required String key}) async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux) {
      await _secureStorage.delete(key: key);
    } else if (Platform.isWindows) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    }
  }
}

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _usernameKey = 'username';
  static final _storage = _CrossPlatformStorage();
  static const _apiBase = 'http://localhost:3000/api'; // Adjust to your server address

  // Save login session and username
  Future<void> saveLoginSession(String token, String username) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _usernameKey, value: username);
  }

  // Clear session data
  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _usernameKey);
  }

  // Retrieve the authentication token
  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  // Retrieve the stored username
  Future<String?> getCurrentUsername() async {
    return _storage.read(key: _usernameKey);
  }

  // Check if user is logged in (token exists)
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
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
      if (data['token'] != null && data['username'] != null) {
        // Save both token and username
        await saveLoginSession(data['token'], data['username']);
        return true;
      }
      // Legacy: save token only if username not provided (fallback, but should always send username)
      if (data['token'] != null) {
        await _storage.write(key: _tokenKey, value: data['token']);
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
    await clearSession();
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
    final token = await getToken();

    if (token == null) return 'NoToken';
    final response = await http.get(
      Uri.parse('$_apiBase/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      // Optionally update username if your API returns it:
      try {
        final data = jsonDecode(response.body);
        if (data['username'] != null) {
          await _storage.write(key: _usernameKey, value: data['username']);
        }
      } catch (_) {}
      return null; // Session OK
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      await logout();
      return 'InvalidSession';
    }
    return 'UnknownError';
  }

  /// Example of a protected API call that will log out and navigate to login if session is invalid
  Future<bool> someProtectedCall(BuildContext context) async {
    final token = await getToken();
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
