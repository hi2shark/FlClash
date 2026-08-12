import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/widgets/grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('core memory dashboard widget is single-height quarter width', () {
    final GridItem widget = DashboardWidget.coreMemoryInfo.widget;
    expect(widget.crossAxisCellCount, 4);
    expect(widget.mainAxisCellCount, isNull);
  });

  test('core memory widget uses CoreMemoryInfo child', () {
    expect(
      DashboardWidget.coreMemoryInfo.widget.child.runtimeType.toString(),
      'CoreMemoryInfo',
    );
  });
}
