import 'dart:convert';
import 'dart:io';
import 'package:dudulan/k/app_s/aps.dart';
// import 'package:flutter/foundation.dart';

Future getIpv4AndIpV6Addresses() async {
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('https://ipw.cn/'));
    final response = await request.close();
    if (response.statusCode == HttpStatus.ok) {
      // print('Failed to get public IPv6: HTTP ${response.statusCode}');
      final publicIPv6 = await response.transform(utf8.decoder).join();
      if (publicIPv6.isNotEmpty) {
        Aps().ipv6.value = response.statusCode.toString();
      }
    }
  } catch (e) {
    // print('Error fetching public IPv6: $e');
  }
}
