// lib/communications/cubit/communications_state.dart
import 'package:equatable/equatable.dart';
import 'package:local_vault_api/local_vault_api.dart';

enum CommunicationsStatus { initial, loading, success, error }

class CommunicationsState extends Equatable {
  const CommunicationsState({
    this.status = CommunicationsStatus.initial,
    this.contacts = const [],
    this.recentMessages = const [],
    this.isSosBroadcasting = false,
    this.errorMessage,
  });

  final CommunicationsStatus status;
  final List<Contact> contacts;
  final List<MessagesVaultData> recentMessages;
  final bool isSosBroadcasting;
  final String? errorMessage;

  /// جهات اتصال الطوارئ مرتبة أبجدياً
  List<Contact> get emergencyContacts {
    final list = contacts.where((c) => c.isEmergency).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  /// جهات الاتصال العادية مرتبة أبجدياً
  List<Contact> get regularContacts {
    final list = contacts.where((c) => !c.isEmergency).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  CommunicationsState copyWith({
    CommunicationsStatus? status,
    List<Contact>? contacts,
    List<MessagesVaultData>? recentMessages,
    bool? isSosBroadcasting,
    String? errorMessage,
  }) {
    return CommunicationsState(
      status: status ?? this.status,
      contacts: contacts ?? this.contacts,
      recentMessages: recentMessages ?? this.recentMessages,
      isSosBroadcasting: isSosBroadcasting ?? this.isSosBroadcasting,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        contacts,
        recentMessages,
        isSosBroadcasting,
        errorMessage,
      ];
}