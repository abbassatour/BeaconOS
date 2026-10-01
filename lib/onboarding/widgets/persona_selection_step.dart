// lib/onboarding/widgets/persona_selection_step.dart
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/onboarding/cubit/onboarding_cubit.dart';
import 'package:beacon_os/onboarding/cubit/onboarding_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PersonaSelectionStep extends StatelessWidget {
  const PersonaSelectionStep({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();

    return Column(
      children: [
        // ==============================================================
        // 🌌 النصف العلوي: وضع المكفوفين وضعاف البصر (Ice-Void OLED)
        // ==============================================================
        Expanded(
          child: Semantics(
            label:
                'Vision and Accessibility Mode. Tap anywhere on the upper half to activate.',
            button: true,
            child: Material(
              color: AppTheme.pureBlack,
              child: InkWell(
                onTap: () => cubit.selectPersona(UserPersona.blindAccessible),
                splashColor: AppTheme.cyanHighlight.withValues(alpha: 0.2),
                highlightColor: AppTheme.cyanHighlight.withValues(alpha: 0.1),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
        // 📜 النصف السفلي: وضع التقليلية الرقمية والتركيز (Warm Paper)
        // ==============================================================
        Expanded(
          child: Semantics(
            label:
                'Digital Minimalist Mode. Tap anywhere on the lower half to activate.',
            button: true,
            child: Material(
              color: AppTheme.warmPaper,
              child: InkWell(
                onTap: () => cubit.selectPersona(UserPersona.digitalMinimalist),
                splashColor: AppTheme.terracotta.withValues(alpha: 0.15),
                highlightColor: AppTheme.terracotta.withValues(alpha: 0.08),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
    );
  }
}