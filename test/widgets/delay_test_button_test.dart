import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/proxies/tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DelayTestButton reverses the animation when onClick throws', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: globalState.navigatorKey,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.delegate.supportedLocales,
        builder: (context, child) {
          globalState.theme = CommonTheme.of(context, 1);
          return child!;
        },
        home: Scaffold(
          body: DelayTestButton(
            onClick: () async {
              throw StateError('delay failed');
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pumpAndSettle();

    final fade = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(DelayTestButton),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is FadeTransition && widget.child is ScaleTransition,
        ),
      ),
    );
    expect(fade.opacity.value, 1);
  });
}
