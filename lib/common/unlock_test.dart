import 'package:fl_clash/models/unlock_test.dart';

const unlockTestCatalogVersion = 2;
const unlockTestConcurrency = 4;
const unlockTestTimeout = 10000;

class UnlockTestTarget {
  final String id;
  final UnlockTestGroup group;
  final String name;
  final String monogram;

  const UnlockTestTarget({
    required this.id,
    required this.group,
    required this.name,
    required this.monogram,
  });
}

const unlockTestTargets = <UnlockTestTarget>[
  UnlockTestTarget(
    id: 'chatgpt',
    group: UnlockTestGroup.ai,
    name: 'ChatGPT',
    monogram: 'C',
  ),
  UnlockTestTarget(
    id: 'claude',
    group: UnlockTestGroup.ai,
    name: 'Claude',
    monogram: 'CL',
  ),
  UnlockTestTarget(
    id: 'gemini',
    group: UnlockTestGroup.ai,
    name: 'Gemini',
    monogram: 'G',
  ),
  UnlockTestTarget(
    id: 'copilot',
    group: UnlockTestGroup.ai,
    name: 'Microsoft Copilot',
    monogram: 'CO',
  ),
  UnlockTestTarget(
    id: 'perplexity',
    group: UnlockTestGroup.ai,
    name: 'Perplexity',
    monogram: 'P',
  ),
  UnlockTestTarget(
    id: 'grok',
    group: UnlockTestGroup.ai,
    name: 'Grok',
    monogram: 'G',
  ),
  UnlockTestTarget(
    id: 'meta-ai',
    group: UnlockTestGroup.ai,
    name: 'Meta AI',
    monogram: 'M',
  ),
  UnlockTestTarget(
    id: 'sora',
    group: UnlockTestGroup.ai,
    name: 'Sora',
    monogram: 'S',
  ),
  UnlockTestTarget(
    id: 'deepseek',
    group: UnlockTestGroup.ai,
    name: 'DeepSeek',
    monogram: 'D',
  ),
  UnlockTestTarget(
    id: 'netflix',
    group: UnlockTestGroup.globalMedia,
    name: 'Netflix',
    monogram: 'N',
  ),
  UnlockTestTarget(
    id: 'disney-plus',
    group: UnlockTestGroup.globalMedia,
    name: 'Disney+',
    monogram: 'D+',
  ),
  UnlockTestTarget(
    id: 'youtube-premium',
    group: UnlockTestGroup.globalMedia,
    name: 'YouTube Premium',
    monogram: 'YT',
  ),
  UnlockTestTarget(
    id: 'prime-video',
    group: UnlockTestGroup.globalMedia,
    name: 'Prime Video',
    monogram: 'PV',
  ),
  UnlockTestTarget(
    id: 'max',
    group: UnlockTestGroup.globalMedia,
    name: 'Max',
    monogram: 'M',
  ),
  UnlockTestTarget(
    id: 'hulu',
    group: UnlockTestGroup.globalMedia,
    name: 'Hulu',
    monogram: 'H',
  ),
  UnlockTestTarget(
    id: 'paramount-plus',
    group: UnlockTestGroup.globalMedia,
    name: 'Paramount+',
    monogram: 'P+',
  ),
  UnlockTestTarget(
    id: 'peacock',
    group: UnlockTestGroup.globalMedia,
    name: 'Peacock',
    monogram: 'P',
  ),
  UnlockTestTarget(
    id: 'spotify',
    group: UnlockTestGroup.globalMedia,
    name: 'Spotify',
    monogram: 'S',
  ),
  UnlockTestTarget(
    id: 'tiktok',
    group: UnlockTestGroup.globalMedia,
    name: 'TikTok',
    monogram: 'T',
  ),
  UnlockTestTarget(
    id: 'dazn',
    group: UnlockTestGroup.globalMedia,
    name: 'DAZN',
    monogram: 'DZ',
  ),
  UnlockTestTarget(
    id: 'crunchyroll',
    group: UnlockTestGroup.globalMedia,
    name: 'Crunchyroll',
    monogram: 'CR',
  ),
  UnlockTestTarget(
    id: 'bbc-iplayer',
    group: UnlockTestGroup.europe,
    name: 'BBC iPlayer',
    monogram: 'BBC',
  ),
  UnlockTestTarget(
    id: 'itvx',
    group: UnlockTestGroup.europe,
    name: 'ITVX',
    monogram: 'ITV',
  ),
  UnlockTestTarget(
    id: 'channel-4',
    group: UnlockTestGroup.europe,
    name: 'Channel 4',
    monogram: 'C4',
  ),
  UnlockTestTarget(
    id: 'bilibili-hk-mo',
    group: UnlockTestGroup.hongKongTaiwan,
    name: 'Bilibili 港澳',
    monogram: 'B',
  ),
  UnlockTestTarget(
    id: 'bilibili-tw',
    group: UnlockTestGroup.hongKongTaiwan,
    name: 'Bilibili 台湾',
    monogram: 'B',
  ),
  UnlockTestTarget(
    id: 'bahamut-anime',
    group: UnlockTestGroup.hongKongTaiwan,
    name: '巴哈姆特动画疯',
    monogram: '巴',
  ),
  UnlockTestTarget(
    id: 'mytv-super',
    group: UnlockTestGroup.hongKongTaiwan,
    name: 'myTV SUPER',
    monogram: 'TV',
  ),
  UnlockTestTarget(
    id: 'viutv',
    group: UnlockTestGroup.hongKongTaiwan,
    name: 'ViuTV',
    monogram: 'V',
  ),
  UnlockTestTarget(
    id: 'abema',
    group: UnlockTestGroup.japan,
    name: 'ABEMA',
    monogram: 'A',
  ),
  UnlockTestTarget(
    id: 'dmm-tv',
    group: UnlockTestGroup.japan,
    name: 'DMM TV',
    monogram: 'D',
  ),
  UnlockTestTarget(
    id: 'u-next',
    group: UnlockTestGroup.japan,
    name: 'U-NEXT',
    monogram: 'U',
  ),
  UnlockTestTarget(
    id: 'tver',
    group: UnlockTestGroup.japan,
    name: 'TVer',
    monogram: 'T',
  ),
  UnlockTestTarget(
    id: 'nhk-plus',
    group: UnlockTestGroup.japan,
    name: 'NHK+',
    monogram: 'N+',
  ),
  UnlockTestTarget(
    id: 'kocowa',
    group: UnlockTestGroup.korea,
    name: 'KOCOWA',
    monogram: 'K',
  ),
  UnlockTestTarget(
    id: 'watcha',
    group: UnlockTestGroup.korea,
    name: 'Watcha',
    monogram: 'W',
  ),
];

