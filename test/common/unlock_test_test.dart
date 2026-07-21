import 'package:fl_clash/common/unlock_test.dart';
import 'package:fl_clash/models/unlock_test.dart';
import 'package:test/test.dart';

void main() {
  group('unlockTestTargets catalog', () {
    test('has unique ids', () {
      final ids = unlockTestTargets.map((target) => target.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('default selected ids are AI and global media', () {
      expect(
        defaultUnlockTestTargetIds,
        unlockTestTargets
            .where(
              (target) =>
                  target.group == UnlockTestGroup.ai ||
                  target.group == UnlockTestGroup.globalMedia,
            )
            .map((target) => target.id)
            .toList(),
      );
    });

    test('contains all regional groups', () {
      for (final group in UnlockTestGroup.values) {
        final targets = unlockTestTargetsOfGroup(group);
        expect(targets, isNotEmpty, reason: group.name);
        expect(targets.every((target) => target.group == group), true);
      }
    });
  });

  group('resolveUnlockTestTargets', () {
    test('returns selected targets in catalog order', () {
      final targets = resolveUnlockTestTargets(['netflix', 'chatgpt']);
      expect(targets.map((target) => target.id), ['chatgpt', 'netflix']);
    });

    test('ignores unknown ids', () {
      final targets = resolveUnlockTestTargets(['unknown', 'chatgpt']);
      expect(targets.map((target) => target.id), ['chatgpt']);
    });

    test('returns empty list for empty selection', () {
      expect(resolveUnlockTestTargets([]), isEmpty);
    });
  });
}
