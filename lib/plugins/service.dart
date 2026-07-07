import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract mixin class ServiceListener {
  void onServiceEvent(CoreEvent event) {}

  void onServiceCrash(String message) {}

  void onServiceSuspended(bool suspended) {}

  void onWifiWatchState(String stateJson) {}
}

class Service {
  static Service? _instance;
  late MethodChannel methodChannel;
  ReceivePort? receiver;

  final ObserverList<ServiceListener> _listeners =
      ObserverList<ServiceListener>();

  factory Service() {
    _instance ??= Service._internal();
    return _instance!;
  }

  Service._internal() {
    methodChannel = const MethodChannel('$packageName/service');
    methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'event':
          final data = call.arguments as String? ?? '';
          final result = ActionResult.fromJson(json.decode(data));
          for (final listener in _listeners) {
            listener.onServiceEvent(CoreEvent.fromJson(result.data));
          }
          break;
        case 'crash':
          final message = call.arguments as String? ?? '';
          for (final listener in _listeners) {
            listener.onServiceCrash(message);
          }
          break;
        case 'suspended':
          final suspended = call.arguments as bool? ?? false;
          for (final listener in _listeners) {
            listener.onServiceSuspended(suspended);
          }
          break;
        case 'wifiWatchState':
          final stateJson = call.arguments as String? ?? '{}';
          for (final listener in _listeners) {
            listener.onWifiWatchState(stateJson);
          }
          break;
        default:
          throw MissingPluginException();
      }
    });
  }

  Future<ActionResult?> invokeAction(Action action) async {
    final data = await methodChannel.invokeMethod<String>(
      'invokeAction',
      json.encode(action),
    );
    if (data == null) {
      return null;
    }
    final dataJson = await data.commonToJSON<dynamic>();
    return ActionResult.fromJson(dataJson);
  }

  Future<bool> start() async {
    return await methodChannel.invokeMethod<bool>('start') ?? false;
  }

  Future<bool> stop() async {
    return await methodChannel.invokeMethod<bool>('stop') ?? false;
  }

  Future<bool> setSuspended(bool suspended) async {
    return await methodChannel.invokeMethod<bool>('setSuspended', suspended) ??
        false;
  }

  Future<String> init() async {
    return await methodChannel.invokeMethod<String>('init') ?? '';
  }

  Future<String> syncState(SharedState state) async {
    return await methodChannel.invokeMethod<String>(
          'syncState',
          json.encode(state),
        ) ??
        '';
  }

  Future<bool> shutdown() async {
    return await methodChannel.invokeMethod<bool>('shutdown') ?? true;
  }

  Future<DateTime?> getRunTime() async {
    final ms = await methodChannel.invokeMethod<int>('getRunTime') ?? 0;
    if (ms == 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<String> getWifiWatchState() async {
    return await methodChannel.invokeMethod<String>('getWifiWatchState') ?? '{}';
  }

  bool get hasListeners {
    return _listeners.isNotEmpty;
  }

  void addListener(ServiceListener listener) {
    _listeners.add(listener);
  }

  void removeListener(ServiceListener listener) {
    _listeners.remove(listener);
  }
}

Service? get service => system.isAndroid ? Service() : null;
