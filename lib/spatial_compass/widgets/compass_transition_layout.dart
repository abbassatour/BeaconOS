// lib/spatial_compass/widgets/compass_transition_layout.dart
import 'package:beacon_os/spatial_compass/cubit/spatial_compass_state.dart';
import 'package:flutter/material.dart';

class CompassTransitionLayout extends StatelessWidget {
  const CompassTransitionLayout({
    required this.direction,
    required this.centerChild,
    required this.northChild,
    required this.southChild,
    required this.eastChild,
    required this.westChild,
    super.key,
  });

  final CompassDirection direction;
  final Widget centerChild;
  final Widget northChild;
  final Widget southChild;
  final Widget eastChild;
  final Widget westChild;

  @override
  Widget build(BuildContext context) {
    // 🚀 إزالة AnimatedSlide بالكامل
    // محرك الفيزياء (SpringSimulation) في الشاشة الأب هو من يتولى الآن
    // تحريك الطابق بأكمله (Translation) لحظة بلحظة، مما يمنع التضارب الحركي.
    return Stack(
      children: [
        _buildRoomLayer(
          child: centerChild,
          translation: Offset.zero,
          roomDir: CompassDirection.center,
        ),
        _buildRoomLayer(
          child: northChild,
          translation: const Offset(0, -1),
          roomDir: CompassDirection.north,
        ),
        _buildRoomLayer(
          child: southChild,
          translation: const Offset(0, 1),
          roomDir: CompassDirection.south,
        ),
        _buildRoomLayer(
          child: eastChild,
          translation: const Offset(1, 0),
          roomDir: CompassDirection.east,
        ),
        _buildRoomLayer(
          child: westChild,
          translation: const Offset(-1, 0),
          roomDir: CompassDirection.west,
        ),
      ],
    );
  }

  /// ⚡️ ترشيد الرندر والفرز الفضائي (Spatial Culling & GPU Optimization)
  Widget _buildRoomLayer({
    required Widget child,
    required Offset translation,
    required CompassDirection roomDir,
  }) {
    // نحدد ما إذا كانت هذه الغرفة هي التي يقف فيها المستخدم حالياً
    final isActive = direction == roomDir;
    final isCenter = roomDir == CompassDirection.center;

    // المركز دائماً مسموح له بالمعالجة لتسهيل العودة، أما الغرف الأخرى فتُجمّد إن لم تكن نشطة
    final isProcessingAllowed = isActive || isCenter;

    return FractionalTranslation(
      translation: translation,
      // 1. عزل حدود إعادة الرسم (Repaint Boundary)
      // يمنع "تلوث الطلاء"، فإذا كان عداد المنبه يعمل في غرفة التركيز، 
      // لن يقوم فلاتر بإعادة رسم باقي الغرف أو البوصلة، مما يثبت الإطارات عند 120fps.
      child: RepaintBoundary(
        // 2. تجميد محركات الأنيميشن (TickerMode)
        // يوفر طاقة معالج الهاتف (CPU/Battery) عبر إيقاف الأنيميشن في الغرف غير المرئية.
        child: TickerMode(
          enabled: isProcessingAllowed,
          // 3. عزل قارئ الشاشة (ExcludeSemantics)
          // يمنع (TalkBack / VoiceOver) من قراءة أزرار غرف غير موجودة على الشاشة.
          child: ExcludeSemantics(
            excluding: !isActive,
            // 4. عزل التركيز (FocusScope)
            // يمنع لوحة المفاتيح من التركيز على حقل نصي موجود في غرفة أخرى.
            child: FocusScope(
              canRequestFocus: isActive,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}