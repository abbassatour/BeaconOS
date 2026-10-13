// test/core/topology/spatial_topology_test.dart
import 'package:beacon_os/core/topology/topology.dart';
import 'package:beacon_os/spatial_shell/spatial_shell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpatialCoordinate Relative Bearing Tests (5x5 Grid)', () {
    test('Origin (0, 0) maps to center', () {
      const origin = SpatialCoordinate(x: 0, y: 0);
      expect(origin.toCompassDirection(), equals(SpatialDirection.center));
      expect(origin.isOrigin, isTrue);
    });

    test('Standard cardinal unit cross maps correctly', () {
      expect(const SpatialCoordinate(x: 0, y: 1).toCompassDirection(), equals(SpatialDirection.north));
      expect(const SpatialCoordinate(x: 0, y: -1).toCompassDirection(), equals(SpatialDirection.south));
      expect(const SpatialCoordinate(x: 1, y: 0).toCompassDirection(), equals(SpatialDirection.east));
      expect(const SpatialCoordinate(x: -1, y: 0).toCompassDirection(), equals(SpatialDirection.west));
    });

    test('Distant coordinates in 5x5 grid map to dominant cardinal direction without returning null', () {
      // الغرف المنقولة لمسافات أبعد في مصفوفة سطح المكتب
      expect(const SpatialCoordinate(x: 2, y: 0).toCompassDirection(), equals(SpatialDirection.east));
      expect(const SpatialCoordinate(x: -2, y: 0).toCompassDirection(), equals(SpatialDirection.west));
      expect(const SpatialCoordinate(x: 0, y: 2).toCompassDirection(), equals(SpatialDirection.north));
      expect(const SpatialCoordinate(x: 0, y: -2).toCompassDirection(), equals(SpatialDirection.south));
    });

    test('Diagonal positions calculate relative quadrant bearing correctly', () {
      // عند التواجد في إحداثيات قطبية
      expect(const SpatialCoordinate(x: 1, y: 2).toCompassDirection(), equals(SpatialDirection.north));
      expect(const SpatialCoordinate(x: 2, y: 1).toCompassDirection(), equals(SpatialDirection.east));
      expect(const SpatialCoordinate(x: -2, y: 1).toCompassDirection(), equals(SpatialDirection.west));
      expect(const SpatialCoordinate(x: 1, y: -2).toCompassDirection(), equals(SpatialDirection.south));
    });
  });

  group('SpatialTopology Reactivity & Node Reconciliation', () {
    late SpatialTopology topology;

    setUp(() {
      topology = SpatialTopology.defaultTopology();
    });

    tearDown(() {
      topology.dispose();
    });

    test('Default topology registers 5 core modules across floors 0 and 1', () {
      final floor0Nodes = topology.nodesOnFloor(0);
      expect(floor0Nodes.length, equals(5));
      expect(topology.coordinateOf(0, 'cockpit'), equals(const SpatialCoordinate(x: 0, y: 0, floor: 0)));
      expect(topology.coordinateOf(0, 'focus'), equals(const SpatialCoordinate(x: 0, y: 1, floor: 0)));
    });

    test('updateFromNodes fires changes stream and clears ghost coordinates', () async {
      var eventFired = false;
      final sub = topology.changes.listen((_) {
        eventFired = true;
      });

      // محاكاة تحريك قمرة القيادة من (0, 0) إلى (2, 0) في الطابق 0
      final updatedRawNodes = [
        {'id': 'cockpit_f0', 'module_id': 'cockpit', 'floor_level': 0, 'x': 2, 'y': 0},
        {'id': 'focus_f0', 'module_id': 'focus', 'floor_level': 0, 'x': 0, 'y': 1},
      ];

      topology.updateFromNodes(updatedRawNodes);

      // انتظار دورة الحدث
      await Future<void>.delayed(Duration.zero);

      expect(eventFired, isTrue);
      // التأكد من أن الإحداثي القديم (0, 0) لم يعد يحتوي على قمرة القيادة
      expect(topology.moduleAtCoordinate(const SpatialCoordinate(x: 0, y: 0, floor: 0)), isNull);
      // التأكد من الإحداثي الجديد
      expect(topology.coordinateOf(0, 'cockpit'), equals(const SpatialCoordinate(x: 2, y: 0, floor: 0)));

      await sub.cancel();
    });
  });
}