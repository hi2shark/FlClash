class WifiWatchState {
  final String? ssid;
  final int? rssi;
  final bool validated;
  final bool wifiPresent;
  final bool suspended;
  final DateTime? pendingSuspendDeadline;

  const WifiWatchState({
    this.ssid,
    this.rssi,
    this.validated = false,
    this.wifiPresent = false,
    this.suspended = false,
    this.pendingSuspendDeadline,
  });

  factory WifiWatchState.fromJson(Map<String, dynamic> json) {
    final deadline = json['pendingSuspendDeadline'] as int?;
    return WifiWatchState(
      ssid: json['ssid'] as String?,
      rssi: json['rssi'] as int?,
      validated: json['validated'] as bool? ?? false,
      wifiPresent: json['wifiPresent'] as bool? ?? false,
      suspended: json['suspended'] as bool? ?? false,
      pendingSuspendDeadline:
          deadline == null ? null : DateTime.fromMillisecondsSinceEpoch(deadline),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ssid': ssid,
      'rssi': rssi,
      'validated': validated,
      'wifiPresent': wifiPresent,
      'suspended': suspended,
      'pendingSuspendDeadline': pendingSuspendDeadline?.millisecondsSinceEpoch,
    };
  }

  WifiWatchState copyWith({
    String? ssid,
    int? rssi,
    bool? validated,
    bool? wifiPresent,
    bool? suspended,
    DateTime? pendingSuspendDeadline,
  }) {
    return WifiWatchState(
      ssid: ssid ?? this.ssid,
      rssi: rssi ?? this.rssi,
      validated: validated ?? this.validated,
      wifiPresent: wifiPresent ?? this.wifiPresent,
      suspended: suspended ?? this.suspended,
      pendingSuspendDeadline:
          pendingSuspendDeadline ?? this.pendingSuspendDeadline,
    );
  }
}
