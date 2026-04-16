import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 评价提交页 — 订单完成后对技师进行评价
class ReviewPage extends StatefulWidget {
  final String orderId;
  final String technicianName;

  const ReviewPage({super.key, required this.orderId, required this.technicianName});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  double _overall = 5.0;
  double _attitude = 5.0;
  double _professional = 5.0;
  double _punctual = 5.0;
  bool _anonymous = false;
  final _contentCtrl = TextEditingController();
  final Set<String> _selectedTags = {};
  bool _submitting = false;

  List<String> _buildTags(AppLocalizations l) => [
    l.tagProfessional, l.tagFriendly, l.tagOnTime, l.tagCareful,
    l.tagClean, l.tagValueForMoney, l.tagGoodComm, l.tagRepurchase,
  ];

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppTheme.gray900),
          onPressed: () => Get.back(),
        ),
        title: Text(l.writeReview, style: const TextStyle(color: AppTheme.gray900, fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildTechInfo(l),
          const SizedBox(height: 16),
          _buildOverallRating(l),
          const SizedBox(height: 16),
          _buildDetailRatings(l),
          const SizedBox(height: 16),
          _buildTagsSection(l),
          const SizedBox(height: 16),
          _buildContentInput(l),
          const SizedBox(height: 16),
          _buildAnonymousToggle(l),
          const SizedBox(height: 24),
          _buildSubmitButton(l),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _buildTechInfo(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [AppTheme.primaryColor.withValues(alpha: 0.7), AppTheme.primaryColor]),
          ),
          child: const Center(child: Icon(Icons.person, color: Colors.white, size: 28)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.technicianName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.gray900)),
          const SizedBox(height: 4),
          Text('${l.orderNo}: ${widget.orderId}', style: const TextStyle(fontSize: 12, color: AppTheme.gray400)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
          child: Text(l.orderCompleted, style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _buildOverallRating(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Text(l.overallRating, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.gray900)),
        const SizedBox(height: 16),
        Text(_ratingLabel(_overall, l), style: TextStyle(fontSize: 14, color: _overall >= 4 ? Colors.amber.shade700 : AppTheme.gray500)),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) {
          return GestureDetector(
            onTap: () => setState(() => _overall = (i + 1).toDouble()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                i < _overall ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 40,
                color: Colors.amber,
              ),
            ),
          );
        })),
      ]),
    );
  }

  String _ratingLabel(double v, AppLocalizations l) {
    if (v == 5) return l.ratingVeryGood;
    if (v == 4) return l.ratingGood;
    if (v == 3) return l.ratingOk;
    if (v == 2) return l.ratingBad;
    return l.ratingVeryBad;
  }

  Widget _buildDetailRatings(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        _ratingRow(l.techniqueScore, _professional, (v) => setState(() => _professional = v), l),
        const SizedBox(height: 12),
        _ratingRow(l.attitudeScore, _attitude, (v) => setState(() => _attitude = v), l),
        const SizedBox(height: 12),
        _ratingRow(l.punctualityScore, _punctual, (v) => setState(() => _punctual = v), l),
      ]),
    );
  }

  Widget _ratingRow(String label, double value, ValueChanged<double> onChanged, AppLocalizations l) {
    return Row(children: [
      SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.gray600))),
      Expanded(
        child: Row(children: List.generate(5, (i) {
          return GestureDetector(
            onTap: () => onChanged((i + 1).toDouble()),
            child: Icon(
              i < value ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 24,
              color: Colors.amber,
            ),
          );
        })),
      ),
      Text(l.scoreFmt(value.toInt()), style: const TextStyle(fontSize: 12, color: AppTheme.gray400)),
    ]);
  }

  Widget _buildTagsSection(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.reviewTags, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _buildTags(l).map((tag) {
            final selected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () => setState(() {
                if (selected) _selectedTags.remove(tag); else _selectedTags.add(tag);
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primaryColor.withValues(alpha: 0.1) : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(20),
                  border: selected ? Border.all(color: AppTheme.primaryColor, width: 1.5) : null,
                ),
                child: Text(tag, style: TextStyle(fontSize: 13, color: selected ? AppTheme.primaryColor : AppTheme.gray600, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  Widget _buildContentInput(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.reviewContent.replaceAll('...', ''), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
        const SizedBox(height: 10),
        TextField(
          controller: _contentCtrl,
          maxLines: 4,
          maxLength: 200,
          style: const TextStyle(fontSize: 14, color: AppTheme.gray900),
          decoration: InputDecoration(
            hintText: l.reviewContent,
            hintStyle: const TextStyle(color: AppTheme.gray300, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {},
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.add_photo_alternate_outlined, size: 22, color: AppTheme.gray400),
              const SizedBox(width: 8),
              Text(l.addPhoto, style: const TextStyle(fontSize: 13, color: AppTheme.gray400)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildAnonymousToggle(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const Icon(Icons.person_outline, size: 20, color: AppTheme.gray400),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.anonymous, style: const TextStyle(fontSize: 15, color: AppTheme.gray900)),
          const SizedBox(height: 2),
          Text(l.anonymousHint, style: const TextStyle(fontSize: 12, color: AppTheme.gray400)),
        ])),
        Switch(value: _anonymous, onChanged: (v) => setState(() => _anonymous = v), activeColor: AppTheme.primaryColor),
      ]),
    );
  }

  Widget _buildSubmitButton(AppLocalizations l) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _submitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _submitting
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(l.submitReview, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    if (_overall == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.selectRatingHint),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).operationSuccess),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      Get.back();
    }
  }
}
