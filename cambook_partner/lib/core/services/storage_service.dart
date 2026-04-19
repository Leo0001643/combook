import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// 本地存储服务 —— 统一管理所有持久化数据
class StorageService extends GetxService {
  late final GetStorage _box;

  static const _keyToken  = 'token';
  static const _keyLocale = 'locale';
  static const _keyNotify = 'notify_';

  Future<StorageService> init() async {
    await GetStorage.init();
    _box = GetStorage();
    return this;
  }

  // ── Token ─────────────────────────────────────────────────────────
  String? get token        => _box.read(_keyToken);
  void saveToken(String t) => _box.write(_keyToken, t);
  void clearToken()        => _box.remove(_keyToken);
  bool get hasToken        => token != null && token!.isNotEmpty;

  // ── 语言 ──────────────────────────────────────────────────────────
  String get locale        => _box.read(_keyLocale) ?? _detectLocale();
  void saveLocale(String l)=> _box.write(_keyLocale, l);

  String _detectLocale() {
    final sys = Get.deviceLocale?.languageCode ?? 'zh';
    const supported = ['zh','en','vi','km','ko','ja'];
    return supported.contains(sys) ? sys : 'zh';
  }

  // ── 通知开关 ─────────────────────────────────────────────────────
  bool getNotify(String key)          => _box.read('$_keyNotify$key') ?? true;
  void saveNotify(String key, bool v) => _box.write('$_keyNotify$key', v);

  // ── 清除所有 ─────────────────────────────────────────────────────
  void clear() => _box.erase();
}
