import 'dart:io';

import 'package:dudulan/src/rust/api/simple.dart';
import 'package:dudulan/wid/home_box.dart';
import 'package:flutter/material.dart';
import 'package:dudulan/k/app_s/aps.dart';
import 'package:vpn_service_plugin/vpn_service_plugin.dart';

class Bugcs extends StatefulWidget {
  const Bugcs({super.key});

  @override
  State<Bugcs> createState() => _BugcsState();
}

class _BugcsState extends State<Bugcs> {
  final Aps _aps = Aps();
  double _progress = 0.0;
  bool _isConnecting = false; // 新增独立状态变量
  bool _isHovered = false; // 添加悬浮状态变量

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: HomeBox(
        widthSpan: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 添加一个容器来显示悬浮效果
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isHovered ? colorScheme.primary : Colors.transparent,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await _initializeServer({
                        'roomName': 'default',
                        'password': '22222',
                      });
                    },
                    child: const Text('初始化服务器'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final vpnPlugin = Platform.isAndroid ? VpnServicePlugin() : null;
                      vpnPlugin?.prepareVpn();
                    },
                    child: const Text('测试VPN服务创建'),
                  ),
                  // 新增测试动画按钮
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _progress = 0.0;
                        _isConnecting = true;
                      });
                    },
                    child: const Text('测试状态切换'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Future.delayed(Duration(seconds: 5), () {
                        setState(() {
                          _isConnecting = false;
                        });
                      });
                    },
                    child: const Text('测试定时器'),
                  ),
                  SizedBox(
                    height: 14,
                    width: 180,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 300),
                      offset: _isConnecting ? Offset.zero : const Offset(0, 1.0),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _isConnecting ? 1.0 : 0.0,
                        child: Container(
                          width: 180,
                          height: 6,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey('progress_$_isConnecting'),
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(seconds: 10),
                            curve: Curves.easeInOut,
                            builder: (context, value, _) {
                              _progress = value * 100;
                              return FractionallySizedBox(
                                widthFactor: value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        colorScheme.tertiary,
                                        colorScheme.primary,
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 新增方块移动逻辑
                  SizedBox(
                    height: 50,
                    width: 180,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 300),
                      offset: _isConnecting ? Offset.zero : const Offset(0, 1.0),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _initializeServer(dynamic rom) async {
  final aps = Aps();

  String currentIp = aps.ipv4.value;
  bool forceDhcp = false;
  String ipForServer = ""; // 默认为空，如果强制DHCP

  if (currentIp.isEmpty || currentIp == "0.0.0.0") {
    forceDhcp = true;
  } else {
    // IP有效且不是 "0.0.0.0"
    ipForServer = currentIp;
  }

  await createServer(
    username: aps.PlayerName.value,
    enableDhcp: forceDhcp ? true : aps.dhcp.value,
    specifiedIp: forceDhcp ? "" : ipForServer, // 如果强制DHCP，则指定IP为空
    roomName: rom.roomName,
    roomPassword: rom.password,
    cidrs: aps.cidrproxy.value,
    severurl:
        aps.servers.value.where((server) => server.enable).expand((server) {
          final urls = <String>[];
          if (server.tcp) urls.add('tcp://${server.url}');
          if (server.udp) urls.add('udp://${server.url}');
          if (server.ws) urls.add('ws://${server.url}');
          if (server.wss) urls.add('wss://${server.url}');
          if (server.quic) urls.add('quic://${server.url}');
          if (server.wg) urls.add('wg://${server.url}');
          if (server.txt) urls.add('txt://${server.url}');
          if (server.srv) urls.add('srv://${server.url}');
          if (server.http) urls.add('http://${server.url}');
          if (server.https) urls.add('https://${server.url}');
          return urls;
        }).toList(),
    onurl:
        Aps().listenList.value.where((url) => !url.contains('[::]')).toList(),
    flag: _buildFlags(aps),
  );
}

FlagsC _buildFlags(Aps aps) => FlagsC(
  defaultProtocol: aps.defaultProtocol.value,
  devName: aps.devName.value,
  enableEncryption: aps.enableEncryption.value,
  enableIpv6: aps.enableIpv6.value,
  mtu: aps.mtu.value,
  multiThread: aps.multiThread.value,
  latencyFirst: aps.latencyFirst.value,
  enableExitNode: aps.enableExitNode.value,
  noTun: aps.noTun.value,
  useSmoltcp: aps.useSmoltcp.value,
  relayNetworkWhitelist: aps.relayNetworkWhitelist.value,
  disableP2P: aps.disableP2p.value,
  relayAllPeerRpc: aps.relayAllPeerRpc.value,
  disableUdpHolePunching: aps.disableUdpHolePunching.value,
  dataCompressAlgo: aps.dataCompressAlgo.value,
  bindDevice: aps.bindDevice.value,
  enableKcpProxy: aps.enableKcpProxy.value,
  disableKcpInput: aps.disableKcpInput.value,
  disableRelayKcp: aps.disableRelayKcp.value,
  proxyForwardBySystem: aps.proxyForwardBySystem.value,
    acceptDns: aps.accept_dns.value,
  
);
