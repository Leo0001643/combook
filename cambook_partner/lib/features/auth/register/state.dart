import 'package:get/get.dart';

class RegisterState {
  final RxBool   loading         = false.obs;
  final RxBool   obscurePass     = true.obs;
  final RxBool   obscureConfirm  = true.obs;
  final RxString countryCode     = '+855'.obs;
  final RxString countryFlag     = '🇰🇭'.obs;
}
