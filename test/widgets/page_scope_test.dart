import 'package:fl_clash/widgets/page_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PageActivityScope reports the nearest active flag', (
    tester,
  ) async {
    late bool latest;
    await tester.pumpWidget(
      PageActivityScope(
        isActive: false,
        child: Builder(
          builder: (context) {
            latest = PageActivityScope.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(latest, isFalse);
  });

  testWidgets('PageActivityScope defaults to active without an ancestor', (
    tester,
  ) async {
    late bool latest;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          latest = PageActivityScope.of(context);
          return const SizedBox();
        },
      ),
    );
    expect(latest, isTrue);
  });

  testWidgets('BackLayerScope pops the most recent overlay first', (
    tester,
  ) async {
    final dismissed = <String>[];
    late BackLayerScopeState scope;
    await tester.pumpWidget(
      BackLayerScope(
        child: Builder(
          builder: (context) {
            scope = BackLayerScope.maybeOf(context)!;
            return const SizedBox();
          },
        ),
      ),
    );

    void first() => dismissed.add('search');
    void second() => dismissed.add('edit');
    scope.push(first);
    scope.push(second);

    expect(scope.hasLayers, isTrue);
    expect(scope.handleBack(), isTrue);
    expect(dismissed, ['edit']);
    expect(scope.handleBack(), isTrue);
    expect(dismissed, ['edit', 'search']);
    expect(scope.handleBack(), isFalse);
    expect(scope.hasLayers, isFalse);
  });
}
