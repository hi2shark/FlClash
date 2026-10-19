import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/desktop/model.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/core/method.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/local_proxies/pages/local_proxy_list_page.dart';
import 'package:fl_clash/local_proxies/services/local_proxy_store.dart';
import 'package:fl_clash/local_rules/pages/local_rule_list_page.dart';
import 'package:fl_clash/local_rules/services/local_rule_store.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/local_proxies.dart';
import 'package:fl_clash/views/local_rules.dart';
import 'package:fl_clash/views/network_test.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform {
  final String root;

  _FakePathProvider(this.root);

  @override
  Future<String?> getApplicationSupportPath() async => root;

  @override
  Future<String?> getTemporaryPath() async => path.join(root, 'temp');

  @override
  Future<String?> getApplicationCachePath() async => path.join(root, 'cache');

  @override
  Future<String?> getDownloadsPath() async => path.join(root, 'downloads');

  @override
  Future<String?> getLibraryPath() async => root;

  @override
  Future<String?> getExternalStoragePath() async => null;

  @override
  Future<List<String>?> getExternalCachePaths() async => null;

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async => null;
}

class _RecordingCoreHandler extends CoreHandlerInterface {
  @override
  Future<T?> invokeMethod<T>({
    required CoreMethod method,
    Object? arguments,
    Duration? timeout,
  }) async {
    return null;
  }

  @override
  Future<CoreLifecycleResult> start() async => _lifecycleResult;

  @override
  Future<CoreLifecycleResult> restart() async => _lifecycleResult;

  @override
  Future<CoreLifecycleResult> stop() async => _lifecycleResult;

  @override
  Future<CoreLifecycleResult> close() async => _lifecycleResult;
}

const _lifecycleResult = CoreLifecycleResult(
  revision: 0,
  outcome: CoreLifecycleOutcome.applied,
);

Widget _testApp(ProviderContainer container, Widget child) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      navigatorKey: globalState.navigatorKey,
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.delegate.supportedLocales,
      home: Builder(
        builder: (context) {
          globalState.theme = CommonTheme.of(context, 1);
          globalState.measure = Measure.of(context, 1);
          return child;
        },
      ),
    ),
  );
}

Future<void> _pumpFrames(WidgetTester tester, {int count = 10}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// The page's bar floats over its body, so its first content must start at or
/// below the bar's bottom edge instead of sliding under it.
void _expectContentBelowBar(WidgetTester tester, Finder finder) {
  final barBottom = tester.getRect(find.byType(AppBar)).bottom;
  expect(tester.getRect(finder.first).top, greaterThanOrEqualTo(barBottom));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late ProviderContainer container;

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'flclash_floating_bar_clearance_test_',
    );
    PathProviderPlatform.instance = _FakePathProvider(tempDirectory.path);
  });

  setUp(() async {
    for (final name in ['local_rules.json', 'local_proxies.json']) {
      final file = File(path.join(tempDirectory.path, name));
      if (await file.exists()) {
        await file.delete();
      }
    }
    localRuleStore.resetForTest();
    await localRuleStore.init().timeout(const Duration(seconds: 5));
    localProxyStore.resetForTest();
    await localProxyStore.init().timeout(const Duration(seconds: 5));
    container = ProviderContainer(
      overrides: [
        viewSizeProvider.overrideWithBuild((_, _) => const Size(800, 600)),
      ],
    );
    globalState.container = container;
  });

  tearDown(() {
    container.dispose();
  });

  tearDownAll(() async {
    localRuleStore.resetForTest();
    localProxyStore.resetForTest();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  testWidgets('LocalRulesView content starts below the floating bar', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(container, const LocalRulesView()));
    await _pumpFrames(tester);

    _expectContentBelowBar(tester, find.byType(CommonCard));
    expect(tester.takeException(), isNull);
  });

  testWidgets('LocalProxiesView content starts below the floating bar', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(container, const LocalProxiesView()));
    await _pumpFrames(tester);

    _expectContentBelowBar(tester, find.byType(CommonCard));
    expect(tester.takeException(), isNull);
  });

  testWidgets('NetworkTestView content starts below the floating bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        container,
        NetworkTestView(
          controller: CoreController.test(_RecordingCoreHandler()),
        ),
      ),
    );
    await _pumpFrames(tester);

    _expectContentBelowBar(tester, find.byType(ListHeader));
    expect(tester.takeException(), isNull);
  });

  testWidgets('LocalRuleListPage content starts below the floating bar', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(container, const LocalRuleListPage()));
    await _pumpFrames(tester);

    _expectContentBelowBar(tester, find.textContaining('0 rules'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('LocalProxyListPage content starts below the floating bar', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(container, const LocalProxyListPage()));
    await _pumpFrames(tester);

    _expectContentBelowBar(tester, find.byType(TextField));
    expect(tester.takeException(), isNull);
  });
}
