import 'iterable.dart';

typedef ValueCallback<T> = T Function();

/// Bounded list that mutates in place. Use [share] after mutation to obtain a
/// new wrapper (same backing storage) so Riverpod can notify listeners without
/// copying every element.
class FixedList<T> {
  final int maxLength;
  final List<T> _list;

  FixedList(this.maxLength, {List<T>? list})
    : _list = List<T>.of(list ?? const []) {
    _list.truncate(maxLength);
  }

  FixedList._share(this.maxLength, this._list);

  void add(T item) {
    if (maxLength <= 0) {
      _list.clear();
      return;
    }
    _list.add(item);
    if (_list.length > maxLength) {
      _list.removeRange(0, _list.length - maxLength);
    }
  }

  void clear() {
    _list.clear();
  }

  /// New [FixedList] wrapping the same buffer (no element copy).
  FixedList<T> share() => FixedList._share(maxLength, _list);

  List<T> get list => List.unmodifiable(_list);

  int get length => _list.length;

  T operator [](int index) => _list[index];

  FixedList<T> copyWith() {
    return FixedList(maxLength, list: List.of(_list));
  }
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
