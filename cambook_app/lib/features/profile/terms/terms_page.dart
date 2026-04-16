import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 用户协议全文
class TermsPage extends StatelessWidget {
  const TermsPage({super.key, this.showAgreeButton = false});

  /// 为 true 时在底部展示「同意协议」（例如从注册页进入）
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
          l.termsTitle,
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
                      _sectionTitle('1. 服务说明'),
                      const Text(
                        'CamBook 为用户提供上门按摩、SPA 等健康服务的信息展示与预约撮合。具体服务由独立技师或合作商户提供，平台负责技术支持与订单管理。',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '您使用本应用即表示已阅读并理解本协议；若不同意，请停止使用相关服务。',
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle('2. 用户义务'),
                      const Text('您在使用服务时应遵守法律法规及公序良俗，并承诺：'),
                      const SizedBox(height: 8),
                      const Text('• 提供真实、准确的注册与联系信息，并及时更新。'),
                      const SizedBox(height: 6),
                      const Text('• 不得利用平台从事违法、骚扰、侵权或虚假交易等行为。'),
                      const SizedBox(height: 6),
                      const Text('• 妥善保管账号与支付信息，对账号下的操作承担相应责任。'),
                      const SizedBox(height: 20),
                      _sectionTitle('3. 隐私保护'),
                      const Text(
                        '我们按照《隐私政策》处理您的个人信息，仅在为提供服务、保障安全与合规所必需的范围内收集与使用数据。',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '未经您同意，我们不会向第三方出售您的个人隐私数据；共享、转让将在法律允许及政策说明的场景下进行。',
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle('4. 免责声明'),
                      const Text(
                        '因不可抗力、网络故障、第三方服务异常等非平台可控原因导致的服务中断或损失，我们将在合理范围内协助处理，但不承担超出法律规定的责任。',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '技师线下服务过程中的专业判断与操作主体为服务提供方，平台将协助纠纷协调但不构成医疗或治疗承诺。',
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle('5. 协议修改'),
                      const Text(
                        '我们可能适时修订本协议，并通过应用内公告等方式通知。若您在生效后继续使用服务，即视为接受修订后的条款。',
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle('6. 联系我们'),
                      const Text('公司名称：CamBook Technology Co., Ltd.'),
                      const SizedBox(height: 6),
                      const Text('地址：Phnom Penh, Cambodia（示例地址）'),
                      const SizedBox(height: 6),
                      const Text('电子邮箱：legal@cambook.app'),
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
                  child: Text(l.agreeToTerms, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
