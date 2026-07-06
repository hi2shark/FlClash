class WifiWatchState {
  final String? ssid;
  final String? rawSsid;
  final int? rssi;
  final bool validated;
  final bool wifiPresent;
  final bool suspended;
  final DateTime? pendingSuspendDeadline;

  const WifiWatchState({
    this.ssid,
    this.rawSsid,
    this.rssi,
    this.validated = false,
    this.wifiPresent = false,
    this.suspended = false,
    this.pendingSuspendDeadline,
  });

  factory WifiWatchState.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    bool toBool(dynamic value) => value == true;

    final deadline = toInt(json['pendingSuspendDeadline']);
    return WifiWatchState(
      ssid: json['ssid']?.toString(),
      rawSsid: json['rawSsid']?.toString(),
      rssi: toInt(json['rssi']),
      validated: toBool(json['validated']),
      wifiPresent: toBool(json['wifiPresent']),
      suspended: toBool(json['suspended']),
      pendingSuspendDeadline:
          deadline == null ? null : DateTime.fromMillisecondsSinceEpoch(deadline),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ssid': ssid,
      'rawSsid': rawSsid,
      'rssi': rssi,
      'validated': validated,
      'wifiPresent': wifiPresent,
      'suspended': suspended,
      'pendingSuspendDeadline': pendingSuspendDeadline?.millisecondsSinceEpoch,
    };
  }

  WifiWatchState copyWith({
    String? ssid,
    String? rawSsid,
    int? rssi,
    bool? validated,
    bool? wifiPresent,
    bool? suspended,
    DateTime? pendingSuspendDeadline,
  }) {
    return WifiWatchState(
      ssid: ssid ?? this.ssid,
      rawSsid: rawSsid ?? this.rawSsid,
      rssi: rssi ?? this.rssi,
      validated: validated ?? this.validated,
      wifiPresent: wifiPresent ?? this.wifiPresent,
      suspended: suspended ?? this.suspended,
      pendingSuspendDeadline:
          pendingSuspendDeadline ?? this.pendingSuspendDeadline,
    );
  }
}
