import 'package:fl_clash/common/unlock_test.dart';
import 'package:fl_clash/models/unlock_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog contains 36 unique services', () {
    expect(unlockTestTargets, hasLength(36));
    expect(unlockTestTargets.map((target) => target.id).toSet(), hasLength(36));
  });

  test('default selection contains all AI and global media services', () {
    expect(defaultUnlockTestTargetIds, hasLength(21));
    for (final target in unlockTestTargets) {
      final shouldBeDefault =
          target.group == UnlockTestGroup.ai ||
          target.group == UnlockTestGroup.globalMedia;
      expect(
        defaultUnlockTestTargetIds.contains(target.id),
        shouldBeDefault,
        reason: target.id,
      );
    }
  });

  test(
    'legacy default selection migrates while custom selection is preserved',
    () {
      expect(
        migrateUnlockTestTargetIds(legacyUnlockTestTargetIds),
        defaultUnlockTestTargetIds,
      );
      expect(migrateUnlockTestTargetIds(['chatgpt', 'netflix']), [
        'chatgpt',
        'netflix',
      ]);
    },
  );
}
