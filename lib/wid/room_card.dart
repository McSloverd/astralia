// 修改RoomCard类，接收 Room 对象和分类名称列表
import 'package:dudulan/k/app_s/aps.dart';
import 'package:dudulan/k/models/room.dart';
import 'package:dudulan/wid/home/connect_button.dart';
import 'package:flutter/material.dart';

class RoomCard extends StatefulWidget {
  final Room room;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onShare; // 添加分享回调

  const RoomCard({
    super.key,
    required this.room,
    this.onEdit,
    this.onDelete,
    this.onShare, // 添加分享参数
  });

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {
  bool _isExpanded = false;
  bool _isHovered = false; // 新增

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    // 获取当前选中的房间
    final selectedRoom = Aps().selectroom.watch(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        elevation: 4,
        // 仅在选中时应用亮度调整，未选中使用默认表面色
        color: selectedRoom?.id == room.id 
            ? (Theme.of(context).brightness == Brightness.dark
                ? HSLColor.fromColor(Theme.of(context).colorScheme.primary)
                    .withLightness(0.10) // 深色模式选中亮度10%
                    .toColor()
                : HSLColor.fromColor(Theme.of(context).colorScheme.primary)
                    .withLightness(0.75) // 浅色模式选中亮度75%
                    .toColor())
            : Theme.of(context).colorScheme.surface, // 未选中使用默认表面色
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          // 添加选中或悬浮状态边框
          side: BorderSide(
            color:
                (selectedRoom?.id == room.id || _isHovered)
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
            width: (_isHovered && selectedRoom?.id != room.id) ? 1 : 2,
          ),
        ),
        child: InkWell(
          onTap: () {
            // 点击时设置当前房间
            Aps().setRoom(room);

            _toggleExpanded();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          // 添加选中状态图标
                          if (selectedRoom?.id == room.id)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              room.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (widget.onShare != null)
                          IconButton(
                            icon: const Icon(Icons.share, size: 20),
                            onPressed: widget.onShare,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: '分享房间',
                          ),
                        if (widget.onShare != null &&
                            (widget.onDelete != null || widget.onEdit != null))
                          const SizedBox(width: 8),
                        if (widget.onDelete != null)
                          if (selectedRoom?.id != room.id)
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () {
                                // 添加确认对话框
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('确认删除'),
                                        content: const Text('确定要删除这个房间吗？'),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: const Text('取消'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              widget.onDelete?.call();
                                            },
                                            child: const Text(
                                              '删除',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: '删除房间',
                            ),
                        if (widget.onDelete != null && widget.onEdit != null)
                          const SizedBox(width: 8),
                        if (widget.onEdit != null)
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: widget.onEdit,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: '编辑房间',
                          ),
                        const SizedBox(width: 8),
                        Icon(
                          room.encrypted
                              ? Icons.lock
                              : Icons.lock_open, // 使用 room.isEncrypted
                          color: room.encrypted ? Colors.red : Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '类型: ${room.encrypted ? "保护" : "不保护"}', // 使用 room.isEncrypted
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
