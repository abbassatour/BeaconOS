// lib/communications/view/communications_view.dart
import 'package:beacon_os/communications/cubit/communications_cubit.dart';
import 'package:beacon_os/communications/cubit/communications_state.dart';
import 'package:beacon_os/communications/widgets/add_contact_dialog.dart';
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launcher_repository/launcher_repository.dart';
import 'package:local_vault_api/local_vault_api.dart';

class CommunicationsView extends StatelessWidget {
  const CommunicationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CommunicationsCubit(
        repository: context.read<LauncherRepository>(),
      ),
      child: const _CommunicationsContent(),
    );
  }
}

class _CommunicationsContent extends StatelessWidget {
  const _CommunicationsContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmPaper,
      body: SafeArea(
        child: BlocBuilder<CommunicationsCubit, CommunicationsState>(
          builder: (context, state) {
            final cubit = context.read<CommunicationsCubit>();

            if (state.status == CommunicationsStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.terracotta),
              );
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. ترويسة الغرفة التحريرية ومؤشر العودة للمركز
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'COMMUNICATIONS',
                              style: TextStyle(
                                color: AppTheme.carbonInk,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            IconButton.filledTonal(
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.softBorder,
                                foregroundColor: AppTheme.carbonInk,
                              ),
                              icon: const Icon(Icons.person_add_alt_1_rounded),
                              tooltip: 'Add Contact',
                              onPressed: () => _showAddDialog(context, cubit),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Swipe UP ⬆️ or double-tap with two fingers to return to Core.',
                          style: TextStyle(
                            color: AppTheme.mutedInk,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. قسم أرقام الطوارئ ورادار الاستغاثة (Emergency Radar)
                if (state.emergencyContacts.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield_rounded,
                            color: AppTheme.errorRed,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'EMERGENCY RADAR CONTACTS',
                            style: TextStyle(
                              color: AppTheme.errorRed,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final contact = state.emergencyContacts[index];
                          return _buildEmergencyCard(contact, cubit);
                        },
                        childCount: state.emergencyContacts.length,
                      ),
                    ),
                  ),
                ],

                // 3. قسم أرشيف الرسائل الواردة والتراسل الصامت (Messages Vault)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.mark_chat_unread_rounded,
                          color: AppTheme.terracotta,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'MESSAGING VAULT (TAP TO LISTEN)',
                          style: TextStyle(
                            color: AppTheme.carbonInk,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.recentMessages.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Text(
                        'No unread messages. Your inbox is completely quiet.',
                        style: TextStyle(
                          color: AppTheme.mutedInk,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final msg = state.recentMessages[index];
                          return _buildMessageTile(msg, cubit);
                        },
                        childCount: state.recentMessages.length,
                      ),
                    ),
                  ),

                // 4. دليل جهات الاتصال العادية (Directory)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Text(
                      'PHONE DIRECTORY',
                      style: TextStyle(
                        color: AppTheme.carbonInk,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                if (state.regularContacts.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Text(
                        'No contacts saved yet. Tap + to add.',
                        style: TextStyle(
                          color: AppTheme.mutedInk,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final contact = state.regularContacts[index];
                          return _buildRegularContactCard(contact, cubit);
                        },
                        childCount: state.regularContacts.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, CommunicationsCubit cubit) {
    showDialog<void>(
      context: context,
      builder: (_) => AddContactDialog(
        onSave:
            ({
              required name,
              required phoneNumber,
              relationship,
              required isEmergency,
            }) {
              cubit.addNewContact(
                name: name,
                phoneNumber: phoneNumber,
                relationship: relationship,
                isEmergency: isEmergency,
              );
            },
      ),
    );
  }

  Widget _buildEmergencyCard(Contact contact, CommunicationsCubit cubit) {
    return Card(
      color: AppTheme.cardSurface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.errorRed, width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFEE2E2),
          child: Icon(Icons.phone_in_talk_rounded, color: AppTheme.errorRed),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(
            color: AppTheme.carbonInk,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        subtitle: Text(
          '${contact.relationship ?? 'Emergency'} • ${contact.phoneNumber}',
          style: const TextStyle(color: AppTheme.mutedInk, fontSize: 13),
        ),
        trailing: const Icon(Icons.touch_app_rounded, color: AppTheme.errorRed),
        onTap: () => cubit.callContact(contact),
      ),
    );
  }

  Widget _buildMessageTile(MessagesVaultData msg, CommunicationsCubit cubit) {
    return Card(
      color: AppTheme.cardSurface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.softBorder, width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.warmPaper,
          child: Icon(
            msg.platform == 'whatsapp' ? Icons.chat_rounded : Icons.sms_rounded,
            color: AppTheme.terracotta,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              msg.senderName,
              style: const TextStyle(
                color: AppTheme.carbonInk,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              msg.platform.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.terracotta,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ],
        ),
        subtitle: Text(
          msg.messageText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.carbonInk, fontSize: 14),
        ),
        trailing: const Icon(
          Icons.volume_up_rounded,
          color: AppTheme.terracotta,
        ),
        onTap: () => cubit.readMessageAloud(msg),
      ),
    );
  }

  Widget _buildRegularContactCard(Contact contact, CommunicationsCubit cubit) {
    return Card(
      color: AppTheme.cardSurface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.softBorder, width: 1.2),
      ),
      child: ListTile(
        title: Text(
          contact.name,
          style: const TextStyle(
            color: AppTheme.carbonInk,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          contact.relationship != null
              ? '${contact.relationship} • ${contact.phoneNumber}'
              : contact.phoneNumber,
          style: const TextStyle(color: AppTheme.mutedInk, fontSize: 13),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.call_rounded, color: AppTheme.terracotta),
          onPressed: () => cubit.callContact(contact),
        ),
      ),
    );
  }
}
