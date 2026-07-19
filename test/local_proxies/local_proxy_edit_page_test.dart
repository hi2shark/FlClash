import 'dart:async';
import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/local_proxies/pages/local_proxy_edit_page.dart';
import 'package:fl_clash/local_proxies/services/local_proxy_store.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/local_proxy.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
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

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.delegate.supportedLocales,
    home: Builder(
      builder: (context) {
        globalState.theme = CommonTheme.of(context, 1.0);
        return Navigator(
          onGenerateInitialRoutes: (_, _) => [
            MaterialPageRoute(builder: (_) => const SizedBox.shrink()),
            MaterialPageRoute(builder: (_) => child),
          ],
        );
      },
    ),
  );
}

LocalProxy _proxy({
  required int id,
  required String name,
  required String type,
  required Map<String, dynamic> config,
  bool enabled = true,
  List<String> tags = const [],
  int? sortIndex,
  DateTime? createdAt,
}) {
  final created = createdAt ?? DateTime.utc(2026, 1, 2);
  return LocalProxy(
    id: id,
    name: name,
    type: type,
    enabled: enabled,
    config: config,
    tags: tags,
    sortIndex: sortIndex,
    createdAt: created,
    updatedAt: created,
  );
}

Finder _field(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );
}

TextEditingController _fieldController(WidgetTester tester, String label) {
  return tester.widget<TextField>(_field(label)).controller!;
}

Future<void> _enterField(
  WidgetTester tester,
  String label,
  String value,
) async {
  final finder = _field(label);
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
}

