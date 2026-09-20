// packages/cloud_sync_api/lib/src/cloud_sync_client.dart
import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';

class CloudSyncClient {
  CloudSyncClient();

  SupabaseClient get _client => Supabase.instance.client;

  /// إرسال إشارة استغاثة طارئة فورا لذوي المستخدم (SOS Radar)
  Future<bool> broadcastEmergencySos({
    required double latitude,
    required double longitude,
    int? batteryLevel,
    String? userId,
  }) async {
    try {
      final googleMapsUrl = 'https://maps.google.com/?q=$latitude,$longitude';

      await _client.from('sos_alerts').insert({
        'user_id': userId ?? 'anonymous_user',
        'latitude': latitude,
        'longitude': longitude,
        'battery_level': batteryLevel ?? 100,
        'status': 'active',
        'google_maps_url': googleMapsUrl,
      });

      log('CloudSyncClient: Emergency SOS broadcasted successfully.');
      return true;
    } catch (e, st) {
      log('CloudSyncClient: Failed to broadcast SOS: $e', stackTrace: st);
      return false;
    }
  }

  /// نسخ الملاحظات احتياطيا في السحابة بهدوء في الخلفية
  Future<void> backupMemo({
    required String title,
    required String content,
  }) async {
    try {
      await _client.from('voice_memos').insert({
        'title': title,
        'content': content,
      });
    } catch (e) {
      log('CloudSyncClient: Background memo backup skipped (offline): $e');
    }
  }

  /// نسخ المهام احتياطيا في السحابة
  Future<void> backupTask({
    required String title,
    DateTime? dueDate,
  }) async {
    try {
      await _client.from('tasks').insert({
        'title': title,
        'due_date': dueDate?.toIso8601String(),
        'is_completed': false,
      });
    } catch (e) {
      log('CloudSyncClient: Background task backup skipped (offline): $e');
    }
  }
}