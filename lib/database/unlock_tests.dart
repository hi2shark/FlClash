part of 'database.dart';

class UnlockTestRunRecord {
  final String runId;
  final DateTime createdAt;
  final int durationMs;
  final String routeMode;
  final String? proxyName;
  final int catalogVersion;
  final String resultsJson;

  const UnlockTestRunRecord({
    required this.runId,
    required this.createdAt,
    required this.durationMs,
    required this.routeMode,
    this.proxyName,
    required this.catalogVersion,
    required this.resultsJson,
  });
}

class UnlockTestRunsDao {
  final Database database;

  const UnlockTestRunsDao(this.database);

  Future<List<UnlockTestRunRecord>> latest({int limit = 10}) {
    return database
        .customSelect(
          '''
            SELECT run_id, created_at, duration_ms, route_mode, proxy_name,
                   catalog_version, results_json
            FROM unlock_test_runs
            ORDER BY created_at DESC
            LIMIT ?
          ''',
          variables: [Variable.withInt(limit)],
        )
        .map(_readRecord)
        .get();
  }

  Future<UnlockTestRunRecord?> latestAppRoute() async {
    final rows = await database
        .customSelect(
          '''
        SELECT run_id, created_at, duration_ms, route_mode, proxy_name,
               catalog_version, results_json
        FROM unlock_test_runs
        WHERE route_mode = ?
        ORDER BY created_at DESC
        LIMIT 1
      ''',
          variables: [Variable.withString('appRoute')],
        )
        .get();
    return rows.isEmpty ? null : _readRecord(rows.first);
  }

  Future<void> insertAndPrune(UnlockTestRunRecord record, {int keep = 10}) {
    return database.transaction(() async {
      await database.customStatement(
        '''
          INSERT OR REPLACE INTO unlock_test_runs (
            run_id, created_at, duration_ms, route_mode, proxy_name,
            catalog_version, results_json
          ) VALUES (?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          record.runId,
          record.createdAt.millisecondsSinceEpoch,
          record.durationMs,
          record.routeMode,
          record.proxyName,
          record.catalogVersion,
          record.resultsJson,
        ],
      );
      await database.customStatement(
        '''
          DELETE FROM unlock_test_runs
          WHERE run_id NOT IN (
            SELECT run_id
            FROM unlock_test_runs
            ORDER BY created_at DESC
            LIMIT ?
          )
        ''',
        [keep],
      );
    });
  }

  Future<void> clear() {
    return database.customStatement('DELETE FROM unlock_test_runs');
  }

  UnlockTestRunRecord _readRecord(QueryRow row) {
    return UnlockTestRunRecord(
      runId: row.read<String>('run_id'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('created_at'),
      ),
      durationMs: row.read<int>('duration_ms'),
      routeMode: row.read<String>('route_mode'),
      proxyName: row.readNullable<String>('proxy_name'),
      catalogVersion: row.read<int>('catalog_version'),
      resultsJson: row.read<String>('results_json'),
    );
  }
}
