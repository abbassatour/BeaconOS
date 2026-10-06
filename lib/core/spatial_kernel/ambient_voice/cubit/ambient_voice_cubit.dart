// lib/core/spatial_kernel/ambient_voice/cubit/ambient_voice_cubit.dart
import 'dart:async';
import 'dart:developer';

import 'package:beacon_os/core/audio/sound_controller.dart';
import 'package:beacon_os/core/audio/sound_cue.dart';
import 'package:beacon_os/core/haptics/haptic_manager.dart';
import 'package:beacon_os/core/spatial_kernel/ambient_voice/cubit/ambient_voice_state.dart';
import 'package:beacon_os/core/spatial_kernel/voice_command_dispatcher.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:launcher_repository/launcher_repository.dart';
import 'package:local_vault_api/local_vault_api.dart';

class AmbientVoiceCubit extends Cubit<AmbientVoiceState> {
  AmbientVoiceCubit({
    required AssistantRepository assistantRepository,
    required VoiceCommandDispatcher voiceDispatcher,
    required TaskAgendaRepository taskRepository,
    required FocusAlarmsRepository focusAlarmsRepository,
    required SettingsRepository settingsRepository,
    CommsRepository? commsRepository,
    SoundController? soundController,
    HapticManager? hapticManager,
  })  : _assistant = assistantRepository,
        _dispatcher = voiceDispatcher,
        _tasksRepo = taskRepository,
        _focusRepo = focusAlarmsRepository,
        _settingsRepo = settingsRepository,
        _commsRepo = commsRepository,
        _sound = soundController ?? SoundController.instance,
        _haptics = hapticManager ?? HapticManager.instance,
        super(const AmbientVoiceState());

  final AssistantRepository _assistant;
  final VoiceCommandDispatcher _dispatcher;
  final TaskAgendaRepository _tasksRepo;
  final FocusAlarmsRepository _focusRepo;
  final SettingsRepository _settingsRepo;
  final CommsRepository? _commsRepo;
  final SoundController _sound;
  final HapticManager _haptics;

  StreamSubscription<String>? _textSubscription;
  StreamSubscription<double>? _soundLevelSubscription;
  StreamSubscription<VoiceRecognitionEvent>? _recognitionSubscription;
  StreamSubscription<bool>? _isListeningSubscription;
  Timer? _autoCloseTimer;
  int _sessionGeneration = 0;

  /// 1. بدء جلسة المساعد الصوتي وتفعيل الميكروفون بعد انقضاء نغمة الإيقاظ
  Future<void> startSession() async {
    final currentGen = ++_sessionGeneration;
    _cancelSubscriptions();
    _autoCloseTimer?.cancel();

    // 🔇 إيقاف أي أصوات أو قراءات سابقة فوراً
    await _sound.stopAll();
    await _assistant.stopSpeaking();

    // 📱 تحديث الحالة فوراً لتظهر الواجهة العائمة ويبدأ المستخدم بالاستعداد
    emit(
      state.copyWith(
        status: AmbientVoiceStatus.listening,
        liveTranscript: '',
        soundLevel: 0.0,
        spokenResponse: '',
        intent: null,
        errorMessage: null,
      ),
    );

    // 🔔 تشغيل نغمة الاستيقاظ
    await _sound.play(SoundCue.wake);

    // ⏱️ فاصل زمني مدروس (200ms) حتى تنتهي النغمة في مكبر الصوت ولا يلتقطها الميكروفون
    await Future<void>.delayed(const Duration(milliseconds: 200));

    // 🛡️ حماية سباق التوقيت: إذا أُلغيت الجلسة أو أُغلقت أثناء انتظار النغمة
    if (_sessionGeneration != currentGen || !state.isListening) {
      return;
    }

    // 📳 بدء النبض التكتيكي اللمسي لتنبيه الكفيف بأن الهاتف ينصت الآن
    _haptics.startListeningPulse();

    // 📝 ربط تدفق الكلمات اللحظية لتحديث الواجهة فوراً
    _textSubscription = _assistant.textStream.listen((text) {
      if (state.isListening && text.isNotEmpty) {
        emit(state.copyWith(liveTranscript: text));
      }
    });

    // 🎚️ ربط مقياس شدة الصوت لتحريك موجات الرادار
    _soundLevelSubscription = _assistant.soundLevelStream.listen((level) {
      if (state.isListening) {
        emit(state.copyWith(soundLevel: level));
      }
    });

    // 🎯 الاستماع لاكتمال الجملة تلقائياً من محرك SpeechToText
    _recognitionSubscription =
        _assistant.recognitionStream.listen((event) async {
      if (event.isFinal && state.isListening) {
        await stopAndExecute(queryOverride: event.text);
      }
    });

    // 🔇 كشف توقف الميكروفون التلقائي (عند الصمت التام أو انتهاء المهلة من أندرويد)
    _isListeningSubscription =
        _assistant.isListeningStream.listen((isListening) {
      if (!isListening && state.isListening) {
        stopAndExecute();
      }
    });

    // 🎙️ فتح الميكروفون الفعلي بعد تأمين بيئة الصوت
    await _assistant.startListening();
  }

