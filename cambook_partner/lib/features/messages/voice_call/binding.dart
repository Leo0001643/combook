import 'package:get/get.dart';

class VoiceCallBinding extends Bindings {
  @override
  void dependencies() {
    // VoiceCallLogic 是 permanent，已在 main.dart 注册，无需再次注入
  }
}
