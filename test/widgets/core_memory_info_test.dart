import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/views/dashboard/widget_registry.dart';
import 'package:fl_clash/views/dashboard/widgets/core_memory_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('core memory dashboard widget builds the core memory card', () {
    expect(DashboardWidget.coreMemoryInfo.card, isA<CoreMemoryInfo>());
  });
}
