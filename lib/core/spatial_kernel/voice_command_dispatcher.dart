// lib/core/spatial_kernel/voice_command_dispatcher.dart
import 'dart:developer';
import 'package:beacon_os/core/spatial_kernel/spatial_topology.dart';
import 'package:beacon_os/core/spatial_kernel/voice_intent_handler.dart';
import 'package:flutter/widgets.dart';
import 'package:launcher_repository/launcher_repository.dart';

/// حافلة توجيه الأوامر الصوتية الذكية (Two-Tier Pluggable Voice Intent Bus)
class VoiceCommandDispatcher {
  VoiceCommandDispatcher({
    required SpatialTopology topology,
    required AssistantRepository assistantRepository,
    GlobalKey<NavigatorState>? navigatorKey,
  })  : _topology = topology,
        _assistant = assistantRepository,
        _navigatorKey = navigatorKey;

  final SpatialTopology _topology;
  final AssistantRepository _assistant;
  final GlobalKey<NavigatorState>? _navigatorKey;

  /// تجميع كل الأوامر المسجلة عبر الموديولات وترتيبها بالأولوية التنازلية
  List<VoiceIntentHandler> get _registeredHandlers {
    final handlers = <VoiceIntentHandler>[];
    for (final module in _topology.allModules) {
      handlers.addAll(module.voiceIntents);
    }
    // الترتيب: الأولوية الأعلى (100) تُفحص أولاً لمنع التضارب
    handlers.sort((a, b) => b.priority.compareTo(a.priority));
    return handlers;
  }

  /// معالجة وتوجيه الأمر الصوتي عبر المستويين (Fast-Path ثم LLM)
  Future<LauncherCommandResult> dispatch(
    String rawQuery, {
    String? base64Image,
    BuildContext? context,
    Map<String, dynamic>? systemContext,
  }) async {
    final effectiveContext = context ?? _navigatorKey?.currentContext;
    final normalized = rawQuery.trim().toLowerCase();

    final intentContext = VoiceIntentContext(
      rawQuery: rawQuery.trim(),
      normalizedQuery: normalized,
      base64Image: base64Image,
    );

    final handlers = _registeredHandlers;

    // =========================================================================
    // ⚡ المستوى 1: المسار السريع الفوري (Tier 1: Sub-5ms Fast Path)
    // =========================================================================
    for (final handler in handlers) {
      if (handler.canHandle(intentContext)) {
        log('VoiceDispatcher: ⚡ Fast-path matched [${handler.intentId}] for query: "$rawQuery"');
        if (effectiveContext != null) {
          try {
            return await handler.execute(effectiveContext, intentContext);
          } catch (e, st) {
            log('VoiceDispatcher: Error executing fast-path [${handler.intentId}]: $e', stackTrace: st);
          }
        }
      }
    }

    // =========================================================================
    // 🧠 المستوى 2: المعالجة التوليدية بالذكاء الاصطناعي (Tier 2: Multimodal LLM)
    // =========================================================================
    log('VoiceDispatcher: 🧠 No fast-path match. Invoking Gemini 2.0 Multimodal...');
    try {
      final llmResult = await _assistant.processLlmCommand(
        userCommand: rawQuery,
        base64Image: base64Image,
        systemContext: systemContext,
      );

      final intentName = llmResult['intent'] as String? ?? 'GENERAL_CHAT';
      final spokenResponse = llmResult['spoken_response'] as String? ?? 'Done.';
      final parameters = llmResult['parameters'] is Map
          ? Map<String, dynamic>.from(llmResult['parameters'] as Map)
          : <String, dynamic>{};

      // البحث عن موديول مسجل يدعم هذا الـ Intent المستخرج من الذكاء الاصطناعي
      VoiceIntentHandler? targetHandler;
      for (final h in handlers) {
        if (h.intentId.toUpperCase() == intentName.toUpperCase()) {
          targetHandler = h;
          break;
        }
      }

      // إذا وُجد معالج معتمد لهذا الأمر، ننفذ إجراءات الحفظ/التعديل عبره
      if (targetHandler != null && effectiveContext != null) {
        log('VoiceDispatcher: LLM intent [$intentName] executing via handler.');
        final enrichedContext = VoiceIntentContext(
          rawQuery: rawQuery,
          normalizedQuery: normalized,
          base64Image: base64Image,
          llmParameters: parameters,
        );
        return await targetHandler.execute(effectiveContext, enrichedContext);
      }

      // إذا كان حديثاً عاماً أو رداً توليدياً
      return LauncherCommandResult(
        intent: intentName,
        spokenResponse: spokenResponse,
        actionPayload: parameters,
      );
    } catch (e, st) {
      log('VoiceDispatcher: LLM dispatch exception: $e', stackTrace: st);
      return const LauncherCommandResult(
        intent: 'ERROR',
        spokenResponse: "I'm sorry, I encountered a connection error. Please try again.",
      );
    }
  }
}