import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/theme_ext.dart';import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/date_util.dart';
import '../../../core/widgets/common_widgets.dart';
import 'logic.dart';

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final logic = Get.find<ReviewsLogic>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MainAppBar(title: l.reviewsTitle, showBack: true),
      body: Obx(() {
        final reviews = logic.state.reviews;
        return CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _RatingSummary(logic: logic)),
          SliverPadding(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            sliver: reviews.isEmpty
                ? SliverFillRemaining(child: EmptyView(message: l.noReviews))
                : SliverList(delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReviewCard(review: reviews[i]),
                    ),
                    childCount: reviews.length,
                  )),
          ),
        ]);
      }),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final ReviewsLogic logic;
  const _RatingSummary({required this.logic});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      margin: const EdgeInsets.all(AppSizes.pagePadding),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: context.primaryGrad,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(logic.avgRating.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800, height: 1)),
          Row(children: List.generate(5, (i) => Icon(
            i < logic.avgRating.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
            color: Colors.amber, size: 18,
          ))),
          const SizedBox(height: 4),
          Text(l.totalReviews(logic.state.reviews.length), style: AppTextStyles.whiteSm),
        ]),
        const Spacer(),
        Column(children: List.generate(5, (i) {
          final star = 5 - i;
          final cnt  = logic.state.reviews.where((r) => r.rating.round() == star).length;
          final ratio= logic.state.reviews.isEmpty ? 0.0 : cnt / logic.state.reviews.length;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Text('$star', style: AppTextStyles.whiteXs),
              const SizedBox(width: 4),
              SizedBox(width: 100, child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.amber),
                borderRadius: BorderRadius.circular(2),
              )),
            ]),
          );
        })),
      ]),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: context.primary.withValues(alpha: 0.1),
          child: Text(
              review.customerName.isNotEmpty ? review.customerName[0].toUpperCase() : '?',
              style: TextStyle(color: context.primary, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(review.customerName, style: AppTextStyles.label2),
          Text(DateUtil.dateOnly(review.date), style: AppTextStyles.caption),
        ])),
        Row(children: List.generate(5, (i) => Icon(
          i < review.rating.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
          color: Colors.amber, size: 14,
        ))),
      ]),
      if (review.comment != null) ...[
        const SizedBox(height: 8),
        Text(review.comment!, style: AppTextStyles.body3),
      ],
      if (review.tags.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(spacing: 6, children: review.tags.map((tag) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: context.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
          child: Text(tag, style: TextStyle(fontSize: 11, color: context.primary)),
        )).toList()),
      ],
    ]),
  );
}
