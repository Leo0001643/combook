import 'package:get/get.dart';
import '../../../core/models/models.dart';
import '../../../core/services/user_service.dart';
import 'state.dart';

class ProfileIndexLogic extends GetxController {
  final ProfileIndexState state = ProfileIndexState();

  UserService get _user => Get.find<UserService>();
  TechnicianModel? get technician => _user.technician.value;
  TechStatus get status => _user.status.value;

  void logout() => Get.find<UserService>().logout();
}
