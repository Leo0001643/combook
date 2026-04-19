/// 数字/金额格式工具（全局，禁止页面内硬编码格式逻辑）
abstract class FormatUtil {
  static String money(double v) =>
      '\$${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)}';
  static String moneyFull(double v) => '\$${v.toStringAsFixed(2)}';
  static String km(double v) => '${v.toStringAsFixed(1)} km';
  static String percent(double v) => '${(v * 100).toStringAsFixed(1)}%';
}
