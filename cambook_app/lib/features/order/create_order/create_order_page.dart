import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 创建订单页 — 下单预约，全部 i18n
class CreateOrderPage extends StatefulWidget {
  final String technicianId;
  final String packageId;
  const CreateOrderPage({super.key, required this.technicianId, required this.packageId});

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _addressCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.gray900), onPressed: () => Get.back()),
        title: Text(l.createOrder, style: const TextStyle(color: AppTheme.gray900, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 已选套餐信息
                  _buildSelectedPackage(l),
                  const SizedBox(height: 12),
                  // 时间选择
                  _buildSection(l.selectDateTime, Icons.calendar_today_outlined, _buildDateTimePicker(l)),
                  const SizedBox(height: 12),
                  // 地址
                  _buildSection(l.selectAddress, Icons.location_on_outlined, _buildAddressInput(l)),
                  const SizedBox(height: 12),
                  // 优惠券
                  _buildCouponRow(l),
                  const SizedBox(height: 12),
                  // 备注
                  _buildSection(l.remarks, Icons.edit_note_outlined, _buildRemarkInput(l)),
                  const SizedBox(height: 12),
                  // 价格明细
                  _buildPriceDetail(l),
                ],
              ),
            ),
          ),
          _buildBottomBar(l),
        ],
      ),
    );
  }

  Widget _buildSelectedPackage(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          width: 54, height: 54,
          decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.spa, color: AppTheme.primaryColor, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('陈秀玲', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          Text(l.services + ' · ' + l.duration(60), style: const TextStyle(fontSize: 13, color: AppTheme.gray500)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(l.memberPriceLabel, style: const TextStyle(fontSize: 11, color: AppTheme.gray400)),
          const Text('\$40.00', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.red)),
        ]),
      ]),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
        ]),
        const SizedBox(height: 12),
        content,
      ]),
    );
  }

  Widget _buildDateTimePicker(AppLocalizations l) {
    return Row(children: [
      Expanded(
        child: GestureDetector(
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
            if (d != null) setState(() => _selectedDate = d);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(color: AppTheme.gray100, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(Icons.calendar_today, size: 16, color: _selectedDate == null ? AppTheme.gray400 : AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                _selectedDate == null ? l.selectDateTime.split(' ')[0] : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 13, color: _selectedDate == null ? AppTheme.gray400 : AppTheme.gray900),
              ),
            ]),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: GestureDetector(
          onTap: () async {
            final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 14, minute: 0));
            if (t != null) setState(() => _selectedTime = t);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(color: AppTheme.gray100, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(Icons.access_time, size: 16, color: _selectedTime == null ? AppTheme.gray400 : AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                _selectedTime == null ? l.selectDateTime.split(' ').last : _selectedTime!.format(context),
                style: TextStyle(fontSize: 13, color: _selectedTime == null ? AppTheme.gray400 : AppTheme.gray900),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _buildAddressInput(AppLocalizations l) {
    return TextFormField(
      controller: _addressCtrl,
      decoration: InputDecoration(
        hintText: l.detailAddress,
        hintStyle: const TextStyle(color: AppTheme.gray400, fontSize: 13),
        filled: true, fillColor: AppTheme.gray100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        suffixIcon: IconButton(icon: const Icon(Icons.my_location, color: AppTheme.primaryColor, size: 20), onPressed: () {}),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildCouponRow(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.local_offer_outlined, size: 18, color: Colors.red),
        const SizedBox(width: 8),
        Text(l.myCoupons, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(l.noCoupon, style: const TextStyle(fontSize: 13, color: AppTheme.gray400)),
        const Icon(Icons.chevron_right, color: AppTheme.gray300, size: 18),
      ]),
    );
  }

  Widget _buildRemarkInput(AppLocalizations l) {
    return TextFormField(
      controller: _remarkCtrl,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: l.remarks,
        hintStyle: const TextStyle(color: AppTheme.gray400, fontSize: 13),
        filled: true, fillColor: AppTheme.gray100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildPriceDetail(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        _PriceRow(label: l.originalPrice, value: '\$45.00'),
        const SizedBox(height: 8),
        _PriceRow(label: l.discountAmount, value: '-\$5.00', valueColor: Colors.green),
        const Divider(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l.payAmount, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const Text('\$40.00', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.red)),
        ]),
      ]),
    );
  }

  Widget _buildBottomBar(AppLocalizations l) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -2))]),
      child: ElevatedButton(
        onPressed: _isLoading ? null : () {
          setState(() => _isLoading = true);
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Get.toNamed('/payment?orderId=new_order_001');
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(l.submitOrder, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _PriceRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.gray500)),
      Text(value, style: TextStyle(fontSize: 13, color: valueColor ?? AppTheme.gray900, fontWeight: FontWeight.w500)),
    ]);
  }
}
