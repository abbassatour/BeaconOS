// lib/spatial_compass/widgets/floor_layouts.dart
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_state.dart';
import 'package:beacon_os/spatial_compass/widgets/compass_transition_layout.dart';
import 'package:flutter/material.dart';

// غرف الطابق الأرضي
import 'package:beacon_os/cockpit_dashboard/view/cockpit_dashboard_view.dart';
import 'package:beacon_os/agenda/view/agenda_view.dart';
import 'package:beacon_os/communications/view/communications_view.dart';
import 'package:beacon_os/focus_alarms/view/focus_alarms_view.dart';
import 'package:beacon_os/spatial_vision/view/spatial_vision_view.dart';

// غرف طابق الإعدادات
import 'package:beacon_os/settings/rooms/settings_core_room.dart';
import 'package:beacon_os/settings/rooms/settings_agenda_room.dart';
import 'package:beacon_os/settings/rooms/settings_comms_room.dart';
import 'package:beacon_os/settings/rooms/settings_focus_room.dart';
import 'package:beacon_os/settings/rooms/settings_vision_room.dart';

/// تصميم شاشات الطابق الأرضي الأساسية (المهام، التواصل، الرؤية، الخ)
class CoreFloorLayout extends StatelessWidget {
  const CoreFloorLayout({required this.direction, super.key});
  final CompassDirection direction;

  @override
  Widget build(BuildContext context) {
    return CompassTransitionLayout(
      direction: direction,
      centerChild: const CockpitDashboardView(),
      northChild: const AgendaView(),
      southChild: const CommunicationsView(),
      westChild: const FocusAlarmsView(),
      eastChild: const SpatialVisionView(),
    );
  }
}

/// تصميم شاشات الطابق الثاني الخاصة بالإعدادات
class SettingsFloorLayout extends StatelessWidget {
  const SettingsFloorLayout({required this.direction, super.key});
  final CompassDirection direction;

  @override
  Widget build(BuildContext context) {
    return CompassTransitionLayout(
      direction: direction,
      centerChild: const SettingsCoreRoom(),
      northChild: const SettingsAgendaRoom(),
      southChild: const SettingsCommsRoom(),
      westChild: const SettingsFocusRoom(),
      eastChild: const SettingsVisionRoom(),
    );
  }
}