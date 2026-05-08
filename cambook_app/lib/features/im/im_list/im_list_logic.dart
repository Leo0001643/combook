import 'package:get/get.dart';
import '../../../core/services/im_service.dart';

class ImListLogic extends GetxController {
  ImService get im => ImService.to;

  @override
  void onInit() {
    super.onInit();
    im.loadConversations();
  }
}
