// lib/onboarding/gateway/view/onboarding_gateway_page.dart
import 'package:beacon_os/core/audio/sound_controller.dart';
import 'package:beacon_os/core/audio/sound_cue.dart';
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/core/theme/cubit/theme_cubit.dart';
import 'package:beacon_os/onboarding/blind_flow/view/blind_onboarding_page.dart';
import 'package:beacon_os/onboarding/minimalist_flow/view/minimalist_onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

class OnboardingGatewayPage extends StatefulWidget {
  const OnboardingGatewayPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const OnboardingGatewayPage(),
    );
  }

  @override
  State<OnboardingGatewayPage> createState() => _OnboardingGatewayPageState();
}

class _OnboardingGatewayPageState extends State<OnboardingGatewayPage> {
  @override
  void initState() {
    super.initState();
    // 🔊 إطلاق التوجيه الصوتي فوراً ليعلم الكفيف أين يضع إصبعه
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _announceGatewayInstructions();
    });
  }

  Future<void> _announceGatewayInstructions() async {
    final assistant = context.read<AssistantRepository>(); // 👈 تم التحديث
    await SoundController.instance.play(SoundCue.wake);
    await HapticFeedback.mediumImpact();
    await assistant.speak( // 👈 تم التحديث
      'Welcome to Beacon OS. Tap the top half of your screen for Vision and Accessibility Mode. '
      'Tap the bottom half for Digital Minimalist Mode.',
    );
  }

  void _selectBlindFlow() {
    final assistant = context.read<AssistantRepository>(); // 👈 تم التحديث
    assistant.stopSpeaking(); // 👈 تم التحديث

    // 1. تفعيل ثيم التباين العالي فوراً
    context.read<ThemeCubit>().toggleTheme(isHighContrast: true);
    SoundController.instance.play(SoundCue.navCenter);
    HapticFeedback.heavyImpact();

    // 2. الانتقال إلى مسار الكفيف المستقل
    Navigator.of(context).pushReplacement(BlindOnboardingPage.route());
  }

  void _selectMinimalistFlow() {
    final assistant = context.read<AssistantRepository>(); // 👈 تم التحديث
    assistant.stopSpeaking(); // 👈 تم التحديث

    // 1. تفعيل ثيم الورق الهادئ
    context.read<ThemeCubit>().toggleTheme(isHighContrast: false);
    SoundController.instance.play(SoundCue.navCenter);
    HapticFeedback.mediumImpact();

    // 2. الانتقال إلى مسار المينيماليست المستقل
    Navigator.of(context).pushReplacement(MinimalistOnboardingPage.route());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // ==============================================================
            // 🌌 النصف العلوي: مسار المكفوفين وضعاف البصر (OLED Pure Black)
            // ==============================================================
            Expanded(
              child: Semantics(
                label:
                    'Vision and Accessibility Mode. Tap anywhere on the upper half of the screen to choose this path.',
                button: true,
                child: Material(
                  color: AppTheme.pureBlack,
                  child: InkWell(
                    onTap: _selectBlindFlow,
                    splashColor: AppTheme.cyanHighlight.withValues(alpha: 0.25),
                    highlightColor: AppTheme.cyanHighlight.withValues(alpha: 0.12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppTheme.cyanHighlight,
                            width: 2.5,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.cyanHighlight,
                                width: 2,
                              ),
                              color: AppTheme.cyanHighlight.withValues(alpha: 0.12),
                            ),
                            child: const Icon(
                              Icons.visibility_rounded,
                              size: 48,
                              color: AppTheme.cyanHighlight,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'VISION & ACCESSIBILITY',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.highContrastText,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'High-contrast OLED display, voice guidance, spatial camera vision, and emergency radar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.highContrastMuted,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: AppTheme.cyanHighlight.withValues(alpha: 0.15),
                              border: Border.all(color: AppTheme.cyanHighlight),
                            ),
                            child: const Text(
                              'TAP TOP HALF TO SELECT',
                              style: TextStyle(
                                color: AppTheme.cyanHighlight,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ==============================================================
            // 📜 النصف السفلي: مسار التقليلية الرقمية والتركيز (Warm Paper)
            // ==============================================================
            Expanded(
              child: Semantics(
                label:
                    'Digital Minimalist Mode. Tap anywhere on the lower half of the screen to choose this path.',
                button: true,
                child: Material(
                  color: AppTheme.warmPaper,
                  child: InkWell(
                    onTap: _selectMinimalistFlow,
                    splashColor: AppTheme.terracotta.withValues(alpha: 0.15),
                    highlightColor: AppTheme.terracotta.withValues(alpha: 0.08),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.softBorder,
                                width: 2,
                              ),
                              color: AppTheme.cardSurface,
                            ),
                            child: const Icon(
                              Icons.spa_rounded,
                              size: 48,
                              color: AppTheme.terracotta,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'DIGITAL MINIMALIST',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.carbonInk,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Calm editorial canvas, intentional eyes-free productivity, focus sessions, and zero distractions.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.mutedInk,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: AppTheme.terracotta.withValues(alpha: 0.1),
                              border: Border.all(color: AppTheme.terracotta),
                            ),
                            child: const Text(
                              'TAP BOTTOM HALF TO SELECT',
                              style: TextStyle(
                                color: AppTheme.terracotta,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}