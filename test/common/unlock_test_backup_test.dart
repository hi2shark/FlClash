import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:fl_clash/common/backup.dart';
import 'package:fl_clash/database/database.dart';
import 'package:flutter_test/flutter_test.dart';

Future<int> _userVersion(File file) async {
  final handle = await file.open();
  try {
    final header = await handle.read(64);
    return ByteData.sublistView(header).getInt32(60);
  } finally {
    await handle.close();
  }
}

void main() {
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

  test(
    'stripping unlock test history keeps the schema version marker',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'flclash-unlock-backup-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/database.sqlite');

      final database = Database(NativeDatabase(file));
      await database
          .customSelect('PRAGMA user_version = ${database.schemaVersion + 1}')
          .get();
      await database.close();

      expect(await _userVersion(file), database.schemaVersion + 1);

      await stripUnlockTestHistoryFromBackup(file);

      // A snapshot from a newer app must still read as newer on restore, so the
      // strip may not rewind the header to the running app's version.
      expect(await _userVersion(file), database.schemaVersion + 1);
    },
  );
}
