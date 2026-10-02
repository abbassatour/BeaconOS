// lib/communications/cubit/communications_cubit.dart
import 'dart:async';
import 'package:beacon_os/communications/cubit/communications_state.dart';
import 'package:beacon_os/core/audio/sound_controller.dart';
import 'package:beacon_os/core/audio/sound_cue.dart';
import 'package:beacon_os/core/haptics/haptic_manager.dart';
import 'package:bloc/bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';
import 'package:local_vault_api/local_vault_api.dart';

class CommunicationsCubit extends Cubit<CommunicationsState> {
  CommunicationsCubit({
    required LauncherRepository repository,
    HapticManager? hapticManager,
    SoundController? soundController,
  })  : _repository = repository,
        _haptics = hapticManager ?? HapticManager.instance,
        _sound = soundController ?? SoundController.instance,
        super(const CommunicationsState()) {
    _initStreams();
  }

  final LauncherRepository _repository;
  final HapticManager _haptics;
  final SoundController _sound;
  StreamSubscription<List<Contact>>? _contactsSubscription;

  void _initStreams() {
    emit(state.copyWith(status: CommunicationsStatus.loading));

    _contactsSubscription = _repository.watchContacts().listen(
      (contactsList) async {
        final messages = await _repository.getUnreadMessages();
        emit(
          state.copyWith(
            status: CommunicationsStatus.success,
            contacts: contactsList,
            recentMessages: messages,
          ),
        );
      },
      onError: (Object error) {
        emit(
          state.copyWith(
            status: CommunicationsStatus.error,
            errorMessage: error.toString(),
          ),
        );
      },
    );
  }

  /// إجراء مكالمة هاتفية فورية
  Future<void> callContact(Contact contact) async {
    await _haptics.successNotification();
    await _sound.play(SoundCue.navCenter);
    await _repository.speak('Calling ${contact.name}');
    await _repository.dispatchVoiceCommand('call ${contact.phoneNumber}');
  }

  /// نطق تفاصيل جهة الاتصال للكفيف
  Future<void> readContactDetailsAloud(Contact contact) async {
    await _haptics.successNotification();
    final relation = contact.relationship != null
        ? 'Relationship: ${contact.relationship}.'
        : '';
    final type = contact.isEmergency ? 'Emergency SOS contact.' : 'Standard contact.';
    await _repository.speak(
      '${contact.name}. $relation $type Phone number: ${contact.phoneNumber}',
    );
  }

  /// نطق الرسالة الواردة وتمييزها كمقروءة فوراً
  Future<void> readMessageAloud(MessagesVaultData message) async {
    await _haptics.successNotification();
    await _sound.play(SoundCue.processing);

    final announcement =
        'Message on ${message.platform.toUpperCase()} from ${message.senderName}: ${message.messageText}';
    await _repository.speak(announcement);

    // تمييز الرسالة كمقروءة محلياً وسحابياً وتحديث القائمة
    await _repository.markMessagesAsRead(message.contactIdentifier);
    final unread = await _repository.getUnreadMessages();
    emit(state.copyWith(recentMessages: unread));
  }

  /// إضافة جهة اتصال جديدة
  Future<void> addNewContact({
    required String name,
    required String phoneNumber,
    String? relationship,
    bool isEmergency = false,
  }) async {
    try {
      await _repository.saveContact(
        name: name,
        phoneNumber: phoneNumber,
        relationship: relationship,
        isEmergency: isEmergency,
      );
      await _haptics.successNotification();
      await _sound.play(SoundCue.success);
      final role = isEmergency ? 'as an emergency contact' : 'to contacts';
      await _repository.speak('Contact $name added $role.');
    } catch (e) {
      await _haptics.errorAlert();
      await _sound.play(SoundCue.error);
      emit(state.copyWith(errorMessage: 'Failed to add contact: $e'));
    }
  }

  /// حذف جهة اتصال مع تأكيد صوتي
  Future<void> deleteContact(Contact contact) async {
    try {
      await _repository.deleteContact(contact.id);
      await _haptics.successNotification();
      await _sound.play(SoundCue.navCenter);
      await _repository.speak('Contact ${contact.name} deleted.');
    } catch (e) {
      await _haptics.errorAlert();
    }
  }

  /// إطلاق رادار الاستغاثة وبث الموقع لجهات الطوارئ
  Future<void> triggerEmergencySos() async {
    emit(state.copyWith(isSosBroadcasting: true));

    await _sound.play(SoundCue.sosAlarm);
    await _haptics.emergencyAlarmPulse();

    await _repository.speak(
      'Emergency SOS broadcast initiated! Broadcasting coordinates to family radar.',
    );

    // بث الإحداثيات (يمكن تزويدها بـ GPS فعلي)
    await _repository.triggerEmergencySos(
      latitude: 0.0,
      longitude: 0.0,
      batteryLevel: 100,
    );

    await Future<void>.delayed(const Duration(seconds: 4));
    emit(state.copyWith(isSosBroadcasting: false));
  }

  @override
  Future<void> close() {
    _contactsSubscription?.cancel();
    return super.close();
  }
}