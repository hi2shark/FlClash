import 'package:fl_clash/common/fixed.dart';
import 'package:fl_clash/common/iterable.dart';
import 'package:test/test.dart';

void main() {
  group('FixedList', () {
    test('rejects an uncapped list', () {
      expect(() => FixedList<int>(0), throwsA(isA<AssertionError>()));
    });

    test('respects maxLength on creation', () {
      final list = FixedList(3, list: [1, 2, 3, 4, 5]);
      expect(list.length, 3);
      expect(list.list, [3, 4, 5]);
    });

    test('truncates when adding beyond maxLength', () {
      final list = FixedList(3);
      list.add(1);
      list.add(2);
      list.add(3);
      list.add(4);
      expect(list.list, [2, 3, 4]);
    });

    test('clear empties the list', () {
      final list = FixedList(3, list: [1, 2, 3]);
      list.clear();
      expect(list.length, 0);
      expect(list.list, isEmpty);
    });

    test('copyWith creates independent copy', () {
      final original = FixedList(3, list: [1, 2, 3]);
      final copy = original.copyWith();
      copy.add(4);
      expect(original.list, [1, 2, 3]);
      expect(copy.list, [2, 3, 4]);
    });

    test('high-frequency add stays within capacity', () {
      final list = FixedList(500);
      for (var i = 0; i < 2000; i++) {
        list.add(i);
      }
      expect(list.length, 500);
      expect(list[0], 1500);
      expect(list[499], 1999);
    });

    test('operator [] returns correct element', () {
      final list = FixedList(5, list: [10, 20, 30]);
      expect(list[0], 10);
      expect(list[2], 30);
    });

    test('list getter returns unmodifiable view', () {
      final list = FixedList(3, list: [1, 2, 3]);
      final view = list.list;
      expect(() => view.add(4), throwsA(isA<UnsupportedError>()));
    });

    test('list caches the snapshot until the next mutation', () {
      final list = FixedList(3, list: [1, 2]);
      expect(identical(list.list, list.list), isTrue);
      list.add(3);
      expect(list.list, [1, 2, 3]);
    });

    test('append yields a new generation over the same buffer', () {
      final first = FixedList(3, list: [1, 2]);
      final second = first.append(3);
      expect(second.list, [1, 2, 3]);
      expect(second.revision, first.revision + 1);
    });

    test('append makes the wrapper unequal so listeners are notified', () {
      final first = FixedList(3, list: [1, 2]);
      expect(first == first.copyWith(), isFalse, reason: 'distinct buffers');
      expect(first == first.append(3), isFalse, reason: 'distinct generations');
    });

    test('a snapshot taken before append is unaffected by it', () {
      final first = FixedList(3, list: [1, 2]);
      final before = first.list;
      first.append(3);
      expect(before, [1, 2]);
    });

    test('replace swaps items in a new generation', () {
      final first = FixedList(3, list: [1, 2, 3]);
      final before = first.list;
      final second = first.replace({0: 10, 2: 30});
      expect(second.list, [10, 2, 30]);
      expect(second.revision, first.revision + 1);
      expect(before, [1, 2, 3]);
    });

    test('append still honours maxLength', () {
      var list = FixedList<int>(2);
      for (var i = 1; i <= 4; i++) {
        list = list.append(i);
      }
      expect(list.list, [3, 4]);
    });
  });

  group('List.truncate', () {
    test('maxLength <= 0 clears the list', () {
      final list = [1, 2, 3];
      list.truncate(0);
      expect(list, isEmpty);
      list.addAll([4, 5]);
      list.truncate(-1);
      expect(list, isEmpty);
    });
  });

  group('FixedMap', () {
    test('stores and retrieves values', () {
      final map = FixedMap<String, int>(5);
      map.updateCacheValue('a', () => 1);
      map.updateCacheValue('b', () => 2);
      expect(map.get('a'), 1);
      expect(map.get('b'), 2);
    });

    test('returns existing value without calling callback', () {
      final map = FixedMap<String, int>(5);
      map.updateCacheValue('a', () => 1);
      var called = false;
      final result = map.updateCacheValue('a', () {
        called = true;
        return 2;
      });
      expect(result, 1);
      expect(called, isFalse);
    });

    test('truncates when exceeding maxLength', () {
      final map = FixedMap<int, int>(3);
      map.updateCacheValue(1, () => 10);
      map.updateCacheValue(2, () => 20);
      map.updateCacheValue(3, () => 30);
      map.updateCacheValue(4, () => 40);
      expect(map.length, 3);
      expect(map.containsKey(1), isFalse);
      expect(map.containsKey(4), isTrue);
    });

    test('maxLength <= 0 clears map', () {
      final map = FixedMap<String, int>(0);
      map.updateCacheValue('a', () => 1);
      expect(map.length, 0);
    });

    test('clear empties the map', () {
      final map = FixedMap<String, int>(3);
      map.updateCacheValue('a', () => 1);
      map.clear();
      expect(map.length, 0);
    });

    test('updateMaxLength truncates existing data', () {
      final map = FixedMap<int, int>(5);
      for (int i = 0; i < 5; i++) {
        map.updateCacheValue(i, () => i * 10);
      }
      map.updateMaxLength(2);
      expect(map.length, 2);
    });

    test('updateMap replaces underlying data', () {
      final map = FixedMap<String, int>(5);
      map.updateCacheValue('a', () => 1);
      map.updateMap({'x': 100, 'y': 200});
      expect(map.get('a'), isNull);
      expect(map.get('x'), 100);
    });

    test('map getter returns unmodifiable view', () {
      final map = FixedMap<String, int>(3);
      map.updateCacheValue('a', () => 1);
      final view = map.map;
      expect(() => view['b'] = 2, throwsA(isA<UnsupportedError>()));
    });

    test('containsKey works correctly', () {
      final map = FixedMap<String, int>(3);
      map.updateCacheValue('a', () => 1);
      expect(map.containsKey('a'), isTrue);
      expect(map.containsKey('b'), isFalse);
    });

    test('get returns null for missing key', () {
      final map = FixedMap<String, int>(3);
      expect(map.get('missing'), isNull);
    });
  });

  group('retainTrimmedHead', () {
    final items = List.generate(6, (i) => Object());

    test('passes latest through when nothing was trimmed', () {
      final current = items.sublist(0, 3);
      final latest = items.sublist(0, 5);
      expect(retainTrimmedHead(current, latest, 10), same(latest));
      expect(retainTrimmedHead(<Object>[], latest, 10), same(latest));
    });

    test('restores entries trimmed off the front', () {
      final current = items.sublist(0, 4);
      final latest = items.sublist(2, 6);
      expect(retainTrimmedHead(current, latest, 10), items);
    });

    test('keeps everything current when latest is entirely newer', () {
      final current = items.sublist(0, 2);
      final latest = items.sublist(4, 6);
      expect(retainTrimmedHead(current, latest, 10), [...current, ...latest]);
    });

    test('finds where latest starts by key when it carries a copy', () {
      final current = [(1, 'a'), (2, 'a'), (3, 'a'), (4, 'a')];
      final latest = [(3, 'b'), (4, 'a'), (5, 'a')];
      expect(retainTrimmedHead(current, latest, 10, keyOf: (item) => item.$1), [
        (1, 'a'),
        (2, 'a'),
        (3, 'b'),
        (4, 'a'),
        (5, 'a'),
      ]);
    });

    test('caps growth from the tail', () {
      final current = items.sublist(0, 4);
      final latest = items.sublist(2, 6);
      expect(retainTrimmedHead(current, latest, 5), items.sublist(0, 5));
    });
  });
}
