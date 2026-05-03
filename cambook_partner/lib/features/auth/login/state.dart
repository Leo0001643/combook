import 'package:get/get.dart';

class LoginState {
  final RxBool   loading     = false.obs;
  final RxBool   obscure     = true.obs;
  final RxInt    mode        = 1.obs;   // 0=phone, 1=techId（默认技师编号登录）
  final RxBool   rememberMe  = false.obs;
  final RxString countryCode = '+855'.obs;
  final RxString countryFlag = '🇰🇭'.obs;
}
