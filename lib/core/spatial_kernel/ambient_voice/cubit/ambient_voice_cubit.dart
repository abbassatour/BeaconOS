// lib/core/spatial_kernel/ambient_voice/cubit/ambient_voice_cubit.dart
import 'dart:async';
import 'package:beacon_os/core/audio/sound_controller.dart';
import 'package:beacon_os/core/audio/sound_cue.dart';
import 'package:beacon_os/core/haptics/haptic_manager.dart';
import 'package:beacon_os/core/spatial_kernel/ambient_voice/cubit/ambient_voice_state.dart';
import 'package:beacon_os/core/spatial_kernel/voice_command_dispatcher.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';

class AmbientVoiceCubit extends Cubit<AmbientVoiceState> {
  AmbientVoiceCubit({
    required AssistantRepository assistantRepository,
    required VoiceCommandDispatcher voiceDispatcher,
    SoundController? soundController,
    HapticManager? hapticManager,
  })  : _assistant = assistantRepository,
        _dispatcher = voiceDispatcher,
        _sound = soundController ?? SoundController.instance,
        _haptics = hapticManager ?? HapticManager.instance,
        super(const AmbientVoiceState());

  final AssistantRepository _assistant;
  final VoiceCommandDispatcher _dispatcher;
  final SoundController _sound;
  final HapticManager _haptics;

  StreamSubscription<String>? _textSubscription;
  StreamSubscription<double>? _soundLevelSubscription;
  StreamSubscription<VoiceRecognitionEvent>? _recognitionSubscription;
  Timer? _autoCloseTimer;

  /// 1. بدء جلسة المساعد الصوتي فور سحب الزاوية أو الضغط المطول
  Future<void> startSession() async {
    _cancelSubscriptions();
    _autoCloseTimer?.cancel();

    // إيقاف أي أصوات أو قراءات سابقة
    await _sound.stopAll();
    await _assistant.stopSpeaking();

    // تشغيل نغمة الإيقاظ والنبض اللمسي
    await _sound.play(SoundCue.wake);
    _haptics.startListeningPulse();

    emit(
      state.copyWith(
        status: AmbientVoiceStatus.listening,
        liveTranscript: '',
        soundLevel: 0.0,
        spokenResponse: '',
        intent: null,
      ),
    );

    // ربط تدفق الكلمات اللحظية لتحديث الواجهة فوراً
    _textSubscription = _assistant.textStream.listen((text) {
      if (state.isListening && text.isNotEmpty) {
        emit(state.copyWith(liveTranscript: text));
      }
    });

    // ربط مقياس شدة الصوت لتحريك موجات الرادار
    _soundLevelSubscription = _assistant.soundLevelStream.listen((level) {
      if (state.isListening) {
        emit(state.copyWith(soundLevel: level));
      }
    });

    // الاستماع لاكتمال الجملة تلقائياً من محرك SpeechToText
    _recognitionSubscription =
        _assistant.recognitionStream.listen((event) async {
      if (event.isFinal && event.text.trim().isNotEmpty && state.isListening) {
        await stopAndExecute(queryOverride: event.text);
      }
    });

    // فتح الميكروفون الفعلي
    await _assistant.startListening();
  }

  /// 2. إيقاف الاستماع وتنفيذ الأمر الصوتي مع تزويده بسياق النظام الحي
  Future<void> stopAndExecute({
    BuildContext? context,
    String? queryOverride,
  }) async {
    if (!state.isListening && !state.isProcessing) return;

    _haptics.stopListeningPulse();
    await _sound.play(SoundCue.processing);

    emit(state.copyWith(status: AmbientVoiceStatus.processing));

    final recognizedFromMic = await _assistant.stopListening();
    final effectiveQuery = queryOverride ??
        (recognizedFromMic.isNotEmpty
            ? recognizedFromMic
            : state.liveTranscript.trim());

    if (effectiveQuery.isEmpty) {
      await _sound.play(SoundCue.error);
      await _haptics.errorAlert();
      await _assistant.speak(
        "I didn't catch that. Please hold or swipe to try again.",
      );
      closeSession();
      return;
    }

    // ⚡️ إثراء سياق النظام الحي لقاعدة البيانات وتمريره لـ Gemini 2.0 Flash
    Map<String, dynamic>? systemContext;
    if (context != null) {
      try {
        final tasksRepo = context.read<TaskAgendaRepository>();
        final alarmsRepo = context.read<FocusAlarmsRepository>();
        final settingsRepo = context.read<SettingsRepository>();

        final tasks = await tasksRepo.getPendingTasks();
        final alarms = await alarmsRepo.watchAlarms().first;
        final settings = await settingsRepo.getSettings();

        systemContext = {
          'tasks': tasks
              .map((t) => {
                    'id': t.id,
                    'title': t.title,
                    'priority': t.priority,
                    'due_date': t.dueDate?.toIso8601String(),
                  })
              .toList(),
          'alarms': alarms
              .map((a) => {
                    'id': a.id,
                    'hour': a.hour,
                    'minute': a.minute,
                    'label': a.label,
                    'isActive': a.isActive,
                  })
              .toList(),
          'settings': {
            'speech_rate': settings.speechRate,
            'haptics_enabled': settings.hapticsEnabled,
            'is_high_contrast': settings.isHighContrast,
          },
        };
      } catch (_) {
        // حماية: إذا فشل جلب السياق يستمر تنفيذ الأمر الصوتي دون انهيار
      }
    }

    // إرسال الأمر لحافلة الأوامر مع سياق النظام المكتمل
    final result = await _dispatcher.dispatchAndAnnounce(
      effectiveQuery,
      context: context,
      systemContext: systemContext,
    );

    emit(
      state.copyWith(
        status: AmbientVoiceStatus.speaking,
        spokenResponse: result.spokenResponse,
        intent: result.intent,
      ),
    );

    // إغلاق الواجهة العائمة تلقائياً بعد 4 ثوانٍ من انتهاء النطق
    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer(const Duration(seconds: 4), () {
      if (state.isOpen) closeSession();
    });
  }

  /// 3. إغلاق الجلسة فوراً وإلغاء الاستماع
  void closeSession() {
    _cancelSubscriptions();
    _autoCloseTimer?.cancel();
    _haptics.stopListeningPulse();
    _assistant.cancelListening();
    emit(const AmbientVoiceState(status: AmbientVoiceStatus.idle));
  }

  void _cancelSubscriptions() {
    _textSubscription?.cancel();
    _soundLevelSubscription?.cancel();
    _recognitionSubscription?.cancel();
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    _autoCloseTimer?.cancel();
    return super.close();
  }
}