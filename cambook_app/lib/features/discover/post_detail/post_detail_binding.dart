import 'package:get/get.dart';
import 'post_detail_logic.dart';

class PostDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PostDetailLogic>(() => PostDetailLogic());
  }
}
