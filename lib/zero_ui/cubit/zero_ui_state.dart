// lib/zero_ui/cubit/zero_ui_state.dart
import 'package:equatable/equatable.dart';

enum ZeroUiStatus { idle, listening, processing, speaking, sosTriggered, error }

enum DisplayMode { eyesFree, visualHud }

class ZeroUiState extends Equatable {
  const ZeroUiState({
    this.status = ZeroUiStatus.idle,
    this.displayMode = DisplayMode.eyesFree,
    this.recognizedText = '',
    this.responseText = '',
    this.soundLevel = 0.0,
    this.errorMessage,
  });

  final ZeroUiStatus status;
  final DisplayMode displayMode;
  final String recognizedText;
  final String responseText;
  final double soundLevel;
  final String? errorMessage;

  ZeroUiState copyWith({
    ZeroUiStatus? status,
    DisplayMode? displayMode,
    String? recognizedText,
    String? responseText,
    double? soundLevel,
    String? errorMessage,
  }) {
    return ZeroUiState(
      status: status ?? this.status,
      displayMode: displayMode ?? this.displayMode,
      recognizedText: recognizedText ?? this.recognizedText,
      responseText: responseText ?? this.responseText,
      soundLevel: soundLevel ?? this.soundLevel,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    displayMode,
    recognizedText,
    responseText,
    soundLevel,
    errorMessage,
  ];
}
