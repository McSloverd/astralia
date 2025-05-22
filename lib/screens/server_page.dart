import 'package:dudulan/fun/show_server_dialog.dart';
import 'package:dudulan/k/app_s/aps.dart';
import 'package:dudulan/k/models/server_mod.dart';
import 'package:dudulan/wid/server_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class ServerPage extends StatefulWidget {
  const ServerPage({super.key});

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  int _getColumnCount(double width) {
    if (width >= 1200) {
      return 4;
    } else if (width >= 900) {
      return 3;
    } else if (width >= 600) {
      return 2;
    }
    return 1;
  }

  final _aps = Aps();

  @override
  void initState() {
    super.initState();
    // 初始化时加载所有服务器
    _loadServers();
  }

  Future<void> _loadServers() async {
    await _aps.getAllServers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columnCount = _getColumnCount(constraints.maxWidth);
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(14),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: columnCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childCount: _aps.servers.watch(context).length,
                  itemBuilder: (context, index) {
                    final server = _aps.servers.watch(context)[index];
                    return ServerCard(
                      server: server,
                      onEdit: () {
                        showEditServerDialog(context, server: server);
                      },
                      onDelete: () {
                        _showDeleteConfirmDialog(server);
                      },
                    );
                  },
                ),
              ),
              // 添加底部安全区域，防止内容被遮挡
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 20,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: '添加服务器',
        onPressed: () => showAddServerDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // 显示删除确认对话框
  void _showDeleteConfirmDialog(ServerMod server) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('删除服务器'),
            content: Text('确定要删除服务器 "${server.name}" 吗？此操作不可撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  _aps.deleteServer(server);
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('删除'),
              ),
            ],
          ),
    );
  }
}
