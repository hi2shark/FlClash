import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';

Future<bool> applyLocalRuleChanges() async {
  final profile = globalState.container.read(currentProfileProvider);
  if (profile == null) return true;
  return globalState.container
      .read(setupActionProvider.notifier)
      .applyProfile(force: true);
}
