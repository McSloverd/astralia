import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static final _storage = FlutterSecureStorage();
  static const _apiBase = 'http://localhost:3000/api'; // Change to your server address

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    return token != null;
  }

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
    }
    return false;
  }

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

  Future logout() async {
    await _storage.delete(key: 'token');
  }
}
