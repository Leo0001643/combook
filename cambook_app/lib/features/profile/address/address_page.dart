import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 地址管理页
class AddressPage extends StatefulWidget {
  const AddressPage({super.key});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  final List<Map<String, dynamic>> _addresses = [
    {
      'id': '1',
      'name': 'Sokha Chan',
      'phone': '+855 12 345 678',
      'detail': 'BKK1, Chamkarmon, Building 5, Room 201',
      'city': 'Phnom Penh',
      'isDefault': true,
    },
    {
      'id': '2',
      'name': 'Sokha Chan',
      'phone': '+855 12 345 678',
      'detail': 'Toul Tom Poung, Street 163, House 42',
      'city': 'Phnom Penh',
      'isDefault': false,
    },
  ];

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
        title: Text(l.addressManage, style: const TextStyle(color: AppTheme.gray900, fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddressForm(context, l),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(l.addAddress, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _addresses.isEmpty
          ? _buildEmpty(l)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _addresses.length,
              itemBuilder: (_, i) => _buildAddressCard(context, l, _addresses[i], i),
            ),
    );
  }

  Widget _buildEmpty(AppLocalizations l) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.location_off_outlined, size: 72, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(l.noData, style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
      ]),
    );
  }

  Widget _buildAddressCard(BuildContext context, AppLocalizations l, Map<String, dynamic> addr, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: addr['isDefault'] as bool
            ? Border.all(color: AppTheme.primaryColor, width: 1.5)
            : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(addr['detail'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
                    const SizedBox(height: 4),
                    Text(addr['city'] as String, style: const TextStyle(fontSize: 13, color: AppTheme.gray500)),
                  ],
                ),
              ),
              if (addr['isDefault'] as bool)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(l.defaultAddress, style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.person_outline, size: 14, color: AppTheme.gray400),
              const SizedBox(width: 4),
              Text('${addr['name']}   ${addr['phone']}', style: const TextStyle(fontSize: 13, color: AppTheme.gray500)),
            ]),
            const Divider(height: 20),
            Row(children: [
              if (!(addr['isDefault'] as bool))
                GestureDetector(
                  onTap: () => setState(() {
                    for (var a in _addresses) { a['isDefault'] = false; }
                    _addresses[index]['isDefault'] = true;
                  }),
                  child: Row(children: [
                    const Icon(Icons.radio_button_unchecked, size: 16, color: AppTheme.gray400),
                    const SizedBox(width: 4),
                    Text(l.setDefault, style: const TextStyle(fontSize: 13, color: AppTheme.gray500)),
                  ]),
                ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showAddressForm(context, l, existing: addr, index: index),
                child: Row(children: [
                  const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Text(l.edit, style: const TextStyle(fontSize: 13, color: AppTheme.primaryColor)),
                ]),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => _confirmDelete(context, l, index),
                child: Row(children: [
                  const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(l.delete, style: const TextStyle(fontSize: 13, color: Colors.red)),
                ]),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppLocalizations l, int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.delete),
        content: Text(l.cancel),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          TextButton(
            onPressed: () {
              setState(() => _addresses.removeAt(index));
              Navigator.pop(context);
            },
            child: Text(l.confirm, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddressForm(BuildContext context, AppLocalizations l, {Map<String, dynamic>? existing, int? index}) {
    final nameCtrl = TextEditingController(text: existing?['name'] as String? ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phone'] as String? ?? '');
    final detailCtrl = TextEditingController(text: existing?['detail'] as String? ?? '');
    final cityCtrl = TextEditingController(text: existing?['city'] as String? ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(existing == null ? l.addAddress : l.editAddress, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.gray900)),
              const SizedBox(height: 20),
              _formField(l.contactName, nameCtrl, Icons.person_outline),
              const SizedBox(height: 12),
              _formField(l.contactPhone, phoneCtrl, Icons.phone_outlined, keyboard: TextInputType.phone),
              const SizedBox(height: 12),
              _formField(l.detailAddress, detailCtrl, Icons.location_on_outlined),
              const SizedBox(height: 12),
              _formField('City', cityCtrl, Icons.location_city_outlined),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty && detailCtrl.text.isNotEmpty) {
                      final entry = {
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'name': nameCtrl.text,
                        'phone': phoneCtrl.text,
                        'detail': detailCtrl.text,
                        'city': cityCtrl.text,
                        'isDefault': existing?['isDefault'] ?? false,
                      };
                      setState(() {
                        if (index != null) {
                          _addresses[index] = entry;
                        } else {
                          _addresses.add(entry);
                        }
                      });
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(l.save, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formField(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 15, color: AppTheme.gray900),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20, color: AppTheme.gray400),
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: AppTheme.gray400),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
