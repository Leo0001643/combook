import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../config/app_config.dart';

/// 本地存储服务 —— 统一管理所有持久化数据
class StorageService extends GetxService {
  late final GetStorage _box;

  static const _keyToken      = 'token';
  static const _keyLocale     = 'locale';
  static const _keyNotify     = 'notify_';
  static const _keyTheme      = 'app_theme';
  static const _keyTechnician = 'technician_profile';

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

  // ── App 主题色 ────────────────────────────────────────────────────
  String get themeColor         => _box.read(_keyTheme) ?? AppConfig.themeVariant;
  String? get storedThemeColor  => _box.read(_keyTheme) as String?;
  void saveThemeColor(String v) => _box.write(_keyTheme, v);

  // ── 技师资料本地缓存（冷启动会话恢复用）────────────────────────────
  Map<String, dynamic>? get technicianCache =>
      _box.read<Map>(_keyTechnician)?.cast<String, dynamic>();
  void saveTechnician(Map<String, dynamic> data) =>
      _box.write(_keyTechnician, data);

  // ── 服务开始时间（专注模式计时，跨重启/登出持久化）─────────────────
  static const _keyServiceStart = 'svc_start_';

  int? getServiceStartMs(int orderId) =>
      _box.read('$_keyServiceStart$orderId') as int?;
  void saveServiceStartMs(int orderId, DateTime t) =>
      _box.write('$_keyServiceStart$orderId', t.millisecondsSinceEpoch);
  void clearServiceStart(int orderId) =>
      _box.remove('$_keyServiceStart$orderId');

  // ── 清除所有 ─────────────────────────────────────────────────────
  void clear() => _box.erase();
}
