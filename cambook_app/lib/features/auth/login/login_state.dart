import 'package:get/get.dart';

class LoginState {
  // ── 表单字段 ──────────────────────────────────────────────────────
  final phone       = ''.obs;
  final password    = ''.obs;
  final smsCode     = ''.obs;
  final countryCode = '+855'.obs;
  final userType    = 1.obs;  // 1=会员 2=技师 3=商户

  // ── UI 状态 ───────────────────────────────────────────────────────
  final isLoading        = false.obs;
  final isSmsMode        = true.obs;  // true=验证码登录 false=密码登录
  final obscurePassword  = true.obs;
  final agreedTerms      = false.obs;

  // ── 验证码倒计时 ──────────────────────────────────────────────────
  final countdown = 0.obs;

  LoginState();
}
