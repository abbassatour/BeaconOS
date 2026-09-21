// lib/communications/cubit/communications_state.dart
import 'package:equatable/equatable.dart';
import 'package:local_vault_api/local_vault_api.dart';

enum CommunicationsStatus { initial, loading, success, error }

class CommunicationsState extends Equatable {
  const CommunicationsState({
    this.status = CommunicationsStatus.initial,
    this.contacts = const [],
    this.recentMessages = const [],
    this.errorMessage,
  });

  final CommunicationsStatus status;
  final List<Contact> contacts;
  final List<MessagesVaultData> recentMessages;
  final String? errorMessage;

  /// جهات اتصال الطوارئ فقط
  List<Contact> get emergencyContacts =>
      contacts.where((c) => c.isEmergency).toList();

  /// جهات الاتصال العادية
  List<Contact> get regularContacts =>
      contacts.where((c) => !c.isEmergency).toList();

  CommunicationsState copyWith({
    CommunicationsStatus? status,
    List<Contact>? contacts,
    List<MessagesVaultData>? recentMessages,
    String? errorMessage,
  }) {
    return CommunicationsState(
      status: status ?? this.status,
      contacts: contacts ?? this.contacts,
      recentMessages: recentMessages ?? this.recentMessages,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, contacts, recentMessages, errorMessage];
}
