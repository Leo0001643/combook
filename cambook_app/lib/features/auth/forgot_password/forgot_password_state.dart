import 'package:get/get.dart';

class ForgotPasswordState {
  final phone       = ''.obs;
  final countryCode = '+855'.obs;
  final smsCode     = ''.obs;
  final newPassword = ''.obs;
  final confirmPwd  = ''.obs;

  final isLoading       = false.obs;
  final obscurePassword = true.obs;
  final countdown       = 0.obs;

  ForgotPasswordState();
}
