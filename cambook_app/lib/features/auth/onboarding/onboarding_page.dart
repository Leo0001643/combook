import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 引导页 — 全部使用 i18n，零硬编码
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<_OnboardingData> _buildPages(AppLocalizations l) => [
    _OnboardingData(
      title: l.onboarding1Title,
      subtitle: l.onboarding1Subtitle,
      color: const Color(0xFF1A1F2E),
      accentColor: AppTheme.primaryColor,
      emoji: '💆',
    ),
    _OnboardingData(
      title: l.onboarding2Title,
      subtitle: l.onboarding2Subtitle,
      color: const Color(0xFF1E2A3D),
      accentColor: const Color(0xFF6366F1),
      emoji: '📍',
    ),
    _OnboardingData(
      title: l.onboarding3Title,
      subtitle: l.onboarding3Subtitle,
      color: const Color(0xFF1A2E25),
      accentColor: const Color(0xFF10B981),
      emoji: '💳',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pages = _buildPages(l);

    return Scaffold(
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [pages[_currentPage].color, pages[_currentPage].color.withOpacity(0.8)],
              ),
            ),
          ),
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pages[_currentPage].accentColor.withOpacity(0.08),
              ),
            ),
          ),
          Column(
            children: [
              // 跳过按钮
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.toNamed('/login'),
                        child: Text(l.skip, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: pages.length,
                  itemBuilder: (context, index) => _buildPage(pages[index]),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).padding.bottom + 32),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: i == _currentPage ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: i == _currentPage
                                ? pages[_currentPage].accentColor
                                : Colors.white30,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_currentPage < pages.length - 1)
                      ElevatedButton(
                        onPressed: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pages[_currentPage].accentColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(l.next, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      )
                    else
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: () => Get.toNamed('/register'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(l.getStarted, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Get.toNamed('/login'),
                            child: Text(l.hasAccount, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160, height: 160,
            decoration: BoxDecoration(shape: BoxShape.circle, color: data.accentColor.withOpacity(0.12)),
            child: Center(child: Text(data.emoji, style: const TextStyle(fontSize: 72))),
          ),
          const SizedBox(height: 48),
          Text(data.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 16),
          Text(data.subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 15, height: 1.7)),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String title, subtitle, emoji;
  final Color color, accentColor;
  const _OnboardingData({required this.title, required this.subtitle, required this.color, required this.accentColor, required this.emoji});
}
