import 'package:dudulan/k/app_s/aps.dart';
import 'package:flutter/material.dart';
import 'package:system_tray/system_tray.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';

class WindowControls extends StatefulWidget {
  const WindowControls({super.key});

  @override
  State<WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<WindowControls> with WindowListener {
  bool _isMaximized = false;
  final SystemTray _systemTray = SystemTray();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _updateMaximizedStatus();
    // 桌面平台代码
    _initTray();

  }

  Future<void> _initTray() async {
    String path = 'assets/icon.ico';
    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
        label: '显示主界面',
        onClicked: (menuItem) {
          // 添加窗口显示逻辑
          windowManager.show();
        },
      ),
      MenuItemLabel(
        label: '退出',
        onClicked: (menuItem) {
          _systemTray.destroy();
          windowManager.close();
        },
      ),
    ]);

    // 添加异常处理
    try {
      await _systemTray.initSystemTray(title: "Dudulan", iconPath: path);
      await _systemTray.setContextMenu(menu);
    } catch (e) {
      print('托盘初始化失败: $e');
    }

    // 注册右键事件处理
    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventRightClick) {
        _systemTray.popUpContextMenu(); // 显式弹出上下文菜单
      } else if (eventName == kSystemTrayEventClick) {
        windowManager.show();
      }
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  Future<void> _updateMaximizedStatus() async {
    final maximized = await windowManager.isMaximized();
    setState(() => _isMaximized = maximized);
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () async {
            await windowManager.minimize();
          },
          tooltip: '最小化',
          iconSize: 20,
        ),
        IconButton(
          icon: Icon(_isMaximized ? Icons.filter_none : Icons.crop_square),
          onPressed: () async {
            if (_isMaximized) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
          tooltip: _isMaximized ? '还原' : '最大化',
          iconSize: 20,
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            if (Aps().closeMinimize.value) {
              await windowManager.hide();
            } else {
              await windowManager.close();
            }
          },
          tooltip: '关闭',
          iconSize: 20,
        ),
      ],
    );
  }
}
