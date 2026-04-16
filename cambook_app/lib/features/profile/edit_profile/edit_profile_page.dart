import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 编辑个人资料页
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nicknameCtrl = TextEditingController(text: 'Sokha Chan');
  final _birthdayCtrl = TextEditingController(text: '1995-06-15');
  String _selectedGender = 'male';
  bool _saving = false;

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _birthdayCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).operationSuccess),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Get.back();
    }
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
        title: Text(l.editProfile, style: const TextStyle(color: AppTheme.gray900, fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                : Text(l.save, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // 头像
          _buildAvatarSection(l),
          const SizedBox(height: 16),
          // 表单
          _buildFormSection(l),
        ]),
      ),
    );
  }

  Widget _buildAvatarSection(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: GestureDetector(
          onTap: _pickAvatar,
          child: Stack(
            children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [AppTheme.primaryColor.withValues(alpha: 0.7), AppTheme.primaryColor]),
                ),
                child: const Center(child: Icon(Icons.person, size: 50, color: Colors.white)),
              ),
              Positioned(
                bottom: 2, right: 2,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection(AppLocalizations l) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildTextField(label: l.nickname, controller: _nicknameCtrl, icon: Icons.person_outline),
          _divider(),
          _buildGenderRow(l),
          _divider(),
          _buildDatePicker(l),
          _divider(),
          _buildPhoneRow(l),
        ],
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.gray400),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 15, color: AppTheme.gray900),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: AppTheme.gray400, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderRow(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.wc_outlined, size: 20, color: AppTheme.gray400),
          const SizedBox(width: 12),
          Text(l.gender, style: const TextStyle(fontSize: 13, color: AppTheme.gray400)),
          const Spacer(),
          _genderChip(l.male, 'male'),
          const SizedBox(width: 10),
          _genderChip(l.female, 'female'),
        ],
      ),
    );
  }

  Widget _genderChip(String label, String value) {
    final selected = _selectedGender == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, color: selected ? Colors.white : AppTheme.gray600, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  Widget _buildDatePicker(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.cake_outlined, size: 20, color: AppTheme.gray400),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _birthdayCtrl,
              readOnly: true,
              style: const TextStyle(fontSize: 15, color: AppTheme.gray900),
              onTap: () => _selectDate(),
              decoration: InputDecoration(
                labelText: l.birthday,
                labelStyle: const TextStyle(color: AppTheme.gray400, fontSize: 13),
                border: InputBorder.none, isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: const Icon(Icons.chevron_right, color: AppTheme.gray300),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneRow(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.phone_outlined, size: 20, color: AppTheme.gray400),
          const SizedBox(width: 12),
          Text(l.phone, style: const TextStyle(fontSize: 13, color: AppTheme.gray400)),
          const Spacer(),
          const Text('+855 12 xxx 678', style: TextStyle(fontSize: 15, color: AppTheme.gray700)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18, color: AppTheme.gray300),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 48);

  Future<void> _pickAvatar() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryColor),
          title: Text(AppLocalizations.of(context).takePhoto),
          onTap: () => Navigator.pop(context),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryColor),
          title: Text(AppLocalizations.of(context).chooseFromGallery),
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 6, 15),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _birthdayCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }
}
