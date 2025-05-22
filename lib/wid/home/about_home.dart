import 'package:astral/fun/up.dart';
import 'package:astral/k/app_s/aps.dart';
import 'package:astral/src/rust/api/simple.dart';
import 'package:astral/wid/home_box.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class AboutHome extends StatefulWidget {
  const AboutHome({super.key});

  @override
  State<AboutHome> createState() => _AboutHomeState();
}

class _AboutHomeState extends State<AboutHome> {
  String version = '';
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    easytierVersion().then((value) {
      setState(() {
        version = value; // 异步完成后更新状态
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    return HomeBox(
      widthSpan: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: colorScheme.primary,
                size: 22,
              ), // 修改标题图标
              const SizedBox(width: 8),
              const Text(
                '关于 DUDU LAN - DUDU重工',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              Icon(
                Icons.smartphone,
                size: 20,
                color: colorScheme.primary,
              ), // 软件版本图标
              const Text(
                '官方QQ群: ',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                //AppInfoUtil.getVersion(),
                '932267169',
                style: TextStyle(color: colorScheme.secondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              Icon(
                Icons.memory,
                size: 20,
                color: colorScheme.primary,
              ), // 内核版本图标
              const Text(
                '注意:    ',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                //version, 
                '滥用将会导致封禁！',
                style: TextStyle(color: colorScheme.secondary)
              ),
            ],
          ),
        ],
      ),
    );
  }
}
