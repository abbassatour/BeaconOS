// lib/core/spatial_kernel/voice_intent_handler.dart
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:launcher_repository/launcher_repository.dart';

/// سياق تنفيذ الأمر الصوتي متضمناً معايير الذكاء الاصطناعي ومراجع النظام
class VoiceIntentContext {
  const VoiceIntentContext({
    required this.rawQuery,
    required this.normalizedQuery,
    this.base64Image,
    this.llmParameters = const {},
  });

  /// النص الخام كما نطق به المستخدم
  final String rawQuery;

  /// النص المنظف والمحضر للمطابقة (Lowercase / Trimmed)
  final String normalizedQuery;

  /// لقطة الكاميرا إن وُجدت
  final String? base64Image;

  /// المتغيرات المستخرجة من Gemini (إن أتى الاستدعاء عبر مسار الـ LLM)
  final Map<String, dynamic> llmParameters;
}

/// عقد تسجيل الأوامر الصوتية الملحقة (Pluggable Voice Intent)
abstract class VoiceIntentHandler {
  /// المعرّف الفريد للأمر (مثل: 'SAVE_TASK', 'READ_TASKS')
  String get intentId;

  /// وزن أولوية الأمر في المسار السريع (الأعلى يُفحص أولاً لمنع التضارب)
  /// الأوامر السيادية (SOS / Flashlight) = 100+
  /// الأوامر النطاقية المحددة (Tasks / Alarms) = 50 - 99
  /// الأوامر العامة والدردشة = 0 - 10
  int get priority => 50;

  /// نمط الـ Regex للمسار السريع الفوري بدون إنترنت (Sub-5ms Fast Path)
  /// إذا تطابق هذا النمط، يُنفذ الأمر محلياً فوراً دون استدعاء LLM
  RegExp? get fastPathPattern => null;

  /// فحص هل يستطيع هذا المعالج التعامل مع الأمر صوتياً
  bool canHandle(VoiceIntentContext context) {
    if (fastPathPattern == null) return false;
    return fastPathPattern!.hasMatch(context.normalizedQuery);
  }

  /// تنفيذ الأمر وإرجاع النتيجة والنص الصوتي المنطوق
  Future<LauncherCommandResult> execute(
    BuildContext context,
    VoiceIntentContext intentContext,
  );
}