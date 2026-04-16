import 'package:get/get.dart';

class VerifyCodeState {
  /// 从上一页传入的参数
  final phone       = ''.obs;
  final countryCode = '+855'.obs;

  /// 用户输入的验证码
  final code      = ''.obs;
  final isLoading = false.obs;
  final countdown = 0.obs;

  VerifyCodeState();
}
