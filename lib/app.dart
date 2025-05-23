import 'package:dudulan/lib/fun/net_astral_udp.dart';
import 'package:dudulan/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:dudulan/k/app_s/aps.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// 仅在桌面平台导入系统托盘

class KevinApp extends StatefulWidget {
  const KevinApp({super.key});
  @override
  State<KevinApp> createState() => _KevinAppState();
}

class _KevinAppState extends State<KevinApp> {
  final _aps = Aps();

  @override
  void initState() {
    super.initState();
    getIpv4AndIpV6Addresses();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        // 添加国际化支持
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Insert this line
      supportedLocales: const [Locale("zh", "CN"), Locale("en", "US")],
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _aps.themeColor.watch(context), // 设置当前主题颜色,
        brightness: Brightness.light,
      ).copyWith(
        textTheme: Typography.material2021().black.apply(fontFamily: 'MiSans'),
        primaryTextTheme: Typography.material2021().black.apply(
          fontFamily: 'MiSans',
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _aps.themeColor.watch(context),
        brightness: Brightness.dark,
      ).copyWith(
        textTheme: Typography.material2021().white.apply(fontFamily: 'MiSans'),
        primaryTextTheme: Typography.material2021().white.apply(
          fontFamily: 'MiSans',
        ),
      ),
      themeMode: _aps.themeMode.watch(context), // 设置当前主题模式
      home: MainScreen(),
    );
  }
}
