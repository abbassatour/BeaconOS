// lib/spatial_vision/cubit/spatial_vision_state.dart
import 'package:equatable/equatable.dart';

enum VisionStatus { idle, capturing, analyzing, speaking, error }

enum VisionMode {
  surroundings, // المحيط والعوائق
  textReader, // قراءة المستندات واللافتات
  currency, // قراءة النقود والعملات
  productExpiry, // اسم المنتج وتاريخ الصلاحية
}

class SpatialVisionState extends Equatable {
  const SpatialVisionState({
    this.status = VisionStatus.idle,
    this.activeMode = VisionMode.surroundings,
    this.lastSpokenResult = '',
    this.isTorchOn = false,
    this.errorMessage,
  });

  final VisionStatus status;
  final VisionMode activeMode;
  final String lastSpokenResult;
  final bool isTorchOn;
  final String? errorMessage;

  bool get isBusy =>
      status == VisionStatus.capturing || status == VisionStatus.analyzing;

  SpatialVisionState copyWith({
    VisionStatus? status,
    VisionMode? activeMode,
    String? lastSpokenResult,
    bool? isTorchOn,
    String? errorMessage,
  }) {
    return SpatialVisionState(
      status: status ?? this.status,
      activeMode: activeMode ?? this.activeMode,
      lastSpokenResult: lastSpokenResult ?? this.lastSpokenResult,
      isTorchOn: isTorchOn ?? this.isTorchOn,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    activeMode,
    lastSpokenResult,
    isTorchOn,
    errorMessage,
  ];
}
