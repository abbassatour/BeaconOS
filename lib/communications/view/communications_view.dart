// lib/communications/view/communications_view.dart
import 'package:beacon_os/communications/cubit/communications_cubit.dart';
import 'package:beacon_os/communications/cubit/communications_state.dart';
import 'package:beacon_os/communications/widgets/add_contact_dialog.dart';
import 'package:beacon_os/core/theme/app_theme.dart';
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_state.dart';
import 'package:beacon_os/spatial_compass/models/spatial_gestures.dart';
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
        commsRepository: context.read<CommsRepository>(),
        hardwareRepository: context.read<SystemHardwareRepository>(),
        assistantRepository: context.read<AssistantRepository>(), // 👈 التحديث تم هنا
      ),
      child: const CommunicationsContentView(),
    );
  }
}

class CommunicationsContentView extends StatelessWidget {
  const CommunicationsContentView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final returnHint = CompassDirection.south.returnGestureHint;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: BlocBuilder<CommunicationsCubit, CommunicationsState>(
          builder: (context, state) {
            final cubit = context.read<CommunicationsCubit>();

            if (state.status == CommunicationsStatus.loading) {
              return Center(
                child: CircularProgressIndicator(color: colors.primary),
              );
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'COMMUNICATIONS',
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Row(
                              children: [
                                // 🔄 زر المزامنة الجديد مع مؤشر دوران أثناء العمل
                                IconButton.filledTonal(
                                  style: IconButton.styleFrom(
                                    backgroundColor: colors.surface,
                                    foregroundColor: colors.onSurface,
                                    side: BorderSide(color: colors.outline),
                                  ),
                                  icon: state.isSyncingContacts
                                      ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: colors.primary,
                                          ),
                                        )
                                      : const Icon(Icons.sync_rounded),
                                  tooltip: 'Sync Device Contacts',
                                  onPressed: state.isSyncingContacts
                                      ? null
                                      : cubit.syncDeviceContacts,
                                ),
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  style: IconButton.styleFrom(
                                    backgroundColor: colors.surface,
                                    foregroundColor: colors.onSurface,
                                    side: BorderSide(color: colors.outline),
                                  ),
                                  icon: const Icon(Icons.person_add_alt_1_rounded),
                                  tooltip: 'Add Contact',
                                  onPressed: () => _showAddDialog(context, cubit),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$returnHint or double-tap to return to Cockpit.',
                          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Semantics(
                      label: 'Emergency SOS Radar. Tap to trigger distress broadcast and call primary contact.',
                      button: true,
                      child: Material(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: cubit.triggerEmergencySos,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: colors.error, width: 2),
                              color: colors.error.withValues(alpha: state.isSosBroadcasting ? 0.15 : 0.04),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: colors.error,
                                  child: Icon(state.isSosBroadcasting ? Icons.wifi_tethering_rounded : Icons.warning_amber_rounded, color: colors.surface, size: 26),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(state.isSosBroadcasting ? 'BROADCASTING SOS RADAR...' : 'EMERGENCY RADAR & SOS', style: TextStyle(color: colors.error, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                                      const SizedBox(height: 2),
                                      Text('Tap to sound alarm, stream GPS & call emergency primary.', style: TextStyle(color: colors.onSurface, fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.emergency_rounded, color: colors.error),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                if (state.emergencyContacts.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shield_rounded, color: colors.error, size: 18),
                              const SizedBox(width: 8),
                              Text('EMERGENCY CONTACTS (${state.emergencyContacts.length})', style: TextStyle(color: colors.error, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                            ],
                          ),
                          Text('Swipe left to delete', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildDismissibleEmergencyCard(context, state.emergencyContacts[index], cubit),
                        childCount: state.emergencyContacts.length,
                      ),
                    ),
                  ),
                ],

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Row(
                      children: [
                        Icon(Icons.mark_chat_unread_rounded, color: colors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text('UNREAD MESSAGES (${state.recentMessages.length})', style: TextStyle(color: colors.onSurface, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                      ],
                    ),
                  ),
                ),
                if (state.recentMessages.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.outline)),
                        child: Text('No unread messages. Your messaging vault is completely quiet.', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildMessageTile(context, state.recentMessages[index], cubit),
                        childCount: state.recentMessages.length,
                      ),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.contacts_rounded, color: colors.primary, size: 18),
                            const SizedBox(width: 8),
                            Text('PHONE DIRECTORY (${state.regularContacts.length})', style: TextStyle(color: colors.onSurface, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                          ],
                        ),
                        Text('Swipe left to delete', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                if (state.regularContacts.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.outline)),
                        child: Text('No standard contacts saved. Tap + above to add one.', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildDismissibleRegularCard(context, state.regularContacts[index], cubit),
                        childCount: state.regularContacts.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 60)),
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
        onSave: ({required name, required phoneNumber, relationship, required isEmergency}) {
          cubit.addNewContact(name: name, phoneNumber: phoneNumber, relationship: relationship, isEmergency: isEmergency);
        },
      ),
    );
  }

  Widget _buildDismissibleEmergencyCard(BuildContext context, Contact contact, CommunicationsCubit cubit) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(contact.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(color: colors.error.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
          child: Icon(Icons.delete_outline_rounded, color: colors.error),
        ),
        onDismissed: (_) => cubit.deleteContact(contact),
        child: Semantics(
          label: 'Emergency contact ${contact.name}, relationship ${contact.relationship ?? 'None'}. Tap to hear details, or tap phone icon to dial.',
          button: true,
          child: Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => cubit.readContactDetailsAloud(contact),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.error, width: 1.5)),
                child: Row(
                  children: [
                    CircleAvatar(radius: 20, backgroundColor: colors.error.withValues(alpha: 0.15), child: Icon(Icons.phone_in_talk_rounded, color: colors.error, size: 20)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(contact.name, style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w900, fontSize: 16)),
                          Text('${contact.relationship ?? 'Emergency'} • ${contact.phoneNumber}', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(icon: Icon(Icons.volume_up_rounded, color: colors.primary, size: 20), onPressed: () => cubit.readContactDetailsAloud(contact)),
                    IconButton(icon: Icon(Icons.call_rounded, color: colors.error, size: 22), onPressed: () => cubit.callContact(contact)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageTile(BuildContext context, MessagesVaultData msg, CommunicationsCubit cubit) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        label: 'Unread message from ${msg.senderName} on ${msg.platform}. Tap to listen and mark as read.',
        button: true,
        child: Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => cubit.readMessageAloud(msg),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.outline, width: 1.2)),
              child: Row(
                children: [
                  CircleAvatar(radius: 20, backgroundColor: colors.primary.withValues(alpha: 0.12), child: Icon(msg.platform == 'whatsapp' ? Icons.chat_rounded : Icons.sms_rounded, color: colors.primary, size: 20)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(msg.senderName, style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(msg.platform.toUpperCase(), style: TextStyle(color: colors.primary, fontWeight: FontWeight.w900, fontSize: 10)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(msg.messageText, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.volume_up_rounded, color: colors.primary, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDismissibleRegularCard(BuildContext context, Contact contact, CommunicationsCubit cubit) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(contact.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(color: colors.error.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
          child: Icon(Icons.delete_outline_rounded, color: colors.error),
        ),
        onDismissed: (_) => cubit.deleteContact(contact),
        child: Semantics(
          label: 'Contact ${contact.name}, ${contact.relationship ?? ''}. Tap to hear details, or call icon to dial.',
          button: true,
          child: Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => cubit.readContactDetailsAloud(contact),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.outline, width: 1.2)),
                child: Row(
                  children: [
                    CircleAvatar(radius: 18, backgroundColor: context.scaffoldBg, child: Icon(Icons.person_rounded, color: colors.onSurfaceVariant, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(contact.name, style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w800, fontSize: 15)),
                          Text(contact.relationship != null ? '${contact.relationship} • ${contact.phoneNumber}' : contact.phoneNumber, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(icon: Icon(Icons.call_rounded, color: colors.primary, size: 20), onPressed: () => cubit.callContact(contact)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}