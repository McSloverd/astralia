import 'dart:io';

Future<void> handleStartupSetting(bool enable) async {
  final executablePath = Platform.resolvedExecutable;
  final startupFolder =
      '${Platform.environment['APPDATA']}\\Microsoft\\Windows\\Start Menu\\Programs\\Startup';
  final shortcutPath = '$startupFolder\\Dudulan.lnk';

  if (enable) {
    // 检查快捷方式是否存在
    if (await File(shortcutPath).exists()) {
      // 如果存在，先删除旧的快捷方式
      await File(shortcutPath).delete();
    }

    // 创建新的快捷方式
    final shell = 'powershell';
    final args = [
      '-Command',
      '\$WshShell = New-Object -ComObject WScript.Shell; '
          '\$Shortcut = \$WshShell.CreateShortcut("$shortcutPath"); '
          '\$Shortcut.TargetPath = "$executablePath"; '
          '\$Shortcut.Save()',
    ];
    await Process.run(shell, args);
  } else {
    // 删除快捷方式
    if (await File(shortcutPath).exists()) {
      await File(shortcutPath).delete();
    }
  }
}
