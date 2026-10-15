import 'iterable.dart';

typedef ValueCallback<T> = T Function();

class FixedList<T> {
  final int maxLength;
  final List<T> _list;

  final int _revision;
  List<T>? _snapshot;

  FixedList(this.maxLength, {List<T>? list})
    : assert(maxLength > 0, 'FixedList without a cap grows without bound'),
      _list = (list ?? [])..truncate(maxLength),
      _revision = 0;

  FixedList._(this.maxLength, this._list, this._revision);

  int get revision => _revision;

  void add(T item) {
    _list.add(item);
    _list.truncate(maxLength);
    _snapshot = null;
  }

  void clear() {
    _list.clear();
    _snapshot = null;
  }

  FixedList<T> append(T item) {
    add(item);
    return FixedList._(maxLength, _list, _revision + 1);
  }

  List<T> get list => _snapshot ??= List.unmodifiable(_list);

  int get length => _list.length;

  T operator [](int index) => _list[index];

  FixedList<T> copyWith() {
    return FixedList(maxLength, list: List.of(_list));
  }

  @override
  bool operator ==(Object other) =>
      other is FixedList<T> &&
      identical(other._list, _list) &&
      other._revision == _revision;

  @override
  int get hashCode => Object.hash(identityHashCode(_list), _revision);
}

class FixedMap<K, V> {
  int maxLength;
  late Map<K, V> _map;

  FixedMap(this.maxLength, {Map<K, V>? map}) {
    _map = map ?? {};
    _adjustMap();
  }

  V updateCacheValue(K key, ValueCallback<V> callback) {
    final realValue = _map.updateCacheValue(key, callback);
    _adjustMap();
    return realValue;
  }

  void clear() {
    _map.clear();
  }

  void updateMaxLength(int size) {
    maxLength = size;
    _adjustMap();
  }

  void updateMap(Map<K, V> map) {
    _map = map;
    _adjustMap();
  }

  void _adjustMap() {
    if (maxLength <= 0) {
      _map.clear();
      return;
    }
    if (_map.length > maxLength) {
      _map = Map.fromEntries(map.entries.toList()..truncate(maxLength));
    }
  }

  V? get(K key) => _map[key];

  bool containsKey(K key) => _map.containsKey(key);

  int get length => _map.length;

  Map<K, V> get map => Map.unmodifiable(_map);
}

/// Restores the head that [latest] trimmed off [current] so a paused view
/// stays anchored; the result is capped at [limit] from the tail.
List<T> retainTrimmedHead<T>(List<T> current, List<T> latest, int limit) {
  if (current.isEmpty || latest.isEmpty) {
    return latest;
  }
  final index = current.indexWhere((item) => identical(item, latest.first));
  if (index == 0) {
    return latest;
  }
  final head = index > 0 ? current.sublist(0, index) : current;
  return List.unmodifiable([...head, ...latest].take(limit));
}
