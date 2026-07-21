import 'dart:ffi';

import 'package:drift/native.dart';
import 'package:fl_clash/database/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

void main() {
  late Database database;

  setUpAll(() {
    open.overrideFor(
      OperatingSystem.linux,
      () => DynamicLibrary.open('libsqlite3.so.0'),
    );
  });

  setUp(() {
    database = Database(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('completed history is pruned to the latest ten runs globally', () async {
    for (var index = 0; index < 12; index++) {
      await database.unlockTestRunsDao.insertAndPrune(
        UnlockTestRunRecord(
          runId: 'run-$index',
          createdAt: DateTime.utc(2026, 7, 21, 0, index),
          durationMs: 1000,
          routeMode: index.isEven ? 'appRoute' : 'proxy',
          proxyName: index.isEven ? null : 'P$index',
          catalogVersion: 2,
          resultsJson: '[]',
        ),
      );
    }

    final history = await database.unlockTestRunsDao.latest();
    expect(history, hasLength(10));
    expect(history.first.runId, 'run-11');
    expect(history.last.runId, 'run-2');
  });

  test('latest app route ignores newer named proxy runs', () async {
    await database.unlockTestRunsDao.insertAndPrune(
      UnlockTestRunRecord(
        runId: 'app',
        createdAt: DateTime.utc(2026, 7, 21),
        durationMs: 500,
        routeMode: 'appRoute',
        catalogVersion: 2,
        resultsJson: '[]',
      ),
    );
    await database.unlockTestRunsDao.insertAndPrune(
      UnlockTestRunRecord(
        runId: 'proxy',
        createdAt: DateTime.utc(2026, 7, 21, 1),
        durationMs: 500,
        routeMode: 'proxy',
        proxyName: 'P1',
        catalogVersion: 2,
        resultsJson: '[]',
      ),
    );

    expect((await database.unlockTestRunsDao.latestAppRoute())?.runId, 'app');
  });
}
