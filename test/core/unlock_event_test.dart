import 'dart:async';

import 'package:fl_clash/core/event.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

class _Listener with CoreEventListener {
  final progress = Completer<UnlockTestProgress>();

  @override
  void onUnlockTestProgress(UnlockTestProgress value) {
    progress.complete(value);
  }
}

void main() {
  test('unlock progress core event is parsed and delivered', () async {
    final listener = _Listener();
    coreEventManager.addListener(listener);
    addTearDown(() => coreEventManager.removeListener(listener));

    coreEventManager.sendEvent(
      CoreEvent.fromJson({
        'type': 'unlockTestProgress',
        'data': {
          'run-id': 'run-1',
          'completed': 1,
          'total': 2,
          'item': {'id': 'chatgpt', 'status': 'unlocked'},
        },
      }),
    );

    final progress = await listener.progress.future;
    expect(progress.runId, 'run-1');
    expect(progress.completed, 1);
    expect(progress.item.status, UnlockTestStatus.unlocked);
    expect(CoreEventType.unlockTestProgress.name, 'unlockTestProgress');
  });
}
