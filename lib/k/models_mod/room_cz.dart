import 'package:isar/isar.dart';
import 'package:dudulan/k/models/room.dart'; // 添加 Room 模型的导入

class RoomCz {
  final Isar _isar;

  RoomCz(this._isar) {
    init();
  }

  Future<void> init() async {}

  // 添加房间
  Future<int> addRoom(Room room) async {
    return await _isar.writeTxn(() async {
      return await _isar.rooms.put(room);
    });
  }

  // 根据ID获取房间
  Future<Room?> getRoomById(int id) async {
    return await _isar.rooms.get(id);
  }

  // 获取所有房间
  Future<List<Room>> getAllRooms() async {
    return await _isar.rooms.where().findAll();
  }

  // 更新房间
  Future<int> updateRoom(Room room) async {
    return await _isar.writeTxn(() async {
      return await _isar.rooms.put(room); // Isar 的 put 方法会自动处理更新
    });
  }

  // 删除房间
  Future<bool> deleteRoom(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.rooms.delete(id);
    });
  }

  // 根据标签查询房间
  Future<List<Room>> getRoomsByTag(String tag) async {
    return await _isar.rooms.filter().tagsElementEqualTo(tag).findAll();
  }
}
