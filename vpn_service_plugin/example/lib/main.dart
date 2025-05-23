import 'package:flutter/material.dart';
import 'package:vpn_service_plugin/vpn_service_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _vpnPlugin = VpnServicePlugin();
  bool _isVpnActive = false;

  Future<void> _toggleVpn() async {
    if (!_isVpnActive) {
      // 准备 VPN
      final prepareResult = await _vpnPlugin.prepareVpn();
      if (prepareResult.containsKey('errorMsg')) {
        // print('VPN 准备失败: ${prepareResult['errorMsg']}');
        return;
      }

      // 启动 VPN
      final startResult = await _vpnPlugin.startVpn(
        ipv4Addr: "10.126.126.1/24",
        dns: "114.114.114.114",
        routes: ["0.0.0.0/0"],
      );

      if (startResult.containsKey('errorMsg')) {
        // print('VPN 启动失败: ${startResult['errorMsg']}');
        return;
      }
    } else {
      // 停止 VPN
      await _vpnPlugin.stopVpn();
    }

    setState(() {
      _isVpnActive = !_isVpnActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('VPN 服务示例')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('VPN 状态: ${_isVpnActive ? "已连接" : "未连接"}'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _toggleVpn,
                child: Text(_isVpnActive ? '断开 VPN' : '连接 VPN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
