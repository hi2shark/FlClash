import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TooltipText derives tooltip message from rich text', (
    tester,
  ) async {
    // A modest width plus a single-line text that obviously exceeds it
    // guarantees didExceedMaxLines is true under the test font, without
    // relying on degenerate 1px layout behavior. The SSID · status pair
    // mirrors the production consumer in WifiWatchCard.
    final richText = Text.rich(
      const TextSpan(
        children: [
          TextSpan(text: 'Home'),
          TextSpan(text: ' · Excluded'),
          TextSpan(text: ' — trusted network, proxy suspended'),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            globalState.measure = Measure.of(context, 1);
            return Center(
              child: SizedBox(width: 20, child: TooltipText(text: richText)),
            );
          },
        ),
      ),
    );

    // pumpAndSettle ensures LayoutBuilder has applied the final constraints
    // and the overflow measurement has completed before we assert.
    await tester.pumpAndSettle();

    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(
      tooltip.message,
      'Home · Excluded — trusted network, proxy suspended',
    );
  });

  testWidgets('TooltipText omits Tooltip when text fits', (tester) async {
    const text = Text('Short', maxLines: 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            globalState.measure = Measure.of(context, 1);
            return Center(
              child: SizedBox(
                width: 1000,
                child: const TooltipText(text: text),
              ),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // When there is no overflow the widget must not attach a long-press
    // Tooltip, so the plain Text is returned directly.
    expect(find.byType(Tooltip), findsNothing);
    expect(find.byType(Text), findsOneWidget);
  });
}
