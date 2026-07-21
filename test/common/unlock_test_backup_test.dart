import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:fl_clash/common/task.dart';
import 'package:fl_clash/database/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

void main() {
  setUpAll(() {
    open.overrideFor(
      OperatingSystem.linux,
      () => DynamicLibrary.open('libsqlite3.so.0'),
    );
  });

  test('backup database copy strips unlock test history', () async {
    final directory = await Directory.systemTemp.createTemp(
      'flclash-unlock-backup-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/database.sqlite');

    var database = Database(NativeDatabase(file));
    await database.unlockTestRunsDao.insertAndPrune(
      UnlockTestRunRecord(
        runId: 'history',
        createdAt: DateTime.utc(2026, 7, 21),
        durationMs: 1000,
        routeMode: 'appRoute',
        catalogVersion: 2,
        resultsJson: '{}',
      ),
    );
    await database.close();

    await stripUnlockTestHistoryFromBackup(file);

    database = Database(NativeDatabase(file));
    expect(await database.unlockTestRunsDao.latest(), isEmpty);
    await database.close();
  });
}
