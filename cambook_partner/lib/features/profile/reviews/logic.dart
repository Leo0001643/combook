import 'package:get/get.dart';
import '../../../core/mock/mock_data.dart';
import 'state.dart';

class ReviewsLogic extends GetxController {
  final ReviewsState state = ReviewsState();

  double get avgRating {
    if (state.reviews.isEmpty) return 0;
    return state.reviews.fold(0.0, (s, r) => s + r.rating) / state.reviews.length;
  }

  @override
  void onInit() {
    super.onInit();
    state.reviews.assignAll(MockData.reviews);
  }
}
