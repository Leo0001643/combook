import 'package:get/get.dart';

class RegisterState {
  final RxBool   loading         = false.obs;
  final RxBool   obscurePass     = true.obs;
  final RxBool   obscureConfirm  = true.obs;
  final RxString countryCode     = '+855'.obs;    // 默认柬埔寨
  final RxString countryFlag     = '🇰🇭'.obs;
  final RxInt    step            = 0.obs;          // 0=基本信息 1=社交账号
}