const defaultUnlockTestTargetIds = <String>[
  'chatgpt',
  'claude',
  'gemini',
  'copilot',
  'perplexity',
  'grok',
  'meta-ai',
  'sora',
  'deepseek',
  'netflix',
  'disney-plus',
  'youtube-premium',
  'prime-video',
  'max',
  'hulu',
  'paramount-plus',
  'peacock',
  'spotify',
  'tiktok',
  'dazn',
  'crunchyroll',
];

const legacyUnlockTestTargetIds = <String>[
  'chatgpt',
  'claude',
  'gemini',
  'copilot',
  'youtube',
  'netflix',
  'disney_plus',
  'tiktok',
];

const _legacyTargetAliases = <String, String>{
  'youtube': 'youtube-premium',
  'disney_plus': 'disney-plus',
};

List<String> migrateUnlockTestTargetIds(Iterable<String> selectedIds) {
  final selected = selectedIds.toList(growable: false);
  if (selected.toSet().length == legacyUnlockTestTargetIds.length &&
      selected.toSet().containsAll(legacyUnlockTestTargetIds)) {
    return defaultUnlockTestTargetIds;
  }

  final knownIds = unlockTestTargets.map((target) => target.id).toSet();
  final migrated = <String>[];
  for (final id in selected) {
    final resolved = _legacyTargetAliases[id] ?? id;
    if (knownIds.contains(resolved) && !migrated.contains(resolved)) {
      migrated.add(resolved);
    }
  }
  return migrated;
}

List<UnlockTestTarget> unlockTestTargetsOfGroup(UnlockTestGroup group) =>
    unlockTestTargets.where((target) => target.group == group).toList();

List<UnlockTestTarget> resolveUnlockTestTargets(List<String> selectedIds) {
  final selected = migrateUnlockTestTargetIds(selectedIds).toSet();
  return unlockTestTargets
      .where((target) => selected.contains(target.id))
      .toList();
}

UnlockTestTarget? unlockTestTargetOf(String id) {
  for (final target in unlockTestTargets) {
    if (target.id == id) {
      return target;
    }
  }
  return null;
}
