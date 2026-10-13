// test/spatial_shell/cubit/spatial_shell_cubit_test.dart
import 'dart:async';

import 'package:beacon_os/core/topology/topology.dart';
import 'package:beacon_os/spatial_shell/cubit/spatial_shell_cubit.dart';
import 'package:beacon_os/spatial_shell/cubit/spatial_shell_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:launcher_repository/launcher_repository.dart';
import 'package:local_vault_api/local_vault_api.dart';
import 'package:mocktail/mocktail.dart';

class MockAssistantRepository extends Mock implements AssistantRepository {}
class MockTopologyRepository extends Mock implements TopologyRepository {}

void main() {
  late MockAssistantRepository mockAssistant;
  late MockTopologyRepository mockTopologyRepo;
  late SpatialTopology topology;
  late StreamController<List<SpatialNode>> nodesStreamController;

  setUp(() {
    mockAssistant = MockAssistantRepository();
    mockTopologyRepo = MockTopologyRepository();
    topology = SpatialTopology.defaultTopology();
    nodesStreamController = StreamController<List<SpatialNode>>.broadcast();

    when(() => mockTopologyRepo.watchNodes()).thenAnswer((_) => nodesStreamController.stream);
    when(() => mockAssistant.stopSpeaking()).thenAnswer((_) async {});
    when(() => mockAssistant.speak(any())).thenAnswer((_) async {});
  });

  tearDown(() {
    nodesStreamController.close();
    topology.dispose();
  });

  group('SpatialShellCubit Black-Screen Defense & Tracking Tests', () {
    test('Initial state tracks Cockpit at origin safely', () {
      final cubit = SpatialShellCubit(
        assistantRepository: mockAssistant,
        topology: topology,
        topologyRepository: mockTopologyRepo,
      );

      expect(cubit.state.currentCoordinate, equals(SpatialCoordinate.origin));
      expect(cubit.state.activeModuleId, equals('cockpit'));
      expect(cubit.state.isGroundFloor, isTrue);

      cubit.close();
    });

    blocTest<SpatialShellCubit, SpatialShellState>(
      'Automatically tracks active room to new coordinates when moved externally (No Black Screen)',
      build: () => SpatialShellCubit(
        assistantRepository: mockAssistant,
        topology: topology,
        topologyRepository: mockTopologyRepo,
      ),
      act: (cubit) {
        // محاكاة تحريك غرفة قمرة القيادة من سطح المكتب إلى (1, 1)
        final movedNodes = [
          const SpatialNode(
            id: 'cockpit_f0',
            moduleId: 'cockpit',
            floorLevel: 0,
            x: 1,
            y: 1, // الموقع الجديد
            createdAt: null,
            updatedAt: null,
            isSynced: true,
          ),
          const SpatialNode(
            id: 'focus_f0',
            moduleId: 'focus',
            floorLevel: 0,
            x: 0,
            y: 1,
            createdAt: null,
            updatedAt: null,
            isSynced: true,
          ),
        ];

        // ضخ التحديث عبر قنوات الخزنة
        nodesStreamController.add(movedNodes);
      },
      expect: () => [
        // التأكد من أن الكيوبيت أصدر حالة جديدة ملاحقاً قمرة القيادة إلى (1, 1) فوراً
        predicate<SpatialShellState>((state) {
          return state.currentCoordinate == const SpatialCoordinate(x: 1, y: 1, floor: 0) &&
              state.activeModuleId == 'cockpit';
        }),
      ],
    );

    blocTest<SpatialShellCubit, SpatialShellState>(
      'Gravitates safely to origin when current room is emptied',
      build: () => SpatialShellCubit(
        assistantRepository: mockAssistant,
        topology: topology,
        topologyRepository: mockTopologyRepo,
      ),
      seed: () => const SpatialShellState(
        currentCoordinate: SpatialCoordinate(x: -1, y: 0, floor: 0),
        activeModuleId: 'agenda',
      ),
      act: (cubit) {
        // حذف غرفة الأجندة بحيث يصبح مكانها (-1, 0) فارغاً تماماً
        final nodesWithoutAgenda = [
          const SpatialNode(
            id: 'cockpit_f0',
            moduleId: 'cockpit',
            floorLevel: 0,
            x: 0,
            y: 0,
            createdAt: null,
            updatedAt: null,
            isSynced: true,
          ),
        ];

        nodesStreamController.add(nodesWithoutAgenda);
      },
      expect: () => [
        // التأكد من الانجذاب الآمن للمركز بدلاً من البقاء في فراغ أسود
        predicate<SpatialShellState>((state) {
          return state.currentCoordinate == SpatialCoordinate.origin &&
              state.activeModuleId == 'cockpit';
        }),
      ],
    );
  });
}