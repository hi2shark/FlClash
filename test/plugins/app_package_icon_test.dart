import 'package:fl_clash/common/constant.dart';
import 'package:fl_clash/plugins/app.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannel channel;
  late App client;
  var calls = 0;

  setUp(() {
    calls = 0;
    channel = const MethodChannel('$packageName/app');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls += 1;
          if (call.method == 'getPackageIcon') {
            return '/tmp/icon.png';
          }
          return null;
        });
    client = App.forTest(channel);
  });

  tearDown(() {
    client.clearPackageIconCache();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('returns null for empty package names without a channel call', () async {
    expect(await client.getPackageIcon(''), isNull);
    expect(calls, 0);
    expect(client.hasPackageIcon(''), isFalse);
  });

  test('deduplicates in-flight and cached package icon loads', () async {
    final first = client.getPackageIcon('com.example.app');
    final second = client.getPackageIcon('com.example.app');
    final icons = await Future.wait([first, second]);

    expect(icons, everyElement(isA<FileImage>()));
    expect(calls, 1);
    expect(client.hasPackageIcon('com.example.app'), isTrue);
    expect(await client.getPackageIcon('com.example.app'), icons.first);
    expect(calls, 1);
  });

  test('caches a failed lookup so the channel is not retried', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls += 1;
          throw PlatformException(code: 'missing');
        });

    expect(await client.getPackageIcon('com.missing'), isNull);
    expect(await client.getPackageIcon('com.missing'), isNull);
    expect(calls, 1);
    expect(client.getCachedPackageIcon('com.missing'), isNull);
  });
}
