// packages/cloud_sync_api/lib/src/cloud_sync_client.dart
import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';

/// عميل المزامنة السحابية وبث الرادار لمنظومة BeaconOS عبر Supabase.
class CloudSyncClient {
  CloudSyncClient();

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // 🔐 1. المصادقة وإدارة الجلسة (Auth & Session Management)
  // ===========================================================================

  /// هل المستخدم مسجل دخوله حالياً؟
  User? get currentUser => _client?.auth.currentUser;

  /// هل المستخدم في وضع الحساب السحابي الموثق؟
  bool get isAuthenticated => currentUser != null;

  /// معرف المستخدم النشط أو مستخدم محلي إن كان أوفلاين
  String get activeUserId => currentUser?.id ?? 'local_guest_user';

  /// تدفق لحالة تسجيل الدخول آنياً
  Stream<AuthState>? get authStateChanges => _client?.auth.onAuthStateChange;

  /// تسجيل الدخول بالبريد وكلمة المرور
  Future<AuthResponse?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client?.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      log('CloudSyncClient: User signed in (${response?.user?.id})');
      return response;
    } catch (e, st) {
      log('CloudSyncClient: Sign in error: $e', stackTrace: st);
      rethrow;
    }
  }

  /// إنشاء حساب جديد
  Future<AuthResponse?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client?.auth.signUp(
        email: email.trim(),
        password: password,
      );
      log('CloudSyncClient: Account created (${response?.user?.id})');
      return response;
    } catch (e, st) {
      log('CloudSyncClient: Sign up error: $e', stackTrace: st);
      rethrow;
    }
  }

  /// الدخول السريع كضيف (ضروري جداً للتشغيل الفوري للمكفوفين بدون تعقيد كتابة بيانات)
  Future<AuthResponse?> signInAnonymously() async {
    try {
      final response = await _client?.auth.signInAnonymously();
      log('CloudSyncClient: Anonymous session active.');
      return response;
    } catch (e) {
      log('CloudSyncClient: Anonymous sign-in bypassed (Offline Mode): $e');
      return null;
    }
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    try {
      await _client?.auth.signOut();
      log('CloudSyncClient: Signed out successfully.');
    } catch (e) {
      log('CloudSyncClient: Sign out error: $e');
    }
  }

  // ===========================================================================
  // 📇 2. مزامنة جهات الاتصال (Contacts Cloud Sync)
  // ===========================================================================

  /// رفع أو تحديث جهة اتصال في السحابة
  Future<void> syncContact({
    required String name,
    required String phoneNumber,
    String? relationship,
    bool isEmergency = false,
  }) async {
    final client = _client;
    final userId = currentUser?.id;
    if (client == null || userId == null) return;

    try {
      await client.from('contacts').insert({
        'user_id': userId,
        'name': name.trim(),
        'phone_number': phoneNumber.trim(),
        'relationship': relationship?.trim(),
        'is_emergency': isEmergency,
      });
      log('CloudSyncClient: Contact synced to cloud: $name');
    } catch (e) {
      log('CloudSyncClient: Contact cloud sync skipped: $e');
    }
  }

  /// جلب كافة جهات الاتصال المحفوظة بالسحابة للمستخدم
  Future<List<Map<String, dynamic>>> fetchContacts() async {
    final client = _client;
    final userId = currentUser?.id;
    if (client == null || userId == null) return [];

    try {
      final response = await client
          .from('contacts')
          .select()
          .eq('user_id', userId)
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      log('CloudSyncClient: Failed to fetch contacts: $e', stackTrace: st);
      return [];
    }
  }

  /// بث لحظي لتعديلات جهات الاتصال (مفيد للمرافق عند إضافة أرقام جديدة من جهاز آخر)
  Stream<List<Map<String, dynamic>>>? streamContacts() {
    final client = _client;
    final userId = currentUser?.id;
    if (client == null || userId == null) return null;

    return client
        .from('contacts')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('name', ascending: true);
  }

  /// حذف جهة اتصال من السحابة
  Future<void> deleteContact(String contactId) async {
    final client = _client;
    final userId = currentUser?.id;
    if (client == null || userId == null) return;

    try {
      await client
          .from('contacts')
          .delete()
          .eq('id', contactId)
          .eq('user_id', userId);
      log('CloudSyncClient: Contact $contactId deleted from cloud.');
    } catch (e) {
      log('CloudSyncClient: Failed to delete contact: $e');
    }
  }

  // ===========================================================================
  // 💬 3. سجل التراسل الصامت (Messages Vault Cloud Sync)
  // ===========================================================================

  /// نسخ رسالة واردة أو صادرة إلى السحابة
  Future<void> syncMessage({
    required String contactIdentifier,
    required String senderName,
    required String messageText,
    String platform = 'sms',
    bool isOutgoing = false,
    DateTime? timestamp,
    bool isRead = false,
  }) async {
    final client = _client;
    final userId = currentUser?.id;
    if (client == null || userId == null) return;

    try {
      await client.from('messages_vault').insert({
        'user_id': userId,
        'contact_identifier': contactIdentifier.trim(),
        'sender_name': senderName.trim(),
        'message_text': messageText.trim(),
        'platform': platform.toLowerCase(),
        'is_outgoing': isOutgoing,
        'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
        'is_read': isRead,
      });
      log('CloudSyncClient: Message logged in cloud vault ($platform: $senderName)');
    } catch (e) {
      log('CloudSyncClient: Message vault sync skipped: $e');
    }
  }

  /// جلب أحدث سجل الرسائل من السحابة
  Future<List<Map<String, dynamic>>> fetchRecentMessages({int limit = 50}) async {
    final client = _client;
    final userId = currentUser?.id;
    if (client == null || userId == null) return [];

    try {
      final response = await client
          .from('messages_vault')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      log('CloudSyncClient: Failed to fetch messages: $e', stackTrace: st);
      return [];
    }
  }

  /// بث لحظي لرسائل محادثة معينة (Realtime Chat Feed)
  Stream<List<Map<String, dynamic>>>? streamMessages({String? contactIdentifier}) {
    final client = _client;
    final userId = currentUser?.id;
    if (client == null || userId == null) return null;

    var query = client
        .from('messages_vault')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId);

    return query.order('timestamp', ascending: true);
  }

  /// تمييز رسائل محادثة كمقروءة في السحابة
  Future<void> markMessagesAsReadInCloud(String contactIdentifier) async {
    final client = _client;
    final userId = currentUser?.id;
    if (client == null || userId == null) return;

    try {
      await client
          .from('messages_vault')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('contact_identifier', contactIdentifier);
      log('CloudSyncClient: Messages marked read for $contactIdentifier');
    } catch (e) {
      log('CloudSyncClient: Mark messages as read skipped: $e');
    }
  }

  // ===========================================================================
  // 🚨 4. رادار الاستغاثة والطوارئ (Emergency SOS Radar)
  // ===========================================================================

  /// بث إشارة الاستغاثة الطارئة (SOS) وإحداثيات الموقع
  Future<bool> broadcastEmergencySos({
    required double latitude,
    required double longitude,
    int? batteryLevel,
    String? userId,
  }) async {
    final client = _client;
    if (client == null) return false;

    try {
      final googleMapsUrl = 'https://maps.google.com/?q=$latitude,$longitude';
      final activeUser = userId ?? currentUser?.id ?? 'offline_user';

      await client.from('sos_alerts').insert({
        'user_id': activeUser,
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

  // ===========================================================================
  // 📝 5. المهام والمذكرات (Tasks & Memos Cloud Sync)
  // ===========================================================================

  /// نسخ الملاحظات الصوتية والمفرغة نصياً
  Future<void> backupMemo({
    required String title,
    required String content,
  }) async {
    final client = _client;
    final userId = currentUser?.id;
    if (client == null || userId == null) return;

    try {
      await client.from('voice_memos').insert({
        'user_id': userId,
        'title': title.trim(),
        'content': content.trim(),
      });
      log('CloudSyncClient: Memo backed up: $title');
    } catch (e) {
      log('CloudSyncClient: Memo backup skipped: $e');
    }
  }

  /// نسخ المهام وجدولتها احتياطياً
  Future<void> backupTask({
    required String title,
    DateTime? dueDate,
  }) async {
    final client = _client;
    final userId = currentUser?.id;
    if (client == null || userId == null) return;

    try {
      await client.from('tasks').insert({
        'user_id': userId,
        'title': title.trim(),
        'due_date': dueDate?.toIso8601String(),
        'is_completed': false,
      });
      log('CloudSyncClient: Task backed up: $title');
    } catch (e) {
      log('CloudSyncClient: Task backup skipped: $e');
    }
  }
}