  /// 2. إيقاف الاستماع وتنفيذ الأمر الصوتي مع تزويده بسياق النظام المجمع ذاتياً
  Future<void> stopAndExecute({
    String? queryOverride,
    BuildContext? context,
  }) async {
    // 🛡️ قفل التزامن لمنع التكرار المزدوج
    if (!state.isListening || state.isProcessing) return;

    _sessionGeneration++;
    _haptics.stopListeningPulse();
    await _sound.play(SoundCue.processing);

    emit(state.copyWith(status: AmbientVoiceStatus.processing));

    final recognizedFromMic = await _assistant.stopListening();
    final effectiveQuery = queryOverride ??
        (recognizedFromMic.isNotEmpty
            ? recognizedFromMic
            : state.liveTranscript.trim());

    // ⚠️ معالجة حالة الصمت التام أو عدم التقاط أي كلمات
    if (effectiveQuery.isEmpty) {
      await _sound.play(SoundCue.error);
      await _haptics.errorAlert();
      const silenceMessage =
          "I didn't catch that. Please hold or swipe to try again.";

      emit(
        state.copyWith(
          status: AmbientVoiceStatus.error,
          errorMessage: "Didn't catch that",
          spokenResponse: silenceMessage,
        ),
      );

      await _assistant.speak(silenceMessage);

      _autoCloseTimer?.cancel();
      _autoCloseTimer = Timer(const Duration(seconds: 3), () {
        if (state.isOpen) closeSession();
      });
      return;
    }

    // ⚡️ جمع سياق النظام الحي ذاتياً من مستودعات النطاق
    final systemContext = await _fetchLiveSystemContext();

    // 🚀 إرسال الأمر لحافلة الأوامر مع سياق النظام الكامل
    final result = await _dispatcher.dispatchAndAnnounce(
      effectiveQuery,
      context: context,
      systemContext: systemContext,
    );

    final isError =
        result.intent == 'ERROR' || result.intent.endsWith('_FAILED');

    emit(
      state.copyWith(
        status: isError
            ? AmbientVoiceStatus.error
            : AmbientVoiceStatus.speaking,
        spokenResponse: result.spokenResponse,
        intent: result.intent,
        errorMessage: isError ? result.spokenResponse : null,
      ),
    );

    // ⏳ إغلاق الواجهة العائمة تلقائياً بعد 4 ثوانٍ من انتهاء النطق
    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer(const Duration(seconds: 4), () {
      if (state.isOpen) closeSession();
    });
  }

  /// 3. جمع سياق النظام الحي الكامل من الخزنة المحلية لتقديمه لـ Gemini 2.0 Flash
  Future<Map<String, dynamic>> _fetchLiveSystemContext() async {
    try {
      final tasks = await _tasksRepo.getPendingTasks();
      final alarms = await _focusRepo.watchAlarms().first;
      final settings = await _settingsRepo.getSettings();

      List<VoiceMemo> memos = const [];
      try {
        memos = await _tasksRepo.watchMemos().first;
      } catch (_) {}

      List<Contact> contacts = const [];
      if (_commsRepo != null) {
        try {
          contacts = await _commsRepo.watchContacts().first;
        } catch (_) {}
      }

      return {
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
        'memos': memos
            .map((m) => {
                  'id': m.id,
                  'title': m.title,
                  'content': m.content,
                })
            .toList(),
        'contacts': contacts
            .map((c) => {
                  'id': c.id,
                  'name': c.name,
                  'phone_number': c.phoneNumber,
                  'relationship': c.relationship,
                  'is_emergency': c.isEmergency,
                })
            .toList(),
        'settings': {
          'speech_rate': settings.speechRate,
          'haptics_enabled': settings.hapticsEnabled,
          'sound_cues_enabled': settings.soundCuesEnabled,
          'is_high_contrast': settings.isHighContrast,
          'default_priority': settings.defaultPriority,
          'auto_archive_completed': settings.autoArchiveCompleted,
          'vision_inspection_detail': settings.visionInspectionDetail,
          'preferred_currency': settings.preferredCurrency,
        },
      };
    } catch (e, st) {
      log('AmbientVoiceCubit: Exception while assembling system context: $e',
          stackTrace: st);
      return {};
    }
  }

  /// 4. إغلاق الجلسة فوراً وإلغاء الاستماع
  void closeSession() {
    _sessionGeneration++;
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
    _isListeningSubscription?.cancel();
  }

  @override
  Future<void> close() {
    _sessionGeneration++;
    _cancelSubscriptions();
    _autoCloseTimer?.cancel();
    return super.close();
  }
}