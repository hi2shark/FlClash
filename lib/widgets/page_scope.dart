import 'package:flutter/widgets.dart';

class PageActivityScope extends InheritedWidget {
  final bool isActive;

  const PageActivityScope({
    super.key,
    required this.isActive,
    required super.child,
  });

  static bool of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<PageActivityScope>()
            ?.isActive ??
        true;
  }

  @override
  bool updateShouldNotify(PageActivityScope oldWidget) {
    return isActive != oldWidget.isActive;
  }
}

class BackLayerScope extends StatefulWidget {
  final Widget child;

  const BackLayerScope({super.key, required this.child});

  static BackLayerScopeState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<BackLayerScopeState>();
  }

  @override
  State<BackLayerScope> createState() => BackLayerScopeState();
}

class BackLayerScopeState extends State<BackLayerScope> {
  final List<VoidCallback> _layers = [];

  void push(VoidCallback onBack) {
    if (!_layers.contains(onBack)) {
      _layers.add(onBack);
    }
  }

  void remove(VoidCallback onBack) {
    _layers.remove(onBack);
  }

  bool get hasLayers => _layers.isNotEmpty;

  bool handleBack() {
    if (_layers.isEmpty) {
      return false;
    }
    _layers.removeLast()();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
