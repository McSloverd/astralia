import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  /// GitHub 仓库所有者
  final String owner;

  /// GitHub 仓库名称
  final String repo;

  /// 可选：指定检查的分支名称，默认为 'main'
  final String branch;

  UpdateChecker({
    required this.owner,
    required this.repo,
    this.branch = 'main',
  });

  /// 检查更新
  Future<void> scheckForUpdates(BuildContext context) async {
    try {
      final releaseInfo = await _fetchLatestRelease();
      if (releaseInfo == null) {
        _showUpdateDialog(
          // 添加空值处理
          context,
          '检查更新失败',
          '无法获取最新版本信息',
          'https://github.com/$owner/$repo/releases',
        );
        return;
      }
      // 获取当前应用版本
      final currentVersion = await _getCurrentVersion();
      debugPrint('当前版本: $currentVersion');
      debugPrint('服务器版本: ${releaseInfo['tag_name']}');

      // 比较版本号，如果有新版本则显示更新弹窗
      if (_shouldUpdate(currentVersion, releaseInfo['tag_name'])) {
        _showUpdateDialog(
          context,
          releaseInfo['tag_name'],
          releaseInfo['body'] ?? '新版本已发布',
          releaseInfo['html_url'],
        );
      }
    } catch (e) {
      _showUpdateDialog(
        context,
        '更新检查失败',
        '检查更新时发生错误: $e',
        'https://github.com/$owner/$repo/releases',
      );
    }
  }

  Future<void> checkForUpdates(BuildContext context) async {
    try {
      final releaseInfo = await _fetchLatestRelease();
      if (releaseInfo == null) {
        _showUpdateDialog(
          // 添加空值处理
          context,
          '检查更新失败',
          '无法获取最新版本信息',
          'https://github.com/$owner/$repo/releases',
        );
        return;
      }

      // 获取当前应用版本
      final currentVersion = await _getCurrentVersion();
      debugPrint('当前版本: $currentVersion');
      debugPrint('服务器版本: ${releaseInfo['tag_name']}');
      // 比较版本号，如果有新版本则显示更新弹窗
      if (_shouldUpdate(currentVersion, releaseInfo['tag_name'])) {
        _showUpdateDialog(
          context,
          releaseInfo['tag_name'],
          releaseInfo['body'] ?? '新版本已发布',
          releaseInfo['html_url'],
        );
      } else {
        _showUpdateDialog(
          context,
          '当前已是最新版本',
          '当前版本为: $currentVersion',
          'https://github.com/$owner/$repo/releases',
        );
      }
    } catch (e) {
      _showUpdateDialog(
        context,
        '更新检查失败',
        '检查更新时发生错误: $e',
        'https://github.com/$owner/$repo/releases',
      );
    }
  }

  /// 获取最新发布版本信息
  Future<Map<String, dynamic>?> _fetchLatestRelease() async {
    try {
      // 添加异常捕获
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$owner/$repo/releases'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'dudulan',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> releases = json.decode(response.body);
        if (releases.isEmpty) return null;

        // 获取第一个发布版本（最新版本）
        return releases[0];
      } else {
        return {
          // 返回错误信息
          'tag_name': '错误 ${response.statusCode}',
          'body': '请求GitHub API失败',
          'html_url': 'https://github.com/$owner/$repo/releases',
        };
      }
    } catch (e) {
      return null;
    }
  }

  /// 获取当前应用版本
  Future<String> _getCurrentVersion() async {
    try {
      return AppInfoUtil.getVersion();
    } catch (e) {
      return "0.0.0"; // 返回默认版本号避免后续比较崩溃
    }
  }

  /// 比较版本号，判断是否需要更新
  bool _shouldUpdate(String currentVersion, String latestVersion) {
    // 统一去除v前缀
    final current = currentVersion.replaceAll(RegExp(r'^v'), '');
    final latest = latestVersion.replaceAll(RegExp(r'^v'), '');

    // 分离主版本和预发布标签
    final currentParts = current.split('-');
    final latestParts = latest.split('-');

    // 比较主版本部分
    final currentMain = _parseVersionParts(currentParts[0]);
    final latestMain = _parseVersionParts(latestParts[0]);

    for (int i = 0; i < 3; i++) {
      final curr = i < currentMain.length ? currentMain[i] : 0;
      final lat = i < latestMain.length ? latestMain[i] : 0;

      if (lat > curr) return true;
      if (lat < curr) return false;
    }

    // 主版本相同，比较预发布标签
    if (currentParts.length == 1) return latestParts.length > 1; // 当前是正式版
    if (latestParts.length == 1) return true; // 最新是正式版

    return _comparePreRelease(currentParts[1], latestParts[1]) < 0;
  }

  List<int> _parseVersionParts(String version) {
    return version.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  }

  int _comparePreRelease(String a, String b) {
    final aParts = a.split('.');
    final bParts = b.split('.');

    for (int i = 0; i < max(aParts.length, bParts.length); i++) {
      final aVal = i < aParts.length ? aParts[i] : '';
      final bVal = i < bParts.length ? bParts[i] : '';

      // 优先比较数字
      final aNum = int.tryParse(aVal);
      final bNum = int.tryParse(bVal);

      if (aNum != null && bNum != null) {
        if (aNum != bNum) return aNum.compareTo(bNum);
      } else {
        final cmp = aVal.compareTo(bVal);
        if (cmp != 0) return cmp;
      }
    }
    return 0;
  }

  /// 显示更新弹窗
  void _showUpdateDialog(
    BuildContext context,
    String version,
    String releaseNotes,
    String downloadUrl,
  ) {
    final isLatestVersion = version.contains("当前已是最新版本");

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isLatestVersion ? version : '发现新版本: $version'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isLatestVersion) Text('更新内容:'),
                  if (!isLatestVersion) const SizedBox(height: 8),
                  Text(releaseNotes, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('稍后再说'),
              ),
              if (!isLatestVersion) // 仅在新版本弹窗显示更新按钮
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _launchUrl(downloadUrl);
                  },
                  child: const Text('立即更新'),
                ),
              if (isLatestVersion) // 最新版本显示确认按钮
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('确定'),
                ),
            ],
          ),
    );
  }

  /// 打开浏览器跳转到下载链接
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {}
  }
}

class AppInfoUtil {
  static PackageInfo? _packageInfo;

  /// 初始化应用信息
  static Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  /// 获取应用版本号 (例如: 1.0.0)
  static String getVersion() {
    return _packageInfo?.version ?? '';
  }

  /// 获取应用构建号 (例如: 1)
  static String getBuildNumber() {
    return _packageInfo?.buildNumber ?? '';
  }

  /// 获取完整版本号 (例如: 1.0.0+1)
  static String getFullVersion() {
    final version = getVersion();
    final buildNumber = getBuildNumber();
    return '$version+$buildNumber';
  }

  /// 获取应用名称
  static String getAppName() {
    return _packageInfo?.appName ?? '';
  }

  /// 获取包名
  static String getPackageName() {
    return _packageInfo?.packageName ?? '';
  }
}
