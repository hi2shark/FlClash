import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/local_proxies/pages/local_proxy_list_page.dart';
import 'package:fl_clash/local_proxies/pages/local_proxy_mixin_settings_page.dart';
import 'package:fl_clash/local_proxies/services/local_proxy_store.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocalProxiesView extends ConsumerStatefulWidget {
  const LocalProxiesView({super.key});

  @override
  ConsumerState<LocalProxiesView> createState() => _LocalProxiesViewState();
}

class _LocalProxiesViewState extends ConsumerState<LocalProxiesView> {
  @override
  void initState() {
    super.initState();
    localProxyStore.init();
  }

  void _openMixinSettings(BuildContext context) {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) {
      context.showNotifier(context.appLocalizations.nullProfileDesc);
      return;
    }
    BaseNavigator.push(
      context,
      LocalProxyMixinSettingsPage(profileId: profile.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return CommonScaffold(
      title: appLocalizations.localProxies,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ValueListenableBuilder<LocalProxyProviderConfig?>(
            valueListenable: localProxyStore.configNotifier,
            builder: (_, config, child) {
              return ValueListenableBuilder<List<LocalProxy>>(
                valueListenable: localProxyStore.proxiesNotifier,
                builder: (_, proxies, child) {
                  final enabled = config?.enabled ?? false;
                  final enabledCount = proxies.where((p) => p.enabled).length;
                  final targetGroups = config?.targetGroups ?? [];
                  return Column(
                    children: [
                      CommonCard(
                        child: ListItem(
                          title: Text(appLocalizations.localProxyMixin),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                enabled
                                    ? appLocalizations.localMixinEnabled
                                    : appLocalizations.localMixinDisabled,
                              ),
                              if (enabled) ...[
                                const SizedBox(height: 4),
                                Text(
                                  appLocalizations.localMixinStatus(
                                    proxies.length,
                                    enabledCount,
                                    targetGroups.isEmpty
                                        ? appLocalizations.none
                                        : targetGroups.join('、'),
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 4),
                                Text(appLocalizations.localMixinDesc),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      CommonCard(
                        onPressed: () {
                          BaseNavigator.push(
                            context,
                            const LocalProxyListPage(),
                          );
                        },
                        child: ListItem(
                          title: Text(appLocalizations.manageLocalNodes),
                          subtitle: Text(
                            appLocalizations.localProxyCount(
                              proxies.length,
                              enabledCount,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      ),
                      const SizedBox(height: 12),
                      CommonCard(
                        onPressed: () => _openMixinSettings(context),
                        child: ListItem(
                          title: Text(appLocalizations.mixinSettings),
                          subtitle: Text(
                            enabled
                                ? appLocalizations.localMixinEnabled
                                : appLocalizations.localMixinDisabled,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
