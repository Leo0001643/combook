/// IM 时间格式化工具
abstract class ImTimeUtil {
  /// 消息时间（气泡内显示 HH:mm）
  static String fmtMsgTime(int unixSec) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSec * 1000);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// 会话列表时间（今天→HH:mm，昨天→昨天，否则→MM/DD）
  static String fmtConvTime(int? unixSec) {
    if (unixSec == null) return '';
    final dt  = DateTime.fromMillisecondsSinceEpoch(unixSec * 1000);
    final now = DateTime.now();
    if (sameDay(dt, now)) return fmtMsgTime(unixSec);
    final yesterday = now.subtract(const Duration(days: 1));
    if (sameDay(dt, yesterday)) return '昨天';
    if (now.year == dt.year) return '${dt.month}/${dt.day}';
    return '${dt.year}/${dt.month}/${dt.day}';
  }

  /// 日期分隔符标签
  static String fmtDateLabel(int unixSec) {
    final dt  = DateTime.fromMillisecondsSinceEpoch(unixSec * 1000);
    final now = DateTime.now();
    if (sameDay(dt, now)) return '今天';
    if (sameDay(dt, now.subtract(const Duration(days: 1)))) return '昨天';
    return '${dt.year}年${dt.month}月${dt.day}日';
  }

  /// 语音时长格式化 mm:ss
  static String fmtDuration(int secs) {
    final m = secs ~/ 60, s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
