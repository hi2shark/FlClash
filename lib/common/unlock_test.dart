import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';

/// Concurrency used by the core unlock test runner.
const unlockTestConcurrency = 4;

/// Default proxy name used by the dashboard unlock detection card.
const unlockTestGlobalProxyName = 'GLOBAL';

class UnlockTestTarget {
  final String id;
  final UnlockTestGroup group;
  final String name;
  final String url;
  final String? regionRegex;
  final List<int>? expectedStatus;

  const UnlockTestTarget({
    required this.id,
    required this.group,
    required this.name,
    required this.url,
    this.regionRegex,
    this.expectedStatus,
  });

  UnlockTestItem toItem() => UnlockTestItem(
    id: id,
    url: url,
    regionRegex: regionRegex,
    expectedStatus: expectedStatus,
  );
}

const unlockTestTargets = <UnlockTestTarget>[
  UnlockTestTarget(
    id: 'chatgpt',
    group: UnlockTestGroup.ai,
    name: 'ChatGPT',
    url: 'https://chat.openai.com/cdn-cgi/trace',
    regionRegex: 'loc=([A-Z]{2})',
  ),
  UnlockTestTarget(
    id: 'claude',
    group: UnlockTestGroup.ai,
    name: 'Claude',
    url: 'https://claude.ai/',
  ),
  UnlockTestTarget(
    id: 'gemini',
    group: UnlockTestGroup.ai,
    name: 'Gemini',
    url: 'https://gemini.google.com/',
  ),
  UnlockTestTarget(
    id: 'copilot',
    group: UnlockTestGroup.ai,
    name: 'Copilot',
    url: 'https://copilot.microsoft.com/',
  ),
  UnlockTestTarget(
    id: 'youtube',
    group: UnlockTestGroup.media,
    name: 'YouTube',
    url: 'https://www.youtube.com/',
  ),
  UnlockTestTarget(
    id: 'netflix',
    group: UnlockTestGroup.media,
    name: 'Netflix',
    url: 'https://www.netflix.com/title/80018499',
  ),
  UnlockTestTarget(
    id: 'disney_plus',
    group: UnlockTestGroup.media,
    name: 'Disney+',
    url: 'https://www.disneyplus.com/',
  ),
  UnlockTestTarget(
    id: 'tiktok',
    group: UnlockTestGroup.media,
    name: 'TikTok',
    url: 'https://www.tiktok.com/',
  ),
];

const defaultUnlockTestTargetIds = <String>[
  'chatgpt',
  'claude',
  'gemini',
  'copilot',
  'youtube',
  'netflix',
  'disney_plus',
  'tiktok',
];

List<UnlockTestTarget> unlockTestTargetsOfGroup(UnlockTestGroup group) =>
    unlockTestTargets.where((target) => target.group == group).toList();

List<UnlockTestTarget> resolveUnlockTestTargets(List<String> selectedIds) =>
    unlockTestTargets
        .where((target) => selectedIds.contains(target.id))
        .toList();
