import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TooltipText derives tooltip message from rich text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            globalState.measure = Measure.of(context, 1);
            return const SizedBox(
              width: 1,
              child: TooltipText(
                text: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Home'),
                      TextSpan(text: ' · Excluded'),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.pump();

    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, 'Home · Excluded');
  });
}
