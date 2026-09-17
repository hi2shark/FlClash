import 'package:fl_clash/plugins/app.dart';
import 'package:fl_clash/widgets/package_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders an empty placeholder for missing package names', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PackageIcon(packageName: ''),
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.byType(SizedBox), findsOneWidget);
  });

  testWidgets('uses a cached icon without rebuilding a future', (tester) async {
    const channel = MethodChannel('com.hi2shark.flclash_nw/app');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => '/tmp/icon.png');
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final client = App.forTest(channel);
    await client.getPackageIcon('com.example.app');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PackageIcon(
            packageName: 'com.example.app',
            client: client,
            size: 24,
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
  });
}
