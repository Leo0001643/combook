import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 隐私政策全文
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key, this.showAgreeButton = false});

  /// 为 true 时在底部展示「同意」按钮（例如注册流程）
  final bool showAgreeButton;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppTheme.gray900),
          onPressed: () => Get.back(),
        ),
        title: Text(
          l.privacyPolicy,
          style: const TextStyle(color: AppTheme.gray900, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.65,
                    color: AppTheme.gray700,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.lastUpdatedApr2026, style: TextStyle(color: AppTheme.gray500.withValues(alpha: 0.9))),
                      const SizedBox(height: 16),
                      _sectionTitle('信息收集'),
                      const Text(
                        '为完成注册、预约、支付与客服沟通，我们可能收集手机号码、昵称、订单信息、设备标识、日志与位置（经您授权）等数据。',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '若您拒绝提供某项必要信息，可能导致对应功能无法使用，我们将在界面中予以提示。',
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle('信息使用'),
                      const Text(
                        '我们使用上述信息用于：创建与管理账号、撮合订单与消息通知、风控与反欺诈、改进产品体验及履行法定义务。',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '在取得您单独同意或法律允许的前提下，我们可能向您发送营销资讯，您可随时在设置中关闭。',
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle('信息共享'),
                      const Text(
                        '我们可能与技师、支付与地图等合作方共享履约所必需的最小必要信息，并要求其按协议承担保密与安全义务。',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '如因合并、收购或法律程序需要转移信息，我们将要求继受方继续受本政策约束或重新征得您的授权。',
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle('信息安全'),
                      const Text(
                        '我们采用加密传输、访问控制、审计与备份等措施保护数据安全，并持续评估第三方服务商的安全能力。',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '请您勿向陌生人泄露验证码、密码或私钥；发现异常请及时修改密码并联系客服。',
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle('用户权利'),
                      const Text(
                        '在适用法律允许的范围内，您可访问、更正、删除个人信息，撤回授权或注销账号。我们将在验证身份后合理期限内响应。',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '如需行使权利或有任何疑问，可通过应用内客服或下方邮箱联系我们。',
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle('联系我们'),
                      const Text('CamBook 数据保护团队'),
                      const SizedBox(height: 6),
                      const Text('电子邮箱：privacy@cambook.app'),
                      const SizedBox(height: 6),
                      const Text('地址：Phnom Penh, Cambodia（示例）'),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (showAgreeButton)
            Container(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + MediaQuery.paddingOf(context).bottom),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.operationSuccess)));
                    Get.back(result: true);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(l.agreeToPrivacy, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        t,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppTheme.gray900,
        ),
      ),
    );
  }
}
