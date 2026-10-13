// lib/spatial_shell/models/spatial_gestures.dart

/// الكتالوج المركزي الموحد لإيماءات النظام (Spatial Interaction Tokens)
enum SpatialGesture {
  // 🏢 1. مصعد الطوابق (Z-Axis Elevator)
  ascendToSettings(
    symbol: '👐',
    shortLabel: 'Spread apart',
    visualHint: '👐 Spread 2 fingers to enter Floor 1 (Settings)',
    spokenPrompt:
        'Elevator activated. Spreading two fingers apart ascends to the Settings floor.',
    onboardingStepLabel: 'Spread 2 fingers 👐 to dive into Settings Floor',
  ),
  descendToGround(
    symbol: '🤏',
    shortLabel: 'Pinch together',
    visualHint: '🤏 Pinch 2 fingers or double-tap HUD to return to Cockpit',
    spokenPrompt:
        'Double tap HUD or pinch two fingers together to return to your Cockpit.',
    onboardingStepLabel: 'Pinch together 🤏 or tap HUD to return to Ground Floor',
  ),

  // 🧭 2. إيماءات واستكشاف الغرف المكانية (Spatial Presence & Sonification)
  swipeToFocus(
    symbol: '⬆️',
    shortLabel: 'Focus Room',
    visualHint: 'Explore Focus & Alarms',
    spokenPrompt:
        'Focus and Alarms room. Listen to the high-pitch radar chime as you approach.',
    onboardingStepLabel: 'Explore Focus & Alarms room',
  ),
  swipeToComms(
    symbol: '⬇️',
    shortLabel: 'Comms Room',
    visualHint: 'Explore Communications & Radar',
    spokenPrompt:
        'Communications and Emergency radar room. Listen to the low-frequency radar chime as you approach.',
    onboardingStepLabel: 'Explore Communications & Emergency Radar',
  ),
  swipeToAgenda(
    symbol: '⬅️',
    shortLabel: 'Agenda Room',
    visualHint: 'Explore Agenda & Tasks',
    spokenPrompt:
        'Agenda room. Pan across to review tasks, deadlines, and voice memos.',
    onboardingStepLabel: 'Explore Agenda & Tasks',
  ),
  swipeToVision(
    symbol: '➡️',
    shortLabel: 'Vision Studio',
    visualHint: 'Explore AI Vision',
    spokenPrompt:
        'AI Vision studio. Pan across to activate your camera eyes.',
    onboardingStepLabel: 'Explore AI Vision Studio',
  ),

  // 🚨 3. إيماءات الطوارئ والتفاعل الصامت
  tripleTapSos(
    symbol: '🚨',
    shortLabel: 'Triple Tap',
    visualHint: 'Tap 3 times anywhere for Emergency SOS',
    spokenPrompt:
        'Triple tapping rapidly anywhere on screen broadcasts your emergency radar and GPS.',
    onboardingStepLabel: 'Triple tap rapidly for Emergency SOS',
  ),
  twoFingerTapContext(
    symbol: '✌️',
    shortLabel: '2-Finger Tap',
    visualHint: 'Double-tap with 2 fingers to hear location',
    spokenPrompt:
        'Double tap anywhere with two fingers to announce your current room location.',
    onboardingStepLabel: 'Double tap with 2 fingers to hear location',
  ),

  // 🎙️ 4. التفاعل الصوتي الحسي (Tactile Voice Summoning)
  holdToSpeak(
    symbol: '🎙️',
    shortLabel: 'Hold to Speak',
    visualHint: 'Press & hold anywhere to talk with Beacon AI',
    spokenPrompt:
        'Press and hold anywhere on the screen to talk, then release when finished.',
    onboardingStepLabel: 'Hold anywhere on screen to speak with Beacon AI',
  ),
  cornerSwipeAssistant(
    symbol: '📐',
    shortLabel: 'Corner Swipe',
    visualHint:
        'Swipe diagonally inward from bottom corners to summon Beacon AI',
    spokenPrompt:
        'Swipe diagonally inward from either bottom corner of your device to speak with your assistant.',
    onboardingStepLabel: 'Swipe from bottom corner for Voice Assistant',
  );

  const SpatialGesture({
    required this.symbol,
    required this.shortLabel,
    required this.visualHint,
    required this.spokenPrompt,
    required this.onboardingStepLabel,
  });

  final String symbol;
  final String shortLabel;
  final String visualHint;
  final String spokenPrompt;
  final String onboardingStepLabel;
}