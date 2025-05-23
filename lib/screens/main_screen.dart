// 导入所需的包
import 'package:dudulan/fun/up.dart';
import 'package:dudulan/k/app_s/aps.dart';
import 'package:dudulan/screens/home_page.dart';
import 'package:dudulan/screens/room_page.dart';
import 'package:dudulan/screens/server_page.dart';
import 'package:dudulan/screens/settings_page.dart';
// import 'package:dudulan/screens/user_page.dart';
import 'package:dudulan/wid/bottom_nav.dart';
import 'package:dudulan/wid/left_nav.dart';
import 'package:dudulan/wid/status_bar.dart';
import 'package:flutter/material.dart';
import 'package:dudulan/k/navigtion.dart';

// 主屏幕Widget，使用StatefulWidget以管理状态
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

// MainScreen的状态管理类
class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this); // 监听屏幕等状态变化
    // 在第一帧渲染完成后获取屏幕宽度并更新分割宽度
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      Aps().updateScreenSplitWidth(screenWidth);
    });

    // 在初始化时进行更新检查
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final updateChecker = UpdateChecker(owner: 'McSloverd', repo: 'dudulan');
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            updateChecker.scheckForUpdates(context);
          }
        });
      }
    });
  }

  // 组件销毁时移除观察者
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 屏幕尺寸变化时的回调
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // 屏幕尺寸变化时更新
    final screenWidth = MediaQuery.of(context).size.width;
    Aps().updateScreenSplitWidth(screenWidth);
  }

  // 定义导航项列表
  final List<NavigationItem> navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined, // 未选中时的图标
      activeIcon: Icons.home, // 选中时的图标
      label: '主页', // 导航项标签
      page: const HomePage(), // 对应的页面
    ),
    NavigationItem(
      icon: Icons.room_preferences_outlined, // 未选中时的图标
      activeIcon: Icons.room_preferences, // 选中时的图标Icon(Icons.room_preferences)
      label: '房间', // 导航项标签
      page: const RoomPage(), // 对应的页面
    ),
    NavigationItem(
      icon: Icons.dns_outlined, // 未选中时的图标
      activeIcon: Icons.dns, // 选中时的图标Icon(Icons.room_preferences)
      label: '服务器', // 导航项标签
      page: const ServerPage(), // 对应的页面
    ),

    NavigationItem(
      icon: Icons.settings_outlined, // 未选中时的图标
      activeIcon: Icons.settings, // 选中时的图标
      label: '设置', // 导航项标签
      page: const SettingsPage(), // 对应的页面
    ),
  ];

  // 获取页面列表的getter方法
  List<Widget> get _pages => navigationItems.map((item) => item.page).toList();

  @override
  Widget build(BuildContext context) {
    // 获取当前主题的颜色方案
    final colorScheme = Theme.of(context).colorScheme;

    // 构建Scaffold组件
    return Scaffold(
      // 自定义应用栏
      appBar: StatusBar(),
      // 主体内容：使用Row布局
      body: Row(
        children: [
          // 根据是否为桌面端决定是否显示左侧导航
          if (Aps().isDesktop.watch(context))
            LeftNav(items: navigationItems, colorScheme: colorScheme),
          // 主要内容区域
          Expanded(
            child: IndexedStack(
              index: Aps().selectedIndex.watch(context), // 当前选中的页面索引
              children: _pages, // 页面列表
            ),
          ),
        ],
      ),
      // 底部导航栏：仅在非桌面端显示
      bottomNavigationBar:
          Aps().isDesktop.watch(context)
              ? null
              : BottomNav(
                navigationItems: navigationItems,
                colorScheme: colorScheme,
              ),
    );
  }
}
