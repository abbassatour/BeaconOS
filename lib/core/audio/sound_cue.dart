// lib/core/audio/sound_cue.dart

/// كتالوج أصوات النظام ونغمات الملاحة الفضائية الموحد (Sound Design Tokens)
enum SoundCue {
  // --- إيماءات الملاحة الفضائية (Spatial Pan) ---
  navNorth('audio/nav_north.mp3', volume: 0.5, allowFloorPitchShift: true),
  navSouth('audio/nav_south.mp3', volume: 0.5, allowFloorPitchShift: true),
  navEast('audio/nav_east.mp3', volume: 0.5, allowFloorPitchShift: true),
  navWest('audio/nav_west.mp3', volume: 0.5, allowFloorPitchShift: true),
  navCenter('audio/nav_center.mp3', volume: 0.6, allowFloorPitchShift: true),

  // --- المصعد الرأسي بين الطوابق (Vertical Z-Axis) ---
  elevatorUp('audio/elevator_up.mp3', volume: 0.8),
  elevatorDown('audio/elevator_down.mp3', volume: 0.8),

  // --- الواجهة الصفرية وحالات الاستماع (Zero-UI Cues) ---
  wake('audio/wake.mp3', volume: 0.6),
  processing('audio/processing.mp3', volume: 0.5),
  success('audio/success.mp3', volume: 0.7),
  error('audio/error.mp3', volume: 0.8),
  sosAlarm('audio/sos.mp3', volume: 1.0, isLooping: true);

  const SoundCue(
    this.path, {
    this.volume = 1.0,
    this.allowFloorPitchShift = false,
    this.isLooping = false,
  });

  /// المسار داخل مجلد assets
  final String path;

  /// مستوى الصوت الافتراضي
  final double volume;

  /// هل ترتفع نبرة الصوت في الطابق الثاني لإعطاء إحساس بالارتفاع
  final bool allowFloorPitchShift;

  /// هل يستمر الصوت بالتكرار (مثل إنذار الطوارئ)
  final bool isLooping;
}