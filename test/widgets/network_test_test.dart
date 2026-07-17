import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/network_test.dart';
import 'package:fl_clash/widgets/list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
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
        return child;
      },
    ),
  );
}

void main() {
  setUpAll(() {
    globalState.container = ProviderContainer();
  });

  testWidgets('NetworkTestView builds without exceptions', (tester) async {
    await tester.pumpWidget(_wrap(const NetworkTestView()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(NetworkTestView), findsOneWidget);
  });

  testWidgets('typed OpenDelegate onChanged throws during ListItem.build', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: ListItem<String>.open(
            title: const Text('node'),
            delegate: OpenDelegate<String>(
              widget: const SizedBox(),
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isA<TypeError>());
  });
}