Future<void> _pumpFrames(WidgetTester tester, {int count = 10}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _tapSave(
  WidgetTester tester, {
  bool expectStoreChange = true,
}) async {
  final dynamic onPressed = tester
      .widget<FloatingActionButton>(find.byType(FloatingActionButton))
      .onPressed!;
  await tester.runAsync(() async {
    final result = onPressed();
    if (result is! Future) {
      if (expectStoreChange) {
        fail('The save callback must expose its asynchronous result.');
      }
      return;
    }
    await result.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException(
        'Saving the local proxy did not complete within 10 seconds.',
      ),
    );
  });
  await _pumpFrames(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDirectory;
  late PathProviderPlatform originalPathProvider;

  setUpAll(() async {
    originalPathProvider = PathProviderPlatform.instance;
    tempDirectory = await Directory.systemTemp.createTemp(
      'flclash_local_proxy_edit_test_',
    );
    PathProviderPlatform.instance = _FakePathProvider(tempDirectory.path);
    expect(
      await appPath.homeDirPath.timeout(const Duration(seconds: 10)),
      tempDirectory.path,
    );
  });

  setUp(() async {
    final storeFile = File(path.join(tempDirectory.path, 'local_proxies.json'));
    if (await storeFile.exists()) {
      await storeFile.delete();
    }
    localProxyStore.resetForTest();
    await localProxyStore.init().timeout(const Duration(seconds: 10));
  });

  tearDown(() {
    localProxyStore.resetForTest();
  });

  tearDownAll(() async {
    try {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    } finally {
      PathProviderPlatform.instance = originalPathProvider;
    }
  });

  testWidgets('initializes SOCKS5 fields and saves kebab-case config', (
    tester,
  ) async {
    final original = _proxy(
      id: 11,
      name: 'Existing SOCKS5',
      type: 'socks5',
      enabled: false,
      tags: ['manual'],
      sortIndex: 7,
      config: {
        'name': 'Existing SOCKS5',
        'type': 'socks5',
        'server': 'socks.example.com',
        'port': 1080,
        'username': 'alice',
        'password': 'secret',
        'tls': true,
        'udp': false,
        'skip-cert-verify': true,
        'fingerprint': 'chrome',
        'certificate': 'CERTIFICATE',
        'private-key': 'PRIVATE KEY',
        'tfo': true,
        'mptcp': true,
        'interface-name': 'eth0',
        'routing-mark': 123,
        'ip-version': 'ipv4',
        'dialer-proxy': 'CHAIN',
      },
    );
    await tester.runAsync(() => localProxyStore.add(original));
    final storedBeforeEdit = localProxyStore.proxies.single;

    await tester.pumpWidget(_wrap(LocalProxyEditPage(proxy: storedBeforeEdit)));
    await _pumpFrames(tester);

    expect(tester.takeException(), isNull);
    expect(_fieldController(tester, 'Username').text, 'alice');
    expect(_fieldController(tester, 'Password').text, 'secret');
    expect(_fieldController(tester, 'Fingerprint').text, 'chrome');
    expect(_fieldController(tester, 'Certificate').text, 'CERTIFICATE');
    expect(_fieldController(tester, 'Private key').text, 'PRIVATE KEY');

    await _tapSave(tester);

    expect(localProxyStore.proxies, hasLength(1));
    final saved = localProxyStore.proxies.single;
    expect(saved.id, original.id);
    expect(saved.enabled, isFalse);
    expect(saved.tags, ['manual']);
    expect(saved.sortIndex, storedBeforeEdit.sortIndex);
    expect(saved.config, {
      'name': 'Existing SOCKS5',
      'type': 'socks5',
      'server': 'socks.example.com',
      'port': 1080,
      'udp': false,
      'username': 'alice',
      'password': 'secret',
      'tls': true,
      'skip-cert-verify': true,
      'fingerprint': 'chrome',
      'certificate': 'CERTIFICATE',
      'private-key': 'PRIVATE KEY',
      'tfo': true,
      'mptcp': true,
      'interface-name': 'eth0',
      'routing-mark': 123,
      'ip-version': 'ipv4',
      'dialer-proxy': 'CHAIN',
    });
    expect(saved.config.containsKey('skipCertVerify'), isFalse);
    expect(saved.config.containsKey('privateKey'), isFalse);
  });

  testWidgets('clears SOCKS5 TLS fields when TLS is disabled', (tester) async {
    final original = _proxy(
      id: 15,
      name: 'TLS SOCKS5',
      type: 'socks5',
      config: {
        'name': 'TLS SOCKS5',
        'type': 'socks5',
        'server': '127.0.0.1',
        'port': 1080,
        'username': 'alice',
        'password': 'secret',
        'tls': true,
        'skip-cert-verify': true,
        'fingerprint': 'chrome',
        'certificate': 'CERTIFICATE',
        'private-key': 'PRIVATE KEY',
        'tfo': true,
      },
    );
    await tester.runAsync(() => localProxyStore.add(original));
    final storedBeforeEdit = localProxyStore.proxies.single;

    await tester.pumpWidget(_wrap(LocalProxyEditPage(proxy: storedBeforeEdit)));
    await _pumpFrames(tester);

    final tlsTile = find
        .ancestor(of: find.text('TLS'), matching: find.byType(ListTile))
        .first;
    final tlsSwitch = tester.widget<Switch>(
      find.descendant(of: tlsTile, matching: find.byType(Switch)),
    );
    tlsSwitch.onChanged!(false);
    await _pumpFrames(tester);
    await _tapSave(tester);

    final saved = localProxyStore.proxies.single;
    expect(saved.config['tls'], isFalse);
    for (final key in [
      'skip-cert-verify',
      'fingerprint',
      'certificate',
      'private-key',
    ]) {
      expect(saved.config.containsKey(key), isFalse);
    }
    expect(saved.config['tfo'], isTrue);
  });

  testWidgets('rejects SOCKS5 password without username', (tester) async {
    await tester.pumpWidget(
      _wrap(const LocalProxyEditPage(initialType: 'socks5')),
    );
    await _pumpFrames(tester);

    await _enterField(tester, 'Name', 'Password-only SOCKS5');
    await _enterField(tester, 'Server', '127.0.0.1');
    await _enterField(tester, 'Port', '1080');
    await _enterField(tester, 'Password', 'secret');

    await _tapSave(tester, expectStoreChange: false);
    expect(localProxyStore.proxies, isEmpty);
  });

  testWidgets('requires SOCKS5 TLS certificate and private key together', (
    tester,
  ) async {
    final original = _proxy(
      id: 14,
      name: 'TLS SOCKS5',
      type: 'socks5',
      config: {
        'name': 'TLS SOCKS5',
        'type': 'socks5',
        'server': '127.0.0.1',
        'port': 1080,
        'username': 'alice',
        'password': 'secret',
        'tls': true,
      },
    );
    await tester.runAsync(() => localProxyStore.add(original));
    final storedBeforeEdit = localProxyStore.proxies.single;

    await tester.pumpWidget(_wrap(LocalProxyEditPage(proxy: storedBeforeEdit)));
    await _pumpFrames(tester);

    await _enterField(tester, 'Certificate', 'CERTIFICATE');
    await _tapSave(tester, expectStoreChange: false);
    expect(localProxyStore.proxies, hasLength(1));
    expect(
      localProxyStore.proxies.single.config.containsKey('certificate'),
      isFalse,
    );

    await _enterField(tester, 'Certificate', '');
    await _enterField(tester, 'Private key', 'PRIVATE KEY');
    await _tapSave(tester, expectStoreChange: false);
    expect(localProxyStore.proxies, hasLength(1));
    expect(
      localProxyStore.proxies.single.config.containsKey('private-key'),
      isFalse,
    );

    await _enterField(tester, 'Certificate', 'CERTIFICATE');
    await _tapSave(tester);
    expect(localProxyStore.proxies, hasLength(1));
    expect(localProxyStore.proxies.single.config['certificate'], 'CERTIFICATE');
    expect(localProxyStore.proxies.single.config['private-key'], 'PRIVATE KEY');
  });

  testWidgets('preserves missing SOCKS5 udp when editing', (tester) async {
    final original = _proxy(
      id: 13,
      name: 'Imported SOCKS5',
      type: 'socks5',
      config: {
        'name': 'Imported SOCKS5',
        'type': 'socks5',
        'server': 'socks.example.com',
        'port': 1080,
        'username': 'alice',
        'password': 'secret',
      },
    );
    await tester.runAsync(() => localProxyStore.add(original));
    final storedBeforeEdit = localProxyStore.proxies.single;

    await tester.pumpWidget(_wrap(LocalProxyEditPage(proxy: storedBeforeEdit)));
    await _pumpFrames(tester);
    await _tapSave(tester);

    final saved = localProxyStore.proxies.single;
    expect(saved.config.containsKey('udp'), isFalse);
  });

  testWidgets('initializes SSH multiline fields and omits UDP when editing', (
    tester,
  ) async {
    final original = _proxy(
      id: 12,
      name: 'Existing SSH',
      type: 'ssh',
      config: {
        'name': 'Existing SSH',
        'type': 'ssh',
        'server': 'ssh.example.com',
        'port': 22,
        'username': 'root',
        'password': 'secret',
        'private-key': 'PRIVATE KEY\nBODY',
        'private-key-passphrase': 'phrase',
        'host-key': [
          'ssh-ed25519 AAAAfirst comment',
          'ssh-rsa AAAAsecond comment',
        ],
        'host-key-algorithms': ['ssh-ed25519', 'rsa-sha2-512'],
        'udp': true,
        'tfo': true,
        'mptcp': true,
        'interface-name': 'eth0',
        'routing-mark': 123,
        'ip-version': 'ipv4',
        'dialer-proxy': 'CHAIN',
      },
    );
    await tester.runAsync(() => localProxyStore.add(original));
    final storedBeforeEdit = localProxyStore.proxies.single;

    await tester.pumpWidget(_wrap(LocalProxyEditPage(proxy: storedBeforeEdit)));
    await _pumpFrames(tester);

    expect(tester.takeException(), isNull);
    expect(_fieldController(tester, 'Username').text, 'root');
    expect(_fieldController(tester, 'Private key passphrase').text, 'phrase');
    await tester.scrollUntilVisible(
      _field('Host key'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      _fieldController(tester, 'Host key').text,
      'ssh-ed25519 AAAAfirst comment\nssh-rsa AAAAsecond comment',
    );
    expect(
      _fieldController(tester, 'Host key algorithms').text,
      'ssh-ed25519\nrsa-sha2-512',
    );
    await _enterField(
      tester,
      'Host key algorithms',
      'ssh-ed25519, rsa-sha2-512， ecdsa-sha2-nistp256\nssh-dss',
    );
    expect(find.text('UDP'), findsNothing);
    expect(find.text('Advanced settings'), findsNothing);

    await _tapSave(tester);

    final saved = localProxyStore.proxies.single;
    expect(saved.id, original.id);
    expect(saved.config['private-key-passphrase'], 'phrase');
    expect(saved.config['host-key'], [
      'ssh-ed25519 AAAAfirst comment',
      'ssh-rsa AAAAsecond comment',
    ]);
    expect(saved.config['host-key-algorithms'], [
      'ssh-ed25519',
      'rsa-sha2-512',
      'ecdsa-sha2-nistp256',
      'ssh-dss',
    ]);
    expect(saved.config.containsKey('udp'), isFalse);
    expect(saved.config['tfo'], isTrue);
    expect(saved.config['mptcp'], isTrue);
    expect(saved.config['interface-name'], 'eth0');
    expect(saved.config['routing-mark'], 123);
    expect(saved.config['ip-version'], 'ipv4');
    expect(saved.config['dialer-proxy'], 'CHAIN');
    expect(saved.config.keys, everyElement(isNot(contains('Key'))));
    expect(saved.config.containsKey('privateKeyPassphrase'), isFalse);
    expect(saved.config.containsKey('hostKey'), isFalse);
    expect(saved.config.containsKey('hostKeyAlgorithms'), isFalse);
  });

  testWidgets('canonicalizes legacy SSH camelCase fields on save', (
    tester,
  ) async {
    final original = _proxy(
      id: 16,
      name: 'Legacy SSH',
      type: 'ssh',
      config: {
        'name': 'Legacy SSH',
        'type': 'ssh',
        'server': 'ssh.example.com',
        'port': 22,
        'username': 'root',
        'password': 'secret',
        'privateKey': 'LEGACY PRIVATE KEY',
        'privateKeyPassphrase': 'legacy phrase',
        'hostKey': ['ssh-ed25519 LEGACY comment'],
        'hostKeyAlgorithms': ['ssh-ed25519'],
        'udp': false,
        'tfo': true,
        'mptcp': true,
        'interface-name': 'eth0',
        'routing-mark': 123,
        'ip-version': 'ipv4',
        'dialer-proxy': 'CHAIN',
      },
    );
    await tester.runAsync(() => localProxyStore.add(original));
    final storedBeforeEdit = localProxyStore.proxies.single;

    await tester.pumpWidget(_wrap(LocalProxyEditPage(proxy: storedBeforeEdit)));
    await _pumpFrames(tester);

    expect(_fieldController(tester, 'Private key').text, 'LEGACY PRIVATE KEY');
    expect(
      _fieldController(tester, 'Private key passphrase').text,
      'legacy phrase',
    );
    await tester.scrollUntilVisible(
      _field('Host key'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      _fieldController(tester, 'Host key').text,
      'ssh-ed25519 LEGACY comment',
    );
    expect(_fieldController(tester, 'Host key algorithms').text, 'ssh-ed25519');

    await _tapSave(tester);

    final saved = localProxyStore.proxies.single;
    expect(saved.config['private-key'], 'LEGACY PRIVATE KEY');
    expect(saved.config['private-key-passphrase'], 'legacy phrase');
    expect(saved.config['host-key'], ['ssh-ed25519 LEGACY comment']);
    expect(saved.config['host-key-algorithms'], ['ssh-ed25519']);
    expect(saved.config.containsKey('udp'), isFalse);
    expect(saved.config['tfo'], isTrue);
    expect(saved.config['mptcp'], isTrue);
    expect(saved.config['interface-name'], 'eth0');
    expect(saved.config['routing-mark'], 123);
    expect(saved.config['ip-version'], 'ipv4');
    expect(saved.config['dialer-proxy'], 'CHAIN');
    for (final key in [
      'privateKey',
      'privateKeyPassphrase',
      'hostKey',
      'hostKeyAlgorithms',
    ]) {
      expect(saved.config.containsKey(key), isFalse, reason: key);
    }
  });

  testWidgets('validates SSH username, authentication, and passphrase', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const LocalProxyEditPage(initialType: 'ssh')),
    );
    await _pumpFrames(tester);

    await _enterField(tester, 'Name', 'New SSH');
    await _enterField(tester, 'Server', '127.0.0.1');
    await _enterField(tester, 'Port', '22');

    await _tapSave(tester, expectStoreChange: false);
    expect(localProxyStore.proxies, isEmpty);

    await _enterField(tester, 'Username', 'root');
    await _tapSave(tester, expectStoreChange: false);
    expect(localProxyStore.proxies, isEmpty);

    await _enterField(tester, 'Private key passphrase', 'phrase');
    await _tapSave(tester, expectStoreChange: false);
    expect(localProxyStore.proxies, isEmpty);

    await _enterField(tester, 'Private key', 'PRIVATE KEY');
    await _tapSave(tester);
    expect(localProxyStore.proxies, hasLength(1));
    expect(localProxyStore.proxies.single.config['private-key'], 'PRIVATE KEY');
    expect(
      localProxyStore.proxies.single.config['private-key-passphrase'],
      'phrase',
    );
  });

  testWidgets('disposes all added controllers without an exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const LocalProxyEditPage(initialType: 'ssh')),
    );
    await _pumpFrames(tester);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpFrames(tester);
    expect(tester.takeException(), isNull);
  });
}
