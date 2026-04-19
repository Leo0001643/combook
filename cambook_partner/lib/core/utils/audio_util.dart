import 'package:audioplayers/audioplayers.dart';
import 'log_util.dart';

/// 音效工具 —— 单例 AudioPlayer，避免每次创建开销
class AudioUtil {
  AudioUtil._();

  static final AudioPlayer _player = AudioPlayer();

  /// 播放提示音（资源路径，相对于 assets 目录）
  static Future<void> playAsset(String assetPath) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      LogUtil.e('[AudioUtil] 播放失败: $e');
    }
  }

  /// 播放新订单提示音
  static Future<void> playNewOrder() =>
      playAsset('mp3/prompt_tone.mp3');

  /// 释放资源（应用退出时调用）
  static Future<void> dispose() async {
    await _player.dispose();
  }
}
