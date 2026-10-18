import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TooltipText derives tooltip message from rich text', (
    tester,
  ) async {
    // The narrow box forces a single-line overflow, which is the only
    // condition under which TooltipText attaches its tooltip.
    const richText = Text.rich(
      TextSpan(
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
            return const Center(
              child: SizedBox(width: 20, child: TooltipText(text: richText)),
            );
          },
        ),
      ),
    );

    // Settle so the overflow measurement completes before the assertion.
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
            return const Center(
              child: SizedBox(width: 1000, child: TooltipText(text: text)),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(Tooltip), findsNothing);
    expect(find.byType(Text), findsOneWidget);
  });
}
