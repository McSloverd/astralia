import 'dart:io';
import 'package:dudulan/k/app_s/aps.dart';
import 'package:dudulan/wid/theme_selector.dart';
import 'package:dudulan/wid/windows_controls.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

// 获取主题模式的文本描述
String getThemeModeText(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return '亮色模式';
    case ThemeMode.dark:
      return '暗色模式';
    case ThemeMode.system:
      return '跟随系统';
  }
}

/// 状态栏组件
/// 实现了PreferredSizeWidget接口以指定首选高度
class StatusBar extends StatelessWidget implements PreferredSizeWidget {
  const StatusBar({super.key});

  /// 指定状态栏的首选高度为36
  @override
  Size get preferredSize => const Size.fromHeight(36);

  @override
  Widget build(BuildContext context) {
    // 获取当前主题的配色方案
    final colorScheme = Theme.of(context).colorScheme;

    return PreferredSize(
      // 设置状态栏高度
      preferredSize: const Size.fromHeight(36),
      child: GestureDetector(
        // 处理拖动事件，仅在桌面平台启用窗口拖动
        onPanStart: (details) {
          if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
            windowManager.startDragging();
          }
        },
        child: AppBar(
          // 显示应用名称
          title: ShaderMask(
            shaderCallback:
                (bounds) => LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                ).createShader(bounds),
            child: Text(
              Aps().appName.watch(context),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white, // 必须设置为白色以显示渐变效果
              ),
            ),
          ),
          // 设置AppBar的背景色和前景色
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          toolbarHeight: 36,
          // 在桌面平台显示窗口控制按钮
          actions: [
            IconButton(
              icon: Icon(
                // 根据当前主题模式选择对应图标
                switch (Aps().themeMode.watch(context)) {
                  ThemeMode.light => Icons.wb_sunny,
                  ThemeMode.dark => Icons.nightlight_round,
                  ThemeMode.system => Icons.auto_mode,
                },
                size: 20,
              ),
              onPressed: () {
                final currentMode = Aps().themeMode.value;
                final newMode = switch (currentMode) {
                  ThemeMode.light => ThemeMode.dark,
                  ThemeMode.dark => ThemeMode.system,
                  ThemeMode.system => ThemeMode.light,
                };
                Aps().updateThemeMode(newMode);
              },
              tooltip: getThemeModeText(Aps().themeMode.watch(context)),
              padding: const EdgeInsets.all(8),
            ),

            IconButton(
              icon: const Icon(Icons.color_lens, size: 20), // 减小图标大小
              onPressed: () => showThemeColorPicker(context),
              tooltip: '选择主题颜色',
              padding: const EdgeInsets.all(4), // 减小内边距
            ),
            if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
              const WindowControls(),
          ],
        ),
      ),
    );
  }
}
