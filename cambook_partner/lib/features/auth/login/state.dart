import 'package:get/get.dart';

class LoginState {
  final RxBool   loading    = false.obs;
  final RxBool   obscure    = true.obs;
  final RxInt    mode       = 0.obs;   // 0=phone, 1=techId
  final RxString countryCode = '+855'.obs;
  final RxString countryFlag = '🇰🇭'.obs;
}
