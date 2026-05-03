import Flutter
import UIKit
import AVFoundation
import AudioToolbox

@main
@objc class AppDelegate: FlutterAppDelegate {

  /// 强引用：AVAudioPlayer 播放期间不被 ARC 释放（真机路径使用）
  private var audioPlayer: AVAudioPlayer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // playback 类别：真机静音拨片打开也出声
    // 模拟器可能不支持，忽略错误，由 Strategy B 兜底
    try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
    try? AVAudioSession.sharedInstance().setActive(true)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.cambook.partner/sound",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        if call.method == "playNewOrder" {
          let args = call.arguments as? [String: Any]
          let path = args?["path"] as? String
          self?.playAudio(path: path, result: result)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Sound

  private func playAudio(path: String?, result: @escaping FlutterResult) {
    guard let filePath = path, !filePath.isEmpty,
          FileManager.default.fileExists(atPath: filePath) else {
      result(FlutterError(code: "NOT_FOUND",
                          message: "File not found: \(path ?? "nil")",
                          details: nil))
      return
    }

    let url = URL(fileURLWithPath: filePath)

    // ── Strategy A: AVAudioPlayer ─────────────────────────────────────────
    // 真机首选：playback 音频会话，静音开关打开也出声
    try? AVAudioSession.sharedInstance().setActive(true)
    if let player = try? AVAudioPlayer(contentsOf: url) {
      player.volume = 1.0
      player.prepareToPlay()
      if player.play() {
        audioPlayer = player   // 强引用，防止播放中被释放
        result(true)
        return
      }
    }

    // ── Strategy B: AudioServicesPlaySystemSound ──────────────────────────
    // 模拟器首选（同 SystemSound.alert 底层）：支持自定义 MP3 文件
    // 真机兜底：受静音开关影响，但至少能出声
    var soundID: SystemSoundID = 0
    let status = AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
    if status == kAudioServicesNoError && soundID != 0 {
      AudioServicesPlaySystemSound(soundID)
      // 播放完成后释放资源（MP3 通常 < 5s）
      DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
        AudioServicesDisposeSystemSoundID(soundID)
      }
      result(true)
      return
    }

    result(false)
  }
}
