import 'dart:convert';
import 'package:dudulan/k/models/room.dart';
import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

// 常量 密文
const String encryptedRoom = '这就是密钥';
// JWT密钥
const String jwtSecret = '这就是密钥';

/// 将房间对象加密为密文并用JWT保护
///
/// 接收一个 [Room] 对象，返回JWT保护的加密字符串
/// 加密过程：
/// 1. 将Room对象转换为JSON
/// 2. 压缩JSON数据
/// 3. 进行Base64编码
/// 4. 使用JWT进行保护
String encryptRoomWithJWT(Room room) {
  // 创建一个包含 Room 对象所有属性的 Map
  final Map<String, dynamic> roomMap = {
    'name': room.name,
    'encrypted': room.encrypted,
    'roomName': room.roomName,
    'password': room.password,
    'tags': room.tags,
  };

  // 将 Map 转换为 JSON 字符串
  final String jsonString = jsonEncode(roomMap);

  // 压缩JSON数据
  final List<int> compressedData = gzip.encode(utf8.encode(jsonString));

  // 将压缩后的数据进行 Base64 编码
  final String encryptedString = base64Encode(compressedData);

  // 使用JWT保护加密数据
  final jwt = JWT({'data': encryptedString}, issuer: 'astral_app');

  // 使用密钥签名JWT
  final token = jwt.sign(SecretKey(jwtSecret), expiresIn: Duration(days: 30));

  return token;
}

/// 将JWT保护的密文解密为房间对象
///
/// 接收一个JWT保护的加密字符串，返回解密后的 [Room] 对象
/// 解密过程：
/// 1. 验证JWT并提取数据
/// 2. 对密文进行Base64解码
/// 3. 解压数据
/// 4. 转换为Room对象
Room? decryptRoomFromJWT(String token) {
  try {
    // 验证JWT并提取数据
    final JWT jwt = JWT.verify(token, SecretKey(jwtSecret));
    final String encryptedString = jwt.payload['data'] as String;

    // 对密文进行Base64解码
    final List<int> compressedData = base64Decode(encryptedString);

    // 解压数据
    final List<int> decompressedData = gzip.decode(compressedData);
    final String jsonString = utf8.decode(decompressedData);

    // 将JSON字符串转换为Map
    final Map<String, dynamic> roomMap = jsonDecode(jsonString);

    // 从Map创建Room对象
    return Room(
      name: roomMap['name'] ?? '',
      encrypted: roomMap['encrypted'] ?? true,
      roomName: roomMap['roomName'] ?? '',
      password: roomMap['password'] ?? '',
      tags: List<String>.from(roomMap['tags'] ?? []),
    );
  } catch (e) {
    return null;
  }
}

/// 将房间对象加密为密文
///
/// 接收一个 [Room] 对象，返回加密后的密文字符串
/// 加密过程：将 Room 对象转换为 JSON，然后进行 Base64 编码
String encryptRoom(Room room) {
  // 创建一个包含 Room 对象所有属性的 Map
  final Map<String, dynamic> roomMap = {
    'name': room.name,
    'encrypted': room.encrypted, // 加密后的房间标记为已加密
    'roomName': room.roomName,
    'password': room.password,
    'tags': room.tags,
  };

  // 将 Map 转换为 JSON 字符串
  final String jsonString = jsonEncode(roomMap);

  // 将 JSON 字符串进行 Base64 编码
  final String encryptedString = base64Encode(utf8.encode(jsonString));

  return encryptedString;
}

/// 将密文解密为房间对象
///
/// 接收一个加密的密文字符串，返回解密后的 [Room] 对象
/// 解密过程：对密文进行 Base64 解码，然后转换为 Room 对象
Room? decryptRoom(String encryptedString) {
  try {
    // 对密文进行 Base64 解码
    final List<int> bytes = base64Decode(encryptedString);
    final String jsonString = utf8.decode(bytes);

    // 将 JSON 字符串转换为 Map
    final Map<String, dynamic> roomMap = jsonDecode(jsonString);

    // 从 Map 创建 Room 对象
    return Room(
      name: roomMap['name'] ?? '',
      encrypted: roomMap['encrypted'] ?? true,
      roomName: roomMap['roomName'] ?? '',
      password: roomMap['password'] ?? '',
      tags: List<String>.from(roomMap['tags'] ?? []),
    );
  } catch (e) {
    // 解密失败时返回null
    return null;
  }
}
