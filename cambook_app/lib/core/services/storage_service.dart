import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

/// 安全本地存储服务（封装 flutter_secure_storage）
/// 存储 Token、用户基本信息，防止明文泄露
class StorageService extends GetxService {
  static StorageService get to => Get.find();

  late final FlutterSecureStorage _storage;

  static const _keyAccessToken  = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserId       = 'user_id';
  static const _keyUserType     = 'user_type';
  static const _keyNickname     = 'nickname';
  static const _keyAvatar       = 'avatar';
  static const _keyLanguage     = 'language';

  Future<StorageService> init() async {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
    return this;
  }

  // ── Token ──────────────────────────────────────────────────────────
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken,  value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
    ]);
  }

  Future<String?> readAccessToken()  => _storage.read(key: _keyAccessToken);
  Future<String?> readRefreshToken() => _storage.read(key: _keyRefreshToken);

  // ── 用户信息 ───────────────────────────────────────────────────────
  Future<void> saveUserInfo({
    required int userId,
    required int userType,
    String? nickname,
    String? avatar,
    String? language,
  }) async {
    await Future.wait([
      _storage.write(key: _keyUserId,   value: userId.toString()),
      _storage.write(key: _keyUserType, value: userType.toString()),
      if (nickname != null) _storage.write(key: _keyNickname, value: nickname),
      if (avatar   != null) _storage.write(key: _keyAvatar,   value: avatar),
      if (language != null) _storage.write(key: _keyLanguage, value: language),
    ]);
  }

  Future<int?>    readUserId()   async => int.tryParse(await _storage.read(key: _keyUserId)   ?? '');
  Future<int?>    readUserType() async => int.tryParse(await _storage.read(key: _keyUserType) ?? '');
  Future<String?> readNickname()  => _storage.read(key: _keyNickname);
  Future<String?> readAvatar()    => _storage.read(key: _keyAvatar);
  Future<String?> readLanguage()  => _storage.read(key: _keyLanguage);
  Future<void>    saveLanguage(String lang) => _storage.write(key: _keyLanguage, value: lang);

  // ── 清除 ───────────────────────────────────────────────────────────
  Future<void> clearAll() => _storage.deleteAll();
}
