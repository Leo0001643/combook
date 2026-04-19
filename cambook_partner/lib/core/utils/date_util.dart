/// 日期时间工具
abstract class DateUtil {
  /// 格式化为 yyyy/MM/dd HH:mm
  static String format(DateTime d) =>
      '${d.year}/${_p(d.month)}/${_p(d.day)} ${_p(d.hour)}:${_p(d.minute)}';

  /// 仅时间 HH:mm
  static String timeOnly(DateTime d) => '${_p(d.hour)}:${_p(d.minute)}';

  /// 仅日期 MM/dd
  static String dateOnly(DateTime d) => '${_p(d.month)}/${_p(d.day)}';

  /// 相对时间（刚刚 / N分钟前 / N小时前 / MM/dd）
  static String relative(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1)  return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours   < 24) return '${diff.inHours}小时前';
    if (diff.inDays    < 7)  return '${diff.inDays}天前';
    return dateOnly(d);
  }

  /// 格式化计时器 mm:ss 或 hh:mm:ss
  static String timer(int secs) {
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    return h > 0
        ? '${_p(h)}:${_p(m)}:${_p(s)}'
        : '${_p(m)}:${_p(s)}';
  }

  static String _p(int n) => n.toString().padLeft(2, '0');

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
