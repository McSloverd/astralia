import 'dart:io';

import 'package:dudulan/k/models/all_settings.dart';
import 'package:dudulan/k/models/room.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:isar/isar.dart';

class AllSettingsCz {
  final Isar _isar;

  AllSettingsCz(this._isar) {
    init();
  }

  Future<void> init() async {
    AllSettings? settings = await _isar.allSettings.get(
      1,
    ); // 1. 使用可变变量 settings
    bool needsSave = false; // 2. 标记是否需要保存

    if (settings == null) {
      // 3. 如果是首次运行 (settings 为 null)
      settings = AllSettings(); // 创建新实例

      // 直接在新实例上设置所有默认值
      settings.playerName = await _getDeviceName(); // 设置默认 playerName
      settings.listenList = [
        // 设置默认 listenList
        "tcp://0.0.0.0:11010",
        "udp://0.0.0.0:11010",
      ];
      needsSave = true; // 标记这个新创建并完全初始化的对象需要保存
    } else {
      // 4. 如果 settings 已存在，检查各个字段是否需要设置默认值
      if (settings.playerName == null) {
        settings.playerName = await _getDeviceName();
        needsSave = true;
      }
      if (settings.listenList == null) {
        settings.listenList = ["tcp://0.0.0.0:11010", "udp://0.0.0.0:11010"];
        needsSave = true;
      }
    }

    // 5. 如果有任何更改或这是新对象，则保存到数据库
    if (needsSave) {
      await _isar.writeTxn(() async {
        // 此处的 settings! 是安全的，因为如果它开始时为 null，则已被赋值
        await _isar.allSettings.put(settings!);
      });
    }
  }

  /// 设置用户简约模式
  /// @param isMinimal 是否启用简约模式
  /// 将新的简约模式设置保存到数据库中
  Future<void> setUserMinimal(bool isMinimal) async {
    AllSettings? settings = await _isar.allSettings.get(1);
    if (settings != null) {
      settings.userListSimple = isMinimal;
      await _isar.writeTxn(() async {
        await _isar.allSettings.put(settings);
      });
    }
  }

  /// 获取用户简约模式
  /// @return 是否启用简约模式
  Future<bool> getUserMinimal() async {
    AllSettings? settings = await _isar.allSettings.get(1);
    if (settings != null) {
      return settings.userListSimple;
    }
    return false;
  }

  // getListenList
  Future<List<String>> getListenList() async {
    AllSettings? config = await _isar.allSettings.get(1);
    if (config?.listenList == null) return [];
    return config!.listenList!;
  }

  ///closeMinimize
  /// @param isClose 是否关闭最小化到托盘
  /// 将新的最小化到托盘设置保存到数据库中
  Future<void> closeMinimize(bool isClose) async {
    AllSettings? settings = await _isar.allSettings.get(1);
    if (settings != null) {
      settings.closeMinimize = isClose;
      await _isar.writeTxn(() async {
        await _isar.allSettings.put(settings);
      });
    }
  }

  ///getCloseMinimize
  /// @return 是否关闭最小化到托盘
  Future<bool> getCloseMinimize() async {
    AllSettings? settings = await _isar.allSettings.get(1);
    if (settings != null) {
      return settings.closeMinimize;
    }
    return false;
  }

  // 设置监听列表
  Future<void> setListenList(List<String> listenList) async {
    AllSettings? config = await _isar.allSettings.get(1);
    if (config != null) {
      config.listenList = listenList;
      await _isar.writeTxn(() async {
        await _isar.allSettings.put(config);
      });
    }
  }

  // 删除监听列表
  Future<void> deleteListenList(int index) async {
    AllSettings? config = await _isar.allSettings.get(1);
    if (config != null) {
      config.listenList!.removeAt(index);
      await _isar.writeTxn(() async {
        await _isar.allSettings.put(config);
      });
    }
  }

  // 添加监听列表
  Future<void> addListenList(String listen) async {
    AllSettings? config = await _isar.allSettings.get(1);
    if (config != null) {
      config.listenList!.add(listen);
      await _isar.writeTxn(() async {
        await _isar.allSettings.put(config);
      });
    }
  }

  // 修改监听列表
  Future<void> updateListenList(int index, String listen) async {
    AllSettings? config = await _isar.allSettings.get(1);
    if (config != null) {
      config.listenList![index] = listen;
      await _isar.writeTxn(() async {
        await _isar.allSettings.put(config);
      });
    }
  }

  // 设置房间
  Future<void> updateRoom(Room room) async {
    AllSettings? config = await _isar.allSettings.get(1);
    if (config != null) {
      config.room = room.id;
      await _isar.writeTxn(() async {
        await _isar.allSettings.put(config);
      });
    }
  }

