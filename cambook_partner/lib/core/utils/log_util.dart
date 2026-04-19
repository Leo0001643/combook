import 'package:flutter/foundation.dart';

/// 统一日志工具
abstract class LogUtil {
  static void d(Object msg) { if (kDebugMode) debugPrint('[D] $msg'); }
  static void i(Object msg) { if (kDebugMode) debugPrint('[I] $msg'); }
  static void w(Object msg) { if (kDebugMode) debugPrint('[W] $msg'); }
  static void e(Object msg) { if (kDebugMode) debugPrint('[E] $msg'); }
}
