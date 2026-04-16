import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'verify_code_logic.dart';

/// 验证码输入页
/// phone 和 countryCode 通过 Get.arguments 传入，由 VerifyCodeLogic 管理
class VerifyCodePage extends GetView<VerifyCodeLogic> {
  const VerifyCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.gray900),
          onPressed: controller.goBack,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(l.verifyCode, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.gray900)),
            const SizedBox(height: 8),
            Obx(() => RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: AppTheme.gray500, height: 1.5),
                children: [
                  TextSpan(text: '${l.sendCode} '),
                  TextSpan(
                    text: '${controller.state.countryCode.value} ${controller.state.phone.value}',
                    style: const TextStyle(color: AppTheme.gray900, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 40),
            _CodeInputRow(logic: controller),
            const SizedBox(height: 32),
            Obx(() => Center(
              child: controller.state.countdown.value > 0
                  ? Text(
                      l.resendCountdown(controller.state.countdown.value),
                      style: const TextStyle(color: AppTheme.gray400, fontSize: 14),
                    )
                  : TextButton(
                      onPressed: controller.sendSmsCode,
                      child: Text(l.sendCode, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                    ),
            )),
            const SizedBox(height: 32),
            Obx(() => ElevatedButton(
              onPressed: controller.state.isLoading.value ? null : controller.verifyAndLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: controller.state.isLoading.value
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(l.confirm, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            )),
          ],
        ),
      ),
    );
  }
}

class _CodeInputRow extends StatefulWidget {
  final VerifyCodeLogic logic;
  const _CodeInputRow({required this.logic});

  @override
  State<_CodeInputRow> createState() => _CodeInputRowState();
}

class _CodeInputRowState extends State<_CodeInputRow> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes  = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNodes[0].requestFocus());
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) => _codeBox(i)),
    );
  }

  Widget _codeBox(int index) {
    return SizedBox(
      width: 48, height: 58,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        maxLength: 1,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.gray900),
        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppTheme.gray100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.gray200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (v) {
          if (v.isNotEmpty && index < 5) _focusNodes[index + 1].requestFocus();
          if (v.isEmpty && index > 0)   _focusNodes[index - 1].requestFocus();
          // 更新 logic state 中的 code
          final code = _controllers.map((c) => c.text).join();
          widget.logic.state.code.value = code;
        },
      ),
    );
  }
}