  // 获取当前房间ID
  Future<Room?> getRoom() async {
    AllSettings? config = await _isar.allSettings.get(1);
    if (config?.room == null) return null;
    return await _isar.rooms.get(config!.room!);
  }

  // 获取所有设置
  Future<AllSettings?> getAllSettings() async {
    return await _isar.allSettings.get(1);
  }

  // 设定玩家名称
  Future<void> setPlayerName(String name) async {
    AllSettings? config = await _isar.allSettings.get(1);
    if (config != null) {
      config.playerName = name;
      await _isar.writeTxn(() async {
        await _isar.allSettings.put(config);
      });
    }
  }

  // 获取玩家名称
  Future<String> getPlayerName() async {
    AllSettings? config = await _isar.allSettings.get(1);
    if (config?.playerName == null) {
      String deviceName = await _getDeviceName();
      await setPlayerName(deviceName);
      return deviceName;
    }
    return config!.playerName!;
  }

  // 设置自定义VPN网段
  Future<void> setCustomVpn(List<String> customVpn) async {
    AllSettings? config = await _isar.allSettings.get(1);
    if (config != null) {
      config.customVpn = customVpn;
      await _isar.writeTxn(() async {
        await _isar.allSettings.put(config);
      });
    }
  }

  // 删除自定义VPN网段
  Future<void> deleteCustomVpn(int index) async {
    AllSettings? config = await _isar.allSettings.get(1);
    if (config != null) {
      config.customVpn.removeAt(index);
      await _isar.writeTxn(() async {
        await _isar.allSettings.put(config);
      });
    }
  }

  // 添加自定义VPN网段
  Future<void> addCustomVpn(String vpn) async {
    AllSettings? config = await _isar.allSettings.get(1);
    if (config != null) {
      config.customVpn.add(vpn);
      await _isar.writeTxn(() async {
        await _isar.allSettings.put(config);
      });
    }
  }

  // 修改自定义VPN网段
  Future<void> updateCustomVpn(int index, String vpn) async {
    AllSettings? config = await _isar.allSettings.get(1);
    if (config != null) {
      config.customVpn[index] = vpn;
      await _isar.writeTxn(() async {
        await _isar.allSettings.put(config);
      });
    }
  }

  // 获取自定义VPN网段
  Future<List<String>> getCustomVpn() async {
    AllSettings? config = await _isar.allSettings.get(1);
    return config?.customVpn ?? [];
  }

  /// 设置开机自启
  Future<void> setStartup(bool isStartup) async {
    AllSettings? settings = await _isar.allSettings.get(1);
    if (settings != null) {
      settings.startup = isStartup;
      await _isar.writeTxn(() async {
        await _isar.allSettings.put(settings);
      });
    }
  }

  /// 获取开机自启状态
  Future<bool> getStartup() async {
    AllSettings? settings = await _isar.allSettings.get(1);
    if (settings != null) {
      return settings.startup;
    }
    return false;
  }

  /// 设置启动后最小化
  Future<void> setStartupMinimize(bool isMinimize) async {
    AllSettings? settings = await _isar.allSettings.get(1);
    if (settings != null) {
      settings.startupMinimize = isMinimize;
      await _isar.writeTxn(() async {
        await _isar.allSettings.put(settings);
      });
    }
  }

  /// 获取启动后最小化状态
  Future<bool> getStartupMinimize() async {
    AllSettings? settings = await _isar.allSettings.get(1);
    if (settings != null) {
      return settings.startupMinimize;
    }
    return false;
  }

  /// 设置启动后自动连接
  Future<void> setStartupAutoConnect(bool isAutoConnect) async {
    AllSettings? settings = await _isar.allSettings.get(1);
    if (settings != null) {
      settings.startupAutoConnect = isAutoConnect;
      await _isar.writeTxn(() async {
        await _isar.allSettings.put(settings);
      });
    }
  }

  /// 获取启动后自动连接状态
  Future<bool> getStartupAutoConnect() async {
    AllSettings? settings = await _isar.allSettings.get(1);
    if (settings != null) {
      return settings.startupAutoConnect;
    }
    return false;
  }
}

// 在同一个文件中添加这个方法
Future<String> _getDeviceName() async {
  try {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name;
    } else if (Platform.isWindows) {
      WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
      return windowsInfo.computerName;
    } else if (Platform.isMacOS) {
      MacOsDeviceInfo macOSInfo = await deviceInfo.macOsInfo;
      return macOSInfo.computerName;
    } else if (Platform.isLinux) {
      LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
      return linuxInfo.name;
    }

    return "Default Player"; // 如果无法获取设备名称，则使用默认名称
  } catch (e) {
    return "Default Player"; // 错误处理，返回默认名称
  }
}
