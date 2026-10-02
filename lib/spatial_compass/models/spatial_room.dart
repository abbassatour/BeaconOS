// lib/spatial_compass/models/spatial_room.dart
import 'package:beacon_os/agenda/view/agenda_view.dart';
import 'package:beacon_os/cockpit_dashboard/view/cockpit_dashboard_view.dart';
import 'package:beacon_os/communications/view/communications_view.dart';
import 'package:beacon_os/focus_alarms/view/focus_alarms_view.dart';
import 'package:beacon_os/settings/rooms/settings_agenda_room.dart';
import 'package:beacon_os/settings/rooms/settings_comms_room.dart';
import 'package:beacon_os/settings/rooms/settings_core_room.dart';
import 'package:beacon_os/settings/rooms/settings_focus_room.dart';
import 'package:beacon_os/settings/rooms/settings_vision_room.dart';
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_state.dart';
import 'package:beacon_os/spatial_vision/view/spatial_vision_view.dart';
import 'package:flutter/material.dart';

/// معرّف هوية كل غرفة مستقلة في النظام
enum RoomId {
  cockpit,
  focusAlarms,
  agenda,
  communications,
  vision,
}

/// نموذج تعريف الغرفة وربط شاشاتها بالطابقين
class SpatialRoom {
  const SpatialRoom({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.settingsTitle,
    required this.icon,
    required this.groundView,
    required this.settingsView,
  });

  final RoomId id;
  final String title;
  final String shortTitle;
  final String settingsTitle;
  final IconData icon;
  final Widget groundView;
  final Widget settingsView;
}

/// مساعد هندسي للاشتقاق التلقائي للفيزياء والإيماءات
extension CompassDirectionX on CompassDirection {
  /// الإزاحة الفضائية (Spatial Offset) على شبكة الـ 2D Canvas
  Offset get translation {
    switch (this) {
      case CompassDirection.center:
        return Offset.zero;
      case CompassDirection.north:
        return const Offset(0, -1);
      case CompassDirection.south:
        return const Offset(0, 1);
      case CompassDirection.east:
        return const Offset(1, 0);
      case CompassDirection.west:
        return const Offset(-1, 0);
    }
  }

  /// إيماءة العودة الهندسية للمركز (محسوبة رياضياً بناءً على الموقع)
  String get returnGestureHint {
    switch (this) {
      case CompassDirection.north:
        return 'Swipe DOWN ⬇️ to return';
      case CompassDirection.south:
        return 'Swipe UP ⬆️ to return';
      case CompassDirection.east:
        return 'Swipe LEFT ⬅️ to return';
      case CompassDirection.west:
        return 'Swipe RIGHT ➡️ to return';
      case CompassDirection.center:
        return '';
    }
  }

  /// سهم الاتجاه من المركز
  String get arrowSymbol {
    switch (this) {
      case CompassDirection.north:
        return '⬆️';
      case CompassDirection.south:
        return '⬇️';
      case CompassDirection.east:
        return '➡️';
      case CompassDirection.west:
        return '⬅️';
      case CompassDirection.center:
        return '⏺️';
    }
  }
}

/// 🌟 مصدر الحقيقة الواحد (Single Source of Truth) للبوصلة
class CompassRegistry {
  CompassRegistry._();

  static const Map<CompassDirection, SpatialRoom> rooms = {
    CompassDirection.center: SpatialRoom(
      id: RoomId.cockpit,
      title: 'TODAY COCKPIT',
      shortTitle: 'Cockpit',
      settingsTitle: 'CORE ENGINE',
      icon: Icons.dashboard_rounded,
      groundView: CockpitDashboardView(),
      settingsView: SettingsCoreRoom(),
    ),
    // 🚀 تم وضع المنبه والمذاكرة في الشمال (الأعلى) كما اتفقنا
    CompassDirection.north: SpatialRoom(
      id: RoomId.focusAlarms,
      title: 'FOCUS & ALARMS',
      shortTitle: 'Focus',
      settingsTitle: 'FOCUS TUNING',
      icon: Icons.hourglass_top_rounded,
      groundView: FocusAlarmsView(),
      settingsView: SettingsFocusRoom(),
    ),
    // 🚀 تم وضع الأجندة في الغرب (اليسار)
    CompassDirection.west: SpatialRoom(
      id: RoomId.agenda,
      title: 'AGENDA & TASKS',
      shortTitle: 'Agenda',
      settingsTitle: 'AGENDA SETTINGS',
      icon: Icons.calendar_today_rounded,
      groundView: AgendaView(),
      settingsView: SettingsAgendaRoom(),
    ),
    CompassDirection.south: SpatialRoom(
      id: RoomId.communications,
      title: 'COMMUNICATIONS',
      shortTitle: 'Comms',
      settingsTitle: 'COMMS & SOS',
      icon: Icons.chat_bubble_outline_rounded,
      groundView: CommunicationsView(),
      settingsView: SettingsCommsRoom(),
    ),
    CompassDirection.east: SpatialRoom(
      id: RoomId.vision,
      title: 'AI VISION',
      shortTitle: 'Vision',
      settingsTitle: 'VISION ENGINE',
      icon: Icons.visibility_rounded,
      groundView: SpatialVisionView(),
      settingsView: SettingsVisionRoom(),
    ),
  };

  /// استرجاع بيانات الغرفة حسب الاتجاه
  static SpatialRoom roomAt(CompassDirection direction) => rooms[direction]!;

  /// استرجاع اتجاه الغرفة حسب معرّفها
  static CompassDirection directionOf(RoomId id) {
    return rooms.entries.firstWhere((entry) => entry.value.id == id).key;
  }
}