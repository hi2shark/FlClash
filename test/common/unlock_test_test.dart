import 'package:fl_clash/common/unlock_test.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:test/test.dart';

void main() {
  group('unlockTestTargets catalog', () {
    test('has unique ids', () {
      final ids = unlockTestTargets.map((target) => target.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('default selected ids match the catalog', () {
      expect(
        defaultUnlockTestTargetIds,
        unlockTestTargets.map((target) => target.id).toList(),
      );
    });

    test('contains ai and media groups', () {
      final aiTargets = unlockTestTargetsOfGroup(UnlockTestGroup.ai);
      final mediaTargets = unlockTestTargetsOfGroup(UnlockTestGroup.media);
      expect(aiTargets, isNotEmpty);
      expect(mediaTargets, isNotEmpty);
      expect(
        aiTargets.every((target) => target.group == UnlockTestGroup.ai),
        true,
      );
      expect(
        mediaTargets.every((target) => target.group == UnlockTestGroup.media),
        true,
      );
      expect(aiTargets.length + mediaTargets.length, unlockTestTargets.length);
    });

    test('every target has an http(s) url', () {
      for (final target in unlockTestTargets) {
        expect(
          target.url.startsWith('https://') || target.url.startsWith('http://'),
          true,
          reason: '${target.id} url is not http(s)',
        );
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

  group('UnlockTestTarget.toItem', () {
    test('maps catalog fields to core item', () {
      const target = UnlockTestTarget(
        id: 'chatgpt',
        group: UnlockTestGroup.ai,
        name: 'ChatGPT',
        url: 'https://chat.openai.com/cdn-cgi/trace',
        regionRegex: 'loc=([A-Z]{2})',
        expectedStatus: [200],
      );
      final item = target.toItem();
      expect(item.id, 'chatgpt');
      expect(item.url, target.url);
      expect(item.regionRegex, 'loc=([A-Z]{2})');
      expect(item.expectedStatus, [200]);
      expect(item.method, null);
    });
  });
}
