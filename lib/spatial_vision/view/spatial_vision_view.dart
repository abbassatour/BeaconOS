// lib/spatial_vision/view/spatial_vision_view.dart
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/spatial_vision/cubit/spatial_vision_cubit.dart';
import 'package:beacon_os/spatial_vision/cubit/spatial_vision_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

class SpatialVisionView extends StatelessWidget {
  const SpatialVisionView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SpatialVisionCubit(
        repository: context.read<LauncherRepository>(),
      ),
      child: const _SpatialVisionContent(),
    );
  }
}

class _SpatialVisionContent extends StatelessWidget {
  const _SpatialVisionContent();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: BlocBuilder<SpatialVisionCubit, SpatialVisionState>(
          builder: (context, state) {
            final cubit = context.read<SpatialVisionCubit>();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. الترويسة وأدوات الكشاف
                Padding(
                  // زيادة الهامش العلوي لمنع التداخل مع البوصلة
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI VISION STUDIO',
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Swipe LEFT ⬅️ to return to Core',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: state.isTorchOn
                              ? colors.secondary
                              : colors.surface,
                          foregroundColor: state.isTorchOn
                              ? colors.surface
                              : colors.onSurface,
                          side: BorderSide(color: colors.outline),
                        ),
                        icon: Icon(
                          state.isTorchOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                        ),
                        tooltip: 'Toggle Flashlight',
                        onPressed: cubit.toggleTorch,
                      ),
                    ],
                  ),
                ),

                // 2. خيارات أوضاع الفحص الأربعة (Vision Modes)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildModeChip(
                          context: context,
                          title: 'Surroundings',
                          icon: Icons.explore_rounded,
                          isSelected: state.activeMode == VisionMode.surroundings,
                          onTap: () => cubit.setMode(VisionMode.surroundings),
                        ),
                        _buildModeChip(
                          context: context,
                          title: 'Text / Doc',
                          icon: Icons.document_scanner_rounded,
                          isSelected: state.activeMode == VisionMode.textReader,
                          onTap: () => cubit.setMode(VisionMode.textReader),
                        ),
                        _buildModeChip(
                          context: context,
                          title: 'Currency',
                          icon: Icons.payments_rounded,
                          isSelected: state.activeMode == VisionMode.currency,
                          onTap: () => cubit.setMode(VisionMode.currency),
                        ),
                        _buildModeChip(
                          context: context,
                          title: 'Product / Expiry',
                          icon: Icons.qr_code_scanner_rounded,
                          isSelected: state.activeMode == VisionMode.productExpiry,
                          onTap: () => cubit.setMode(VisionMode.productExpiry),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. المسطح الحسي للرادار (Tap anywhere to scan)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: cubit.captureAndAnalyze,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildRadarScanner(context, state),
                          const SizedBox(height: 24),
                          Text(
                            _getStatusTitle(state),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.isBusy
                                ? 'Gemini 2.0 Flash is inspecting scene...'
                                : 'Tap anywhere on screen to scan',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 4. بطاقة نتيجة التحليل الصوتي المكتوبة + أدوات الحفظ
                if (state.lastSpokenResult.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colors.outline,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.onSurface.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.remove_red_eye_rounded,
                                  color: colors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'SCENE DESCRIPTION',
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.volume_up_rounded,
                                    color: colors.primary,
                                    size: 20,
                                  ),
                                  tooltip: 'Replay Description',
                                  onPressed: cubit.replayDescription,
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.bookmark_add_rounded,
                                    color: colors.primary,
                                    size: 20,
                                  ),
                                  tooltip: 'Save to Notes',
                                  onPressed: cubit.saveScanResultAsNote,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.lastSpokenResult,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildModeChip({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: Icon(
          icon,
          color: isSelected ? colors.surface : colors.primary,
          size: 18,
        ),
        label: Text(title),
        selected: isSelected,
        selectedColor: colors.primary,
        backgroundColor: colors.surface,
        side: BorderSide(color: colors.outline, width: 1.2),
        labelStyle: TextStyle(
          color: isSelected ? colors.surface : colors.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _buildRadarScanner(BuildContext context, SpatialVisionState state) {
    final colors = context.colors;
    final isBusy = state.isBusy;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isBusy ? 160 : 130,
      height: isBusy ? 160 : 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.primary.withValues(alpha: isBusy ? 0.15 : 0.06),
        border: Border.all(
          color: colors.primary,
          width: isBusy ? 3.0 : 1.8,
        ),
        boxShadow: [
          if (isBusy)
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.25),
              blurRadius: 28,
              spreadRadius: 4,
            ),
        ],
      ),
      child: Center(
        child: Icon(
          isBusy ? Icons.camera_rounded : Icons.center_focus_strong_rounded,
          color: colors.primary,
          size: isBusy ? 54 : 46,
        ),
      ),
    );
  }

  String _getStatusTitle(SpatialVisionState state) {
    switch (state.status) {
      case VisionStatus.capturing:
        return 'CAPTURING SCENE...';
      case VisionStatus.analyzing:
        return 'ANALYZING WITH AI...';
      case VisionStatus.speaking:
        return 'DESCRIBING...';
      case VisionStatus.error:
        return 'SCAN FAILED';
      case VisionStatus.idle:
        return 'READY TO SCAN';
    }
  }
}