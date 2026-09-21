// lib/communications/cubit/communications_cubit.dart
import 'dart:async';
import 'package:beacon_os/communications/cubit/communications_state.dart';
import 'package:beacon_os/core/haptics/haptic_manager.dart';
import 'package:bloc/bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';
import 'package:local_vault_api/local_vault_api.dart';

class CommunicationsCubit extends Cubit<CommunicationsState> {
  CommunicationsCubit({
    required LauncherRepository repository,
    HapticManager? hapticManager,
  }) : _repository = repository,
       _haptics = hapticManager ?? HapticManager.instance,
       super(const CommunicationsState()) {
    _initStreams();
  }

  final LauncherRepository _repository;
  final HapticManager _haptics;
  StreamSubscription<List<Contact>>? _contactsSubscription;

  void _initStreams() {
    emit(state.copyWith(status: CommunicationsStatus.loading));

    // استماع حي لتعديلات جهات الاتصال من Drift
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

  /// الاتصال الفوري بجهة اتصال مع نطق الاسم وتأكيد اهتزازي
  Future<void> callContact(Contact contact) async {
    await _haptics.successNotification();
    await _repository.speak('Calling ${contact.name}');
    await _repository.dispatchVoiceCommand('call ${contact.phoneNumber}');
  }

  /// نطق محتوى الرسالة صوتياً للكفيف بمجرد لمسها
  Future<void> readMessageAloud(MessagesVaultData message) async {
    await _haptics.successNotification();
    final announcement =
        'Message from ${message.senderName}: ${message.messageText}';
    await _repository.speak(announcement);
  }

  /// إضافة جهة اتصال جديدة (للمرافق عبر واجهة الإدخال أو بالصوت)
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
      await _repository.speak('Contact $name added successfully.');
    } catch (e) {
      await _haptics.errorAlert();
      emit(state.copyWith(errorMessage: 'Failed to add contact.'));
    }
  }

  /// حذف جهة اتصال
  Future<void> deleteContact(int id) async {
    await _repository.deleteContact(id);
    await _haptics.successNotification();
  }

  @override
  Future<void> close() {
    _contactsSubscription?.cancel();
    return super.close();
  }
}
