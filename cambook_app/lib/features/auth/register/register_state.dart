import 'package:get/get.dart';

class RegisterState {
  final phone          = ''.obs;
  final countryCode    = '+855'.obs;
  final smsCode        = ''.obs;
  final password       = ''.obs;
  final confirmPwd     = ''.obs;
  final inviteCode     = ''.obs;
  final userType       = 1.obs;  // 1=会员 2=技师 3=商户

  final isLoading       = false.obs;
  final obscurePassword = true.obs;
  final agreedTerms     = false.obs;
  final countdown       = 0.obs;

  RegisterState();
}
