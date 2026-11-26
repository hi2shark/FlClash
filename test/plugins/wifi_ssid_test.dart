import 'package:fl_clash/common/constant.dart';
import 'package:fl_clash/plugins/wifi_ssid.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWifiSsidHost implements WifiSsidHost {
  String? ssid = 'Office';
  WifiConnectionInfo info = const WifiConnectionInfo(ssid: 'Office', rssi: -52);
  WifiSsidPermission permission = WifiSsidPermission.granted;
  WifiSsidPermission backgroundPermission = WifiSsidPermission.denied;
  final Stream<String?> stream;

  _FakeWifiSsidHost({this.stream = const Stream.empty()});

  @override
  Future<String?> getSsid() async => ssid;

  @override
  Future<WifiConnectionInfo> getCurrentWifiInfo() async => info;

  @override
  Future<WifiSsidPermission> checkPermission() async => permission;

  @override
  Future<WifiSsidPermission> requestPermission() async => permission;

  @override
  Future<WifiSsidPermission> checkBackgroundPermission() async =>
      backgroundPermission;

  @override
  Future<WifiSsidPermission> requestBackgroundPermission() async =>
      backgroundPermission;

  @override
  Stream<String?> get wifiStream => stream;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('$packageName/wifi_ssid');
  const eventChannel = EventChannel(
    '$packageName/wifi_ssid/validated_wifi_ssid',
  );

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(eventChannel, null);
  });

  test('WifiConnectionInfo.fromMap decodes null and populated maps', () {
    final empty = WifiConnectionInfo.fromMap(null);
    expect(empty.ssid, isNull);
    expect(empty.rssi, isNull);

    final info = WifiConnectionInfo.fromMap({'ssid': 'Home', 'rssi': -61.0});
    expect(info.ssid, 'Home');
    expect(info.rssi, -61);
  });

  test('AndroidWifiSsidHost calls the expected channel methods and decodes '
      'permission states', () async {
    final calls = <String>[];
    var permissionCode = 0;
    const backgroundCode = 2;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return switch (call.method) {
            'getSsid' => 'LabWiFi',
            'getCurrentWifiInfo' => <Object?, Object?>{
              'ssid': 'LabWiFi',
              'rssi': -48,
            },
            'checkPermission' => permissionCode,
            'requestPermission' => 1,
            'checkBackgroundPermission' => backgroundCode,
            'requestBackgroundPermission' => null,
            _ => null,
          };
        });

    const host = AndroidWifiSsidHost();
    expect(await host.getSsid(), 'LabWiFi');

    final info = await host.getCurrentWifiInfo();
    expect(info.ssid, 'LabWiFi');
    expect(info.rssi, -48);

    expect(await host.checkPermission(), WifiSsidPermission.granted);
    expect(await host.requestPermission(), WifiSsidPermission.denied);
    expect(
      await host.checkBackgroundPermission(),
      WifiSsidPermission.permanentlyDenied,
    );
    expect(await host.requestBackgroundPermission(), WifiSsidPermission.denied);

    permissionCode = 99;
    await expectLater(
      host.checkPermission(),
      throwsA(
        isA<PlatformException>().having(
          (e) => e.code,
          'code',
          'INVALID_PERMISSION_STATE',
        ),
      ),
    );
    expect(calls, containsAll(['getSsid', 'getCurrentWifiInfo']));
  });

  test('AndroidWifiSsidHost relays SSID updates on wifiStream', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (_, events) {
              events.success('Home');
              events.success(null);
              events.endOfStream();
            },
          ),
        );

    const host = AndroidWifiSsidHost();
    expect(await host.wifiStream.toList(), ['Home', null]);
  });

  test('WifiSsidManager delegates every method to the active host', () async {
    final fake = _FakeWifiSsidHost(stream: Stream.fromIterable(['Cafe']));
    wifiSsidManager.resetForTesting(fake);

    expect(await wifiSsidManager.getSsid(), 'Office');
    final info = await wifiSsidManager.getCurrentWifiInfo();
    expect(info.ssid, 'Office');
    expect(info.rssi, -52);
    expect(await wifiSsidManager.checkPermission(), WifiSsidPermission.granted);
    expect(
      await wifiSsidManager.requestPermission(),
      WifiSsidPermission.granted,
    );
    expect(
      await wifiSsidManager.checkBackgroundPermission(),
      WifiSsidPermission.denied,
    );
    expect(
      await wifiSsidManager.requestBackgroundPermission(),
      WifiSsidPermission.denied,
    );
    expect(await wifiSsidManager.wifiStream.toList(), ['Cafe']);
  });
}
