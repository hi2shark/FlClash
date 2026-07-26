import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/pages/editor.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EffectiveConfigView extends ConsumerStatefulWidget {
  const EffectiveConfigView({super.key});

  @override
  ConsumerState<EffectiveConfigView> createState() =>
      _EffectiveConfigViewState();
}

class _EffectiveConfigViewState extends ConsumerState<EffectiveConfigView> {
  final _contentNotifier = ValueNotifier<String?>(null);
  bool _initialized = false;
  int? _loadedProfileId;

  @override
  void dispose() {
    _contentNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadConfig(int profileId) async {
    _contentNotifier.value = null;
    final content = await ref
        .read(setupActionProvider.notifier)
        .getProfileWithId(profileId);
    if (mounted) {
      _contentNotifier.value = content;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final profileId = ref.watch(currentProfileIdProvider);
    if (!_initialized || profileId != _loadedProfileId) {
      _initialized = true;
      _loadedProfileId = profileId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (profileId == null) {
          _contentNotifier.value = '';
        } else {
          _loadConfig(profileId);
        }
      });
    }
    if (profileId == null) {
      return CommonScaffold(
        title: appLocalizations.effectiveConfig,
        body: NullStatus(
          label: appLocalizations.nullTip(appLocalizations.profile),
        ),
      );
    }
    final profileName = ref.watch(currentProfileProvider)?.realLabel ?? '';
    return ValueListenableBuilder<String?>(
      valueListenable: _contentNotifier,
      builder: (_, content, _) {
        return EditorPage(
          key: const Key('content'),
          title: profileName,
          content: content,
        );
      },
    );
  }
}
