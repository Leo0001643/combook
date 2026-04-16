import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 设备信息服务（GetxService，全局单例，应用启动时初始化一次）
///
/// 采集：
///   - deviceId     — 设备唯一标识符
///   - deviceInfo   — 操作系统/型号/品牌/系统版本（JSON字符串）
///   - appVersion   — App 版本号（pubspec.yaml 中的 version）
class DeviceService extends GetxService {
  static DeviceService get to => Get.find();

  String deviceId   = '';
  String deviceInfo = '{}';
  String appVersion = '';

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await _loadAppVersion();
    await _loadDeviceInfo();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {
      appVersion = '1.0.0';
    }
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (kIsWeb) {
        final w = await plugin.webBrowserInfo;
        deviceId   = 'web-${w.userAgent?.hashCode ?? 0}';
        deviceInfo = jsonEncode({
          'os': 'web',
          'browserName': w.browserName.name,
          'userAgent': w.userAgent,
        });
      } else if (Platform.isIOS) {
        final ios = await plugin.iosInfo;
        deviceId   = ios.identifierForVendor ?? 'ios-unknown';
        deviceInfo = jsonEncode({
          'os': 'iOS',
          'osVersion': ios.systemVersion,
          'model': ios.model,
          'name': ios.name,
        });
      } else if (Platform.isAndroid) {
        final and = await plugin.androidInfo;
        deviceId   = and.id;
        deviceInfo = jsonEncode({
          'os': 'Android',
          'osVersion': and.version.release,
          'model': and.model,
          'brand': and.brand,
          'manufacturer': and.manufacturer,
        });
      } else if (Platform.isMacOS) {
        final mac = await plugin.macOsInfo;
        deviceId   = mac.systemGUID ?? 'mac-unknown';
        deviceInfo = jsonEncode({
          'os': 'macOS',
          'osVersion': mac.osRelease,
          'model': mac.model,
        });
      }
    } catch (_) {
      deviceId   = 'unknown';
      deviceInfo = '{}';
    }
  }
}
