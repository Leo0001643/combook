import 'package:get/get.dart';

class SettingsState {
  final RxBool   notifyOrder   = true.obs;
  final RxBool   notifyMessage = true.obs;
  final RxBool   notifySystem  = true.obs;
  final RxString locale        = ''.obs;
  final RxString nickname      = ''.obs;
  final RxString phone         = ''.obs;
}
