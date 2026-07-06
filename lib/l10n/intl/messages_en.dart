// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(count) =>
      "${Intl.plural(count, one: '1 day ago', other: '${count} days ago')}";

  static String m1(label) =>
      "Are you sure you want to delete the selected ${label}?";

  static String m2(label) =>
      "Are you sure you want to delete the current ${label}?";

  static String m3(label) => "${label} details";

  static String m4(label) => "${label} cannot be empty";

  static String m5(label) => "Current ${label} already exists";

  static String m6(count) =>
      "${Intl.plural(count, one: '1 hour ago', other: '${count} hours ago')}";

  static String m7(target) => "${target} is an invalid policy";

  static String m8(proxyName) => "${proxyName} is an invalid proxy";

  static String m9(providerName) =>
      "${providerName} is an invalid proxy provider";

  static String m10(subRule) => "${subRule} is an invalid SUB_RULE";

  static String m11(groups) =>
      "Target groups ${groups} no longer exist, please reselect.";

  static String m12(total, enabled, groups) =>
      "${total} nodes · ${enabled} enabled · Groups: ${groups}";

  static String m13(total, enabled) => "${total} nodes · ${enabled} enabled";

  static String m14(appName) =>
      "1. Open System Settings > Privacy & Security\n2. Choose Location Services\n3. Find and check ${appName} in the right list\n\nAfter completing the setup, return to the app and use it normally. Thank you for your cooperation.";

  static String m15(count) =>
      "${Intl.plural(count, one: '1 minute ago', other: '${count} minutes ago')}";

  static String m16(count) =>
      "${Intl.plural(count, one: '1 month ago', other: '${count} months ago')}";

  static String m17(label) => "No ${label} yet";

  static String m18(label) => "${label} must be a number";

  static String m19(valid, invalid) =>
      "Detected ${valid} available nodes, ${invalid} failed";

  static String m20(label) => "${label} must be between 1024 and 49151";

  static String m21(count) => "${count} items have been selected";

  static String m22(label) => "${label} must be a url";

  static String m23(seconds) => "Suspend in ${seconds}s";

  static String m24(rssi) => "Signal: ${rssi} dBm";

  static String m25(seconds) => "Suspend in ${seconds}s";

  static String m26(count) =>
      "${Intl.plural(count, one: '1 year ago', other: '${count} years ago')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("About"),
    "accessControl": MessageLookupByLibrary.simpleMessage("AccessControl"),
    "accessControlAllowDesc": MessageLookupByLibrary.simpleMessage(
      "Only allow selected app to enter VPN",
    ),
    "accessControlDesc": MessageLookupByLibrary.simpleMessage(
      "Configure application access proxy",
    ),
    "accessControlNotAllowDesc": MessageLookupByLibrary.simpleMessage(
      "The selected application will be excluded from VPN",
    ),
    "accessControlSettings": MessageLookupByLibrary.simpleMessage(
      "Access Control Settings",
    ),
    "account": MessageLookupByLibrary.simpleMessage("Account"),
    "action": MessageLookupByLibrary.simpleMessage("Action"),
    "action_mode": MessageLookupByLibrary.simpleMessage("Switch mode"),
    "action_proxy": MessageLookupByLibrary.simpleMessage("System proxy"),
    "action_start": MessageLookupByLibrary.simpleMessage("Start/Stop"),
    "action_tun": MessageLookupByLibrary.simpleMessage("TUN"),
    "action_view": MessageLookupByLibrary.simpleMessage("Show/Hide"),
    "add": MessageLookupByLibrary.simpleMessage("Add"),
    "addLocalProxy": MessageLookupByLibrary.simpleMessage("Add local proxy"),
    "addProfile": MessageLookupByLibrary.simpleMessage("Add Profile"),
    "addProxies": MessageLookupByLibrary.simpleMessage("Add proxies"),
    "addProxyGroup": MessageLookupByLibrary.simpleMessage("Add proxy group"),
    "addProxyProviders": MessageLookupByLibrary.simpleMessage(
      "Add proxy providers",
    ),
    "addRule": MessageLookupByLibrary.simpleMessage("Add rule"),
    "addSsid": MessageLookupByLibrary.simpleMessage("Add SSID"),
    "addedRules": MessageLookupByLibrary.simpleMessage("Added rules"),
    "additionalParameters": MessageLookupByLibrary.simpleMessage(
      "Additional parameters",
    ),
    "address": MessageLookupByLibrary.simpleMessage("Address"),
    "addressHelp": MessageLookupByLibrary.simpleMessage(
      "WebDAV server address",
    ),
    "addressTip": MessageLookupByLibrary.simpleMessage(
      "Please enter a valid WebDAV address",
    ),
    "advancedConfig": MessageLookupByLibrary.simpleMessage(
      "Advanced configuration",
    ),
    "advancedConfigDesc": MessageLookupByLibrary.simpleMessage(
      "Provide diverse configuration options",
    ),
    "advancedSettings": MessageLookupByLibrary.simpleMessage(
      "Advanced settings",
    ),
    "agree": MessageLookupByLibrary.simpleMessage("Agree"),
    "allowBypass": MessageLookupByLibrary.simpleMessage(
      "Allow applications to bypass VPN",
    ),
    "allowBypassDesc": MessageLookupByLibrary.simpleMessage(
      "Some apps can bypass VPN when turned on",
    ),
    "allowLan": MessageLookupByLibrary.simpleMessage("AllowLan"),
    "allowLanDesc": MessageLookupByLibrary.simpleMessage(
      "Allow access proxy through the LAN",
    ),
    "alpn": MessageLookupByLibrary.simpleMessage("ALPN"),
    "anytls": MessageLookupByLibrary.simpleMessage("AnyTLS"),
    "app": MessageLookupByLibrary.simpleMessage("App"),
    "appAccessControl": MessageLookupByLibrary.simpleMessage(
      "App access control",
    ),
    "appendSystemDns": MessageLookupByLibrary.simpleMessage(
      "Append System DNS",
    ),
    "appendSystemDnsTip": MessageLookupByLibrary.simpleMessage(
      "Forcefully append system DNS to the configuration",
    ),
    "application": MessageLookupByLibrary.simpleMessage("Application"),
    "applicationDesc": MessageLookupByLibrary.simpleMessage(
      "Modify application related settings",
    ),
    "authorized": MessageLookupByLibrary.simpleMessage("Authorized"),
    "auto": MessageLookupByLibrary.simpleMessage("Auto"),
    "autoCheckUpdate": MessageLookupByLibrary.simpleMessage(
      "Auto check updates",
    ),
    "autoCheckUpdateDesc": MessageLookupByLibrary.simpleMessage(
      "Auto check for updates when the app starts",
    ),
    "autoCloseConnections": MessageLookupByLibrary.simpleMessage(
      "Auto close connections",
    ),
    "autoCloseConnectionsDesc": MessageLookupByLibrary.simpleMessage(
      "Auto close connections after change node",
    ),
    "autoLaunch": MessageLookupByLibrary.simpleMessage("Auto launch"),
    "autoLaunchDesc": MessageLookupByLibrary.simpleMessage(
      "Follow the system self startup",
    ),
    "autoRun": MessageLookupByLibrary.simpleMessage("AutoRun"),
    "autoRunDesc": MessageLookupByLibrary.simpleMessage(
      "Auto run when the application is opened",
    ),
    "autoSetSystemDns": MessageLookupByLibrary.simpleMessage(
      "Auto set system DNS",
    ),
    "autoUpdate": MessageLookupByLibrary.simpleMessage("Auto update"),
    "autoUpdateInterval": MessageLookupByLibrary.simpleMessage(
      "Auto update interval (minutes)",
    ),
    "backup": MessageLookupByLibrary.simpleMessage("Backup"),
    "backupAndRestore": MessageLookupByLibrary.simpleMessage(
      "Backup and Restore",
    ),
    "backupAndRestoreDesc": MessageLookupByLibrary.simpleMessage(
      "Sync data via WebDAV or files",
    ),
    "backupSuccess": MessageLookupByLibrary.simpleMessage("Backup success"),
    "basicConfig": MessageLookupByLibrary.simpleMessage("Basic configuration"),
    "basicConfigDesc": MessageLookupByLibrary.simpleMessage(
      "Modify the basic configuration globally",
    ),
    "basicInfo": MessageLookupByLibrary.simpleMessage("Basic info"),
    "basicStrategy": MessageLookupByLibrary.simpleMessage("Basic strategy"),
    "batteryOptimizationDesc": MessageLookupByLibrary.simpleMessage(
      "To ensure background operation, please disable battery optimization for this app. Tap to go to settings.",
    ),
    "batteryOptimizationStatusTip": MessageLookupByLibrary.simpleMessage(
      "Affected by the system, this status may not always be accurate.",
    ),
    "bbrProfile": MessageLookupByLibrary.simpleMessage("BBR profile"),
    "bind": MessageLookupByLibrary.simpleMessage("Bind"),
    "blacklistMode": MessageLookupByLibrary.simpleMessage("Blacklist mode"),
    "bypassDomain": MessageLookupByLibrary.simpleMessage("Bypass domain"),
    "bypassDomainDesc": MessageLookupByLibrary.simpleMessage(
      "Only takes effect when the system proxy is enabled",
    ),
    "cacheCorrupt": MessageLookupByLibrary.simpleMessage(
      "The cache is corrupt. Do you want to clear it?",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "cancelSelectAll": MessageLookupByLibrary.simpleMessage(
      "Cancel select all",
    ),
    "cannotSaveLocalMixin": MessageLookupByLibrary.simpleMessage(
      "Cannot save local proxy mix-in config",
    ),
    "certificate": MessageLookupByLibrary.simpleMessage("Certificate"),
    "checkUpdate": MessageLookupByLibrary.simpleMessage("Check for updates"),
    "checkUpdateError": MessageLookupByLibrary.simpleMessage(
      "The current application is already the latest version",
    ),
    "cipher": MessageLookupByLibrary.simpleMessage("Cipher"),
    "clearData": MessageLookupByLibrary.simpleMessage("Clear Data"),
    "clientFingerprint": MessageLookupByLibrary.simpleMessage(
      "Client fingerprint",
    ),
    "clipboardExport": MessageLookupByLibrary.simpleMessage("Export clipboard"),
    "clipboardImport": MessageLookupByLibrary.simpleMessage("Clipboard import"),
    "color": MessageLookupByLibrary.simpleMessage("Color"),
    "colorSchemes": MessageLookupByLibrary.simpleMessage("Color schemes"),
    "columns": MessageLookupByLibrary.simpleMessage("Columns"),
    "compatible": MessageLookupByLibrary.simpleMessage("Compatibility mode"),
    "configDataDetected": MessageLookupByLibrary.simpleMessage(
      "Data detected in configuration",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "confirmClearAllData": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to clear all data?",
    ),
    "confirmDeleteProxyGroup": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to delete the current proxy group?",
    ),
    "confirmExitWindow": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to exit the current window?",
    ),
    "confirmForceCrashCore": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to force crash the core?",
    ),
    "confirmOverwriteTip": MessageLookupByLibrary.simpleMessage(
      "Existing data will be overwritten after confirmation",
    ),
    "congestionController": MessageLookupByLibrary.simpleMessage(
      "Congestion controller",
    ),
    "connected": MessageLookupByLibrary.simpleMessage("Connected"),
    "connecting": MessageLookupByLibrary.simpleMessage("Connecting..."),
    "connection": MessageLookupByLibrary.simpleMessage("Connection"),
    "connections": MessageLookupByLibrary.simpleMessage("Connections"),
    "connectionsDesc": MessageLookupByLibrary.simpleMessage(
      "View current connections data",
    ),
    "connectivity": MessageLookupByLibrary.simpleMessage("Connectivity："),
    "content": MessageLookupByLibrary.simpleMessage("Content"),
    "contentNotEmpty": MessageLookupByLibrary.simpleMessage(
      "Content cannot be empty",
    ),
    "contentScheme": MessageLookupByLibrary.simpleMessage("Content"),
    "controlGlobalAddedRules": MessageLookupByLibrary.simpleMessage(
      "Control global added rules",
    ),
    "copy": MessageLookupByLibrary.simpleMessage("Copy"),
    "copyEnvVar": MessageLookupByLibrary.simpleMessage(
      "Copying environment variables",
    ),
    "copyLink": MessageLookupByLibrary.simpleMessage("Copy link"),
    "copySuccess": MessageLookupByLibrary.simpleMessage("Copy success"),
    "core": MessageLookupByLibrary.simpleMessage("Core"),
    "coreStatus": MessageLookupByLibrary.simpleMessage("Core status"),
    "country": MessageLookupByLibrary.simpleMessage("Country"),
    "crashTest": MessageLookupByLibrary.simpleMessage("Crash test"),
    "crashlytics": MessageLookupByLibrary.simpleMessage("Crash Analysis"),
    "crashlyticsTip": MessageLookupByLibrary.simpleMessage(
      "When enabled, automatically uploads crash logs without sensitive information when the app crashes",
    ),
    "create": MessageLookupByLibrary.simpleMessage("Create"),
    "createProfile": MessageLookupByLibrary.simpleMessage("Create Profile"),
    "creationTime": MessageLookupByLibrary.simpleMessage("Creation time"),
    "currentWifiConnection": MessageLookupByLibrary.simpleMessage(
      "Current Connection",
    ),
    "currentWifiSignal": MessageLookupByLibrary.simpleMessage(
      "Signal Strength",
    ),
    "currentWifiSsid": MessageLookupByLibrary.simpleMessage("SSID"),
    "currentWifiStatus": MessageLookupByLibrary.simpleMessage("Status"),
    "custom": MessageLookupByLibrary.simpleMessage("Custom"),
    "cut": MessageLookupByLibrary.simpleMessage("Cut"),
    "cwnd": MessageLookupByLibrary.simpleMessage("CWND"),
    "dark": MessageLookupByLibrary.simpleMessage("Dark"),
    "dashboard": MessageLookupByLibrary.simpleMessage("Dashboard"),
    "dataChangedSave": MessageLookupByLibrary.simpleMessage(
      "Data changes detected, do you want to save?",
    ),
    "dataCollectionContent": MessageLookupByLibrary.simpleMessage(
      "This app uses Firebase Crashlytics to collect crash information to improve app stability.\nThe collected data includes device information and crash details, but does not contain personal sensitive data.\nYou can disable this feature in settings.",
    ),
    "dataCollectionTip": MessageLookupByLibrary.simpleMessage(
      "Data Collection Notice",
    ),
    "daysAgo": m0,
    "defaultNameserver": MessageLookupByLibrary.simpleMessage(
      "Default nameserver",
    ),
    "defaultNameserverDesc": MessageLookupByLibrary.simpleMessage(
      "For resolving DNS server",
    ),
    "defaultText": MessageLookupByLibrary.simpleMessage("Default"),
    "delay": MessageLookupByLibrary.simpleMessage("Delay"),
    "delayTest": MessageLookupByLibrary.simpleMessage("Delay Test"),
    "delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "deleteMultipTip": m1,
    "deleteTip": m2,
    "desc": MessageLookupByLibrary.simpleMessage(
      "A multi-platform proxy client based on ClashMeta, simple and easy to use, open-source and ad-free.",
    ),
    "destination": MessageLookupByLibrary.simpleMessage("Destination"),
    "destinationGeoIP": MessageLookupByLibrary.simpleMessage(
      "Destination GeoIP",
    ),
    "destinationIPASN": MessageLookupByLibrary.simpleMessage(
      "Destination IPASN",
    ),
    "details": m3,
    "detectionTip": MessageLookupByLibrary.simpleMessage(
      "Relying on third-party api is for reference only",
    ),
    "developerMode": MessageLookupByLibrary.simpleMessage("Developer mode"),
    "developerModeEnableTip": MessageLookupByLibrary.simpleMessage(
      "Developer mode is enabled.",
    ),
    "direct": MessageLookupByLibrary.simpleMessage("Direct"),
    "disableUDP": MessageLookupByLibrary.simpleMessage("Disable UDP"),
    "disabled": MessageLookupByLibrary.simpleMessage("Disabled"),
    "disclaimer": MessageLookupByLibrary.simpleMessage("Disclaimer"),
    "disclaimerDesc": MessageLookupByLibrary.simpleMessage(
      "This software is only used for non-commercial purposes such as learning exchanges and scientific research. It is strictly prohibited to use this software for commercial purposes. Any commercial activity, if any, has nothing to do with this software.",
    ),
    "disconnected": MessageLookupByLibrary.simpleMessage("Disconnected"),
    "discoverNewVersion": MessageLookupByLibrary.simpleMessage(
      "Discover the new version",
    ),
    "dnsDesc": MessageLookupByLibrary.simpleMessage(
      "Update DNS related settings",
    ),
    "dnsHijacking": MessageLookupByLibrary.simpleMessage("DNS hijacking"),
    "dnsMode": MessageLookupByLibrary.simpleMessage("DNS mode"),
    "doYouWantToPass": MessageLookupByLibrary.simpleMessage(
      "Do you want to pass",
    ),
    "domain": MessageLookupByLibrary.simpleMessage("Domain"),
    "down": MessageLookupByLibrary.simpleMessage("Down"),
    "download": MessageLookupByLibrary.simpleMessage("Download"),
    "ech": MessageLookupByLibrary.simpleMessage("ECH"),
    "echConfig": MessageLookupByLibrary.simpleMessage("ECH config"),
    "edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "editGlobalRules": MessageLookupByLibrary.simpleMessage(
      "Edit global rules",
    ),
    "editLocalProxy": MessageLookupByLibrary.simpleMessage("Edit local proxy"),
    "editProxy": MessageLookupByLibrary.simpleMessage("Edit proxy"),
    "editProxyGroup": MessageLookupByLibrary.simpleMessage("Edit proxy group"),
    "editRule": MessageLookupByLibrary.simpleMessage("Edit rule"),
    "editSsid": MessageLookupByLibrary.simpleMessage("Edit SSID"),
    "emptyTip": m4,
    "en": MessageLookupByLibrary.simpleMessage("English"),
    "enableHealthCheck": MessageLookupByLibrary.simpleMessage(
      "Enable health check",
    ),
    "enableLocalProxyMixin": MessageLookupByLibrary.simpleMessage(
      "Enable local proxy mix-in",
    ),
    "enabled": MessageLookupByLibrary.simpleMessage("Enabled"),
    "enabledNodes": MessageLookupByLibrary.simpleMessage("Enabled nodes"),
    "entries": MessageLookupByLibrary.simpleMessage(" entries"),
    "exclude": MessageLookupByLibrary.simpleMessage("Hidden from recent tasks"),
    "excludeDesc": MessageLookupByLibrary.simpleMessage(
      "When the app is in the background, the app is hidden from the recent task",
    ),
    "excludeProxyFilter": MessageLookupByLibrary.simpleMessage(
      "Exclude proxy filter",
    ),
    "excludeSsids": MessageLookupByLibrary.simpleMessage("Exclude SSIDs"),
    "excludeSsidsDesc": MessageLookupByLibrary.simpleMessage(
      "When connected to an excluded SSID Wi-Fi, the app running state will be automatically switched.",
    ),
    "excludeType": MessageLookupByLibrary.simpleMessage("Exclude type"),
    "existsTip": m5,
    "exit": MessageLookupByLibrary.simpleMessage("Exit"),
    "expand": MessageLookupByLibrary.simpleMessage("Standard"),
    "expectedStatus": MessageLookupByLibrary.simpleMessage("Expected status"),
    "exportFile": MessageLookupByLibrary.simpleMessage("Export file"),
    "exportLogs": MessageLookupByLibrary.simpleMessage("Export logs"),
    "exportSuccess": MessageLookupByLibrary.simpleMessage("Export Success"),
    "expressiveScheme": MessageLookupByLibrary.simpleMessage("Expressive"),
    "externalController": MessageLookupByLibrary.simpleMessage(
      "ExternalController",
    ),
    "externalControllerDesc": MessageLookupByLibrary.simpleMessage(
      "Once enabled, the Clash kernel can be controlled on port 9090",
    ),
    "externalFetch": MessageLookupByLibrary.simpleMessage("External fetch"),
    "externalLink": MessageLookupByLibrary.simpleMessage("External link"),
    "fakeipFilter": MessageLookupByLibrary.simpleMessage("Fakeip filter"),
    "fakeipRange": MessageLookupByLibrary.simpleMessage("Fakeip range"),
    "fallback": MessageLookupByLibrary.simpleMessage("Fallback"),
    "fallbackDesc": MessageLookupByLibrary.simpleMessage(
      "Generally use offshore DNS",
    ),
    "fallbackFilter": MessageLookupByLibrary.simpleMessage("Fallback filter"),
    "fidelityScheme": MessageLookupByLibrary.simpleMessage("Fidelity"),
    "file": MessageLookupByLibrary.simpleMessage("File"),
    "fileDesc": MessageLookupByLibrary.simpleMessage("Directly upload profile"),
    "fileIsUpdate": MessageLookupByLibrary.simpleMessage(
      "The file has been modified. Do you want to save the changes?",
    ),
    "findProcessMode": MessageLookupByLibrary.simpleMessage("Find process"),
    "findProcessModeDesc": MessageLookupByLibrary.simpleMessage(
      "There is a certain performance loss after opening",
    ),
    "fingerprint": MessageLookupByLibrary.simpleMessage("Fingerprint"),
    "fontFamily": MessageLookupByLibrary.simpleMessage("FontFamily"),
    "forceRestartCoreTip": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to force restart the core?",
    ),
    "fruitSaladScheme": MessageLookupByLibrary.simpleMessage("FruitSalad"),
    "general": MessageLookupByLibrary.simpleMessage("General"),
    "geodataLoader": MessageLookupByLibrary.simpleMessage(
      "Geo Low Memory Mode",
    ),
    "geodataLoaderDesc": MessageLookupByLibrary.simpleMessage(
      "Enabling will use the Geo low memory loader",
    ),
    "geoipCode": MessageLookupByLibrary.simpleMessage("Geoip code"),
    "global": MessageLookupByLibrary.simpleMessage("Global"),
    "go": MessageLookupByLibrary.simpleMessage("Go"),
    "goDownload": MessageLookupByLibrary.simpleMessage("Go to download"),
    "goToConfigureScript": MessageLookupByLibrary.simpleMessage(
      "Go to configure script",
    ),
    "hasCacheChange": MessageLookupByLibrary.simpleMessage(
      "Do you want to cache the changes?",
    ),
    "healthCheck": MessageLookupByLibrary.simpleMessage("Health check"),
    "healthCheckInterval": MessageLookupByLibrary.simpleMessage(
      "Interval (seconds)",
    ),
    "healthCheckTimeout": MessageLookupByLibrary.simpleMessage("Timeout (ms)"),
    "healthCheckUrl": MessageLookupByLibrary.simpleMessage("Check URL"),
    "hideFromList": MessageLookupByLibrary.simpleMessage("Hide from list"),
    "host": MessageLookupByLibrary.simpleMessage("Host"),
    "hostsDesc": MessageLookupByLibrary.simpleMessage("Add Hosts"),
    "hotkeyConflict": MessageLookupByLibrary.simpleMessage("Hotkey conflict"),
    "hotkeyManagement": MessageLookupByLibrary.simpleMessage(
      "Hotkey Management",
    ),
    "hotkeyManagementDesc": MessageLookupByLibrary.simpleMessage(
      "Use keyboard to control applications",
    ),
    "hoursAgo": m6,
    "hysteria2": MessageLookupByLibrary.simpleMessage("Hysteria2"),
    "icon": MessageLookupByLibrary.simpleMessage("Icon"),
    "iconRecords": MessageLookupByLibrary.simpleMessage("Icon records"),
    "iconStyle": MessageLookupByLibrary.simpleMessage("Icon style"),
    "iconUrl": MessageLookupByLibrary.simpleMessage("Icon URL"),
    "idleSessionCheckInterval": MessageLookupByLibrary.simpleMessage(
      "Idle session check interval",
    ),
    "idleSessionTimeout": MessageLookupByLibrary.simpleMessage(
      "Idle session timeout",
    ),
    "ignoreBatteryOptimization": MessageLookupByLibrary.simpleMessage(
      "Ignore Battery Optimization",
    ),
    "import": MessageLookupByLibrary.simpleMessage("Import"),
    "importAvailableNodes": MessageLookupByLibrary.simpleMessage(
      "Import available nodes",
    ),
    "importFile": MessageLookupByLibrary.simpleMessage("Import from file"),
    "importFromURL": MessageLookupByLibrary.simpleMessage("Import from URL"),
    "importUrl": MessageLookupByLibrary.simpleMessage("Import from URL"),
    "includeAllProxies": MessageLookupByLibrary.simpleMessage(
      "Include all proxies",
    ),
    "includeAllProxiesTip": MessageLookupByLibrary.simpleMessage(
      "Import all proxies not containing proxy groups, additional proxy groups can be added below",
    ),
    "includeAllProxyProviders": MessageLookupByLibrary.simpleMessage(
      "Include all proxy providers",
    ),
    "includeAllProxyProvidersTip": MessageLookupByLibrary.simpleMessage(
      "When enabled, it will override the imported proxy providers",
    ),
    "incompleteSupport": MessageLookupByLibrary.simpleMessage(
      "Incomplete support",
    ),
    "infiniteTime": MessageLookupByLibrary.simpleMessage("Long term effective"),
    "init": MessageLookupByLibrary.simpleMessage("Init"),
    "inputCorrectHotkey": MessageLookupByLibrary.simpleMessage(
      "Please enter the correct hotkey",
    ),
    "inputProxyGroupName": MessageLookupByLibrary.simpleMessage(
      "Input proxy group name",
    ),
    "inputRuleContent": MessageLookupByLibrary.simpleMessage(
      "Input rule content",
    ),
    "intelligentSelected": MessageLookupByLibrary.simpleMessage(
      "Intelligent selection",
    ),
    "internet": MessageLookupByLibrary.simpleMessage("Internet"),
    "interval": MessageLookupByLibrary.simpleMessage("Interval"),
    "intranetIP": MessageLookupByLibrary.simpleMessage("Intranet IP"),
    "invalidBackupFile": MessageLookupByLibrary.simpleMessage(
      "Invalid backup file",
    ),
    "invalidPolicy": m7,
    "invalidProxy": m8,
    "invalidProxyProvider": m9,
    "invalidSubRule": m10,
    "ipcidr": MessageLookupByLibrary.simpleMessage("Ipcidr"),
    "ipv6Desc": MessageLookupByLibrary.simpleMessage(
      "When turned on it will be able to receive IPv6 traffic",
    ),
    "ipv6InboundDesc": MessageLookupByLibrary.simpleMessage(
      "Allow IPv6 inbound",
    ),
    "ja": MessageLookupByLibrary.simpleMessage("Japanese"),
    "justNow": MessageLookupByLibrary.simpleMessage("Just now"),
    "keepAliveIntervalDesc": MessageLookupByLibrary.simpleMessage(
      "Tcp keep alive interval",
    ),
    "key": MessageLookupByLibrary.simpleMessage("Key"),
    "language": MessageLookupByLibrary.simpleMessage("Language"),
    "layout": MessageLookupByLibrary.simpleMessage("Layout"),
    "light": MessageLookupByLibrary.simpleMessage("Light"),
    "list": MessageLookupByLibrary.simpleMessage("List"),
    "listen": MessageLookupByLibrary.simpleMessage("Listen"),
    "loadTest": MessageLookupByLibrary.simpleMessage("Load test"),
    "loading": MessageLookupByLibrary.simpleMessage("Loading..."),
    "local": MessageLookupByLibrary.simpleMessage("Local"),
    "localBackupDesc": MessageLookupByLibrary.simpleMessage(
      "Backup local data to local",
    ),
    "localFile": MessageLookupByLibrary.simpleMessage("Local file"),
    "localMixinDesc": MessageLookupByLibrary.simpleMessage(
      "Mix your manually added nodes into the current subscription without affecting updates.",
    ),
    "localMixinDisabled": MessageLookupByLibrary.simpleMessage("Disabled"),
    "localMixinEnabled": MessageLookupByLibrary.simpleMessage(
      "Status: enabled",
    ),
    "localMixinMissingGroups": m11,
    "localMixinStatus": m12,
    "localProxies": MessageLookupByLibrary.simpleMessage("Local Proxies"),
    "localProxyAnyTlsPasswordEmpty": MessageLookupByLibrary.simpleMessage(
      "AnyTLS password is required",
    ),
    "localProxyCarrierInvalid": MessageLookupByLibrary.simpleMessage(
      "Carrier must be tcp or udp",
    ),
    "localProxyCount": m13,
    "localProxyMixin": MessageLookupByLibrary.simpleMessage(
      "Local Proxy Mix-in",
    ),
    "localProxyNameEmpty": MessageLookupByLibrary.simpleMessage(
      "Proxy name cannot be empty",
    ),
    "localProxyNowhereKeyEmpty": MessageLookupByLibrary.simpleMessage(
      "Nowhere key is required",
    ),
    "localProxyPasswordEmpty": MessageLookupByLibrary.simpleMessage(
      "Password is required",
    ),
    "localProxyPoolInvalid": MessageLookupByLibrary.simpleMessage(
      "Pool must be 0-9",
    ),
    "localProxyPortInvalid": MessageLookupByLibrary.simpleMessage(
      "Port must be 1-65535",
    ),
    "localProxyServerEmpty": MessageLookupByLibrary.simpleMessage(
      "Server address cannot be empty",
    ),
    "localProxySsAuthEmpty": MessageLookupByLibrary.simpleMessage(
      "Shadowsocks cipher and password are required",
    ),
    "localProxyUuidEmpty": MessageLookupByLibrary.simpleMessage(
      "VLESS UUID is required",
    ),
    "locationPermission": MessageLookupByLibrary.simpleMessage(
      "Location Permission",
    ),
    "locationPermissionDeniedMessage": MessageLookupByLibrary.simpleMessage(
      "Location permission was denied, so the current Wi-Fi name cannot be obtained. Please open location permission manually in system settings.",
    ),
    "locationPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "According to system requirements, obtaining the Wi-Fi name requires you to grant location permission.",
    ),
    "locationPermissionGuide": m14,
    "locationPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "Location Permission Required",
    ),
    "log": MessageLookupByLibrary.simpleMessage("Log"),
    "logLevel": MessageLookupByLibrary.simpleMessage("LogLevel"),
    "logcat": MessageLookupByLibrary.simpleMessage("Logcat"),
    "logcatDesc": MessageLookupByLibrary.simpleMessage(
      "Disabling will hide the log entry",
    ),
    "logs": MessageLookupByLibrary.simpleMessage("Logs"),
    "logsDesc": MessageLookupByLibrary.simpleMessage("Log capture records"),
    "logsTest": MessageLookupByLibrary.simpleMessage("Logs test"),
    "loopback": MessageLookupByLibrary.simpleMessage("Loopback unlock tool"),
    "loopbackDesc": MessageLookupByLibrary.simpleMessage(
      "Used for UWP loopback unlocking",
    ),
    "loose": MessageLookupByLibrary.simpleMessage("Loose"),
    "manageLocalNodes": MessageLookupByLibrary.simpleMessage(
      "Manage Local Nodes",
    ),
    "manualAdd": MessageLookupByLibrary.simpleMessage("Manual add"),
    "matchSourceIp": MessageLookupByLibrary.simpleMessage("Match source IP"),
    "maxFailedTimes": MessageLookupByLibrary.simpleMessage("Max failed times"),
    "maxUdpRelayPacketSize": MessageLookupByLibrary.simpleMessage(
      "Max UDP relay packet size",
    ),
    "memoryInfo": MessageLookupByLibrary.simpleMessage("Memory info"),
    "messageTest": MessageLookupByLibrary.simpleMessage("Message test"),
    "messageTestTip": MessageLookupByLibrary.simpleMessage(
      "This is a message.",
    ),
    "min": MessageLookupByLibrary.simpleMessage("Min"),
    "minIdleSession": MessageLookupByLibrary.simpleMessage("Min idle session"),
    "minimizeOnExit": MessageLookupByLibrary.simpleMessage("Minimize on exit"),
    "minimizeOnExitDesc": MessageLookupByLibrary.simpleMessage(
      "Modify the default system exit event",
    ),
    "minutesAgo": m15,
    "mixedPort": MessageLookupByLibrary.simpleMessage("Mixed Port"),
    "mixinSettings": MessageLookupByLibrary.simpleMessage("Mixin Settings"),
    "mode": MessageLookupByLibrary.simpleMessage("Mode"),
    "monochromeScheme": MessageLookupByLibrary.simpleMessage("Monochrome"),
    "monthsAgo": m16,
    "more": MessageLookupByLibrary.simpleMessage("More"),
    "name": MessageLookupByLibrary.simpleMessage("Name"),
    "nameserver": MessageLookupByLibrary.simpleMessage("Nameserver"),
    "nameserverDesc": MessageLookupByLibrary.simpleMessage(
      "For resolving domain",
    ),
    "nameserverPolicy": MessageLookupByLibrary.simpleMessage(
      "Nameserver policy",
    ),
    "nameserverPolicyDesc": MessageLookupByLibrary.simpleMessage(
      "Specify the corresponding nameserver policy",
    ),
    "network": MessageLookupByLibrary.simpleMessage("Network"),
    "networkDesc": MessageLookupByLibrary.simpleMessage(
      "Modify network-related settings",
    ),
    "networkDetection": MessageLookupByLibrary.simpleMessage(
      "Network detection",
    ),
    "networkException": MessageLookupByLibrary.simpleMessage(
      "Network exception, please check your connection and try again",
    ),
    "networkSpeed": MessageLookupByLibrary.simpleMessage("Network speed"),
    "networkType": MessageLookupByLibrary.simpleMessage("Network type"),
    "neutralScheme": MessageLookupByLibrary.simpleMessage("Neutral"),
    "noData": MessageLookupByLibrary.simpleMessage("No data"),
    "noHotKey": MessageLookupByLibrary.simpleMessage("No HotKey"),
    "noInfo": MessageLookupByLibrary.simpleMessage("No info"),
    "noLocalProxy": MessageLookupByLibrary.simpleMessage("No local proxies"),
    "noLongerRemind": MessageLookupByLibrary.simpleMessage(
      "Don\'t remind again",
    ),
    "noNetwork": MessageLookupByLibrary.simpleMessage("No network"),
    "noNetworkApp": MessageLookupByLibrary.simpleMessage("No network APP"),
    "noProxyGroups": MessageLookupByLibrary.simpleMessage(
      "No proxy groups in current config",
    ),
    "noRecords": MessageLookupByLibrary.simpleMessage("No records"),
    "noResolve": MessageLookupByLibrary.simpleMessage("No resolve IP"),
    "noResolveHostname": MessageLookupByLibrary.simpleMessage(
      "No resolve hostname",
    ),
    "none": MessageLookupByLibrary.simpleMessage("none"),
    "notSelectedTip": MessageLookupByLibrary.simpleMessage(
      "The current proxy group cannot be selected.",
    ),
    "nowhere": MessageLookupByLibrary.simpleMessage("Nowhere"),
    "nullProfileDesc": MessageLookupByLibrary.simpleMessage(
      "No profile, Please add a profile",
    ),
    "nullTip": m17,
    "numberTip": m18,
    "obfs": MessageLookupByLibrary.simpleMessage("Obfs"),
    "obfsPassword": MessageLookupByLibrary.simpleMessage("Obfs password"),
    "onDemand": MessageLookupByLibrary.simpleMessage("On Demand"),
    "onDemandDesc": MessageLookupByLibrary.simpleMessage(
      "Configure the program running state for specific scenarios",
    ),
    "onlyIcon": MessageLookupByLibrary.simpleMessage("Icon"),
    "onlyStatisticsProxy": MessageLookupByLibrary.simpleMessage(
      "Only statistics proxy",
    ),
    "onlyStatisticsProxyDesc": MessageLookupByLibrary.simpleMessage(
      "When turned on, only statistics proxy traffic",
    ),
    "optional": MessageLookupByLibrary.simpleMessage("Optional"),
    "options": MessageLookupByLibrary.simpleMessage("Options"),
    "other": MessageLookupByLibrary.simpleMessage("Other"),
    "otherContributors": MessageLookupByLibrary.simpleMessage(
      "Other contributors",
    ),
    "outboundMode": MessageLookupByLibrary.simpleMessage("Outbound mode"),
    "override": MessageLookupByLibrary.simpleMessage("Override"),
    "overrideDns": MessageLookupByLibrary.simpleMessage("Override Dns"),
    "overrideDnsDesc": MessageLookupByLibrary.simpleMessage(
      "Turning it on will override the DNS options in the profile",
    ),
    "overrideMode": MessageLookupByLibrary.simpleMessage("Override mode"),
    "overrideScript": MessageLookupByLibrary.simpleMessage("Override script"),
    "overwriteTypeCustom": MessageLookupByLibrary.simpleMessage("Custom"),
    "overwriteTypeCustomDesc": MessageLookupByLibrary.simpleMessage(
      "Custom mode, fully customize proxy groups and rules",
    ),
    "palette": MessageLookupByLibrary.simpleMessage("Palette"),
    "parse": MessageLookupByLibrary.simpleMessage("Parse"),
    "parseFailed": MessageLookupByLibrary.simpleMessage("Parse failed"),
    "parseResult": m19,
    "password": MessageLookupByLibrary.simpleMessage("Password"),
    "paste": MessageLookupByLibrary.simpleMessage("Paste"),
    "pasteNodeLinkHint": MessageLookupByLibrary.simpleMessage(
      "One node link per line",
    ),
    "pasteShareLink": MessageLookupByLibrary.simpleMessage("Paste share link"),
    "pleaseBindWebDAV": MessageLookupByLibrary.simpleMessage(
      "Please bind WebDAV",
    ),
    "pleaseEnterScriptName": MessageLookupByLibrary.simpleMessage(
      "Please enter a script name",
    ),
    "pleaseInputAdminPassword": MessageLookupByLibrary.simpleMessage(
      "Please enter the admin password",
    ),
    "pleaseUploadValidQrcode": MessageLookupByLibrary.simpleMessage(
      "Please upload a valid QR code",
    ),
    "pool": MessageLookupByLibrary.simpleMessage("Pool"),
    "port": MessageLookupByLibrary.simpleMessage("Port"),
    "portConflictTip": MessageLookupByLibrary.simpleMessage(
      "Please enter a different port",
    ),
    "portTip": m20,
    "preferH3Desc": MessageLookupByLibrary.simpleMessage(
      "Prioritize the use of DOH\'s http/3",
    ),
    "prerequisites": MessageLookupByLibrary.simpleMessage("Prerequisites"),
    "pressKeyboard": MessageLookupByLibrary.simpleMessage(
      "Please press the keyboard.",
    ),
    "preview": MessageLookupByLibrary.simpleMessage("Preview"),
    "privateKey": MessageLookupByLibrary.simpleMessage("Private key"),
    "process": MessageLookupByLibrary.simpleMessage("Process"),
    "profile": MessageLookupByLibrary.simpleMessage("Profile"),
    "profileAutoUpdateIntervalInvalidValidationDesc":
        MessageLookupByLibrary.simpleMessage(
          "Please input a valid interval time format",
        ),
    "profileAutoUpdateIntervalNullValidationDesc":
        MessageLookupByLibrary.simpleMessage(
          "Please enter the auto update interval time",
        ),
    "profileHasUpdate": MessageLookupByLibrary.simpleMessage(
      "The profile has been modified. Do you want to disable auto update?",
    ),
    "profileNameNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Please input the profile name",
    ),
    "profileUrlInvalidValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Please input a valid profile URL",
    ),
    "profileUrlNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Please input the profile URL",
    ),
    "profiles": MessageLookupByLibrary.simpleMessage("Profiles"),
    "profilesSort": MessageLookupByLibrary.simpleMessage("Profiles sort"),
    "project": MessageLookupByLibrary.simpleMessage("Project"),
    "protocolAuth": MessageLookupByLibrary.simpleMessage(
      "Protocol authentication",
    ),
    "providerInfo": MessageLookupByLibrary.simpleMessage("Provider"),
    "providerName": MessageLookupByLibrary.simpleMessage("Provider name"),
    "providerType": MessageLookupByLibrary.simpleMessage("Provider type"),
    "providers": MessageLookupByLibrary.simpleMessage("Providers"),
    "proxies": MessageLookupByLibrary.simpleMessage("Proxies"),
    "proxiesEmpty": MessageLookupByLibrary.simpleMessage("Proxies is empty"),
    "proxy": MessageLookupByLibrary.simpleMessage("Proxy"),
    "proxyChains": MessageLookupByLibrary.simpleMessage("Proxy chains"),
    "proxyDetectedAbnormal": MessageLookupByLibrary.simpleMessage(
      "Detected selected proxies are abnormal",
    ),
    "proxyFilter": MessageLookupByLibrary.simpleMessage("Proxy filter"),
    "proxyGroup": MessageLookupByLibrary.simpleMessage("Proxy group"),
    "proxyGroupDetectedAbnormal": MessageLookupByLibrary.simpleMessage(
      "Detected current proxy group is abnormal",
    ),
    "proxyGroupEmpty": MessageLookupByLibrary.simpleMessage(
      "Proxy group is empty",
    ),
    "proxyGroupNameDuplicate": MessageLookupByLibrary.simpleMessage(
      "Proxy group name is duplicate",
    ),
    "proxyGroupNameEmpty": MessageLookupByLibrary.simpleMessage(
      "Proxy group name cannot be empty",
    ),
    "proxyNameserver": MessageLookupByLibrary.simpleMessage("Proxy nameserver"),
    "proxyNameserverDesc": MessageLookupByLibrary.simpleMessage(
      "Domain for resolving proxy nodes",
    ),
    "proxyPort": MessageLookupByLibrary.simpleMessage("ProxyPort"),
    "proxyProviderDetectedAbnormal": MessageLookupByLibrary.simpleMessage(
      "Detected selected proxy providers are abnormal",
    ),
    "proxyProviders": MessageLookupByLibrary.simpleMessage("Proxy providers"),
    "proxyProvidersEmpty": MessageLookupByLibrary.simpleMessage(
      "Proxy providers is empty",
    ),
    "proxyProvidersNotEmpty": MessageLookupByLibrary.simpleMessage(
      "Proxy providers cannot be empty",
    ),
    "proxyType": MessageLookupByLibrary.simpleMessage("Proxy type"),
    "pruneCache": MessageLookupByLibrary.simpleMessage("Prune cache"),
    "pureBlackMode": MessageLookupByLibrary.simpleMessage("Pure black mode"),
    "qrcode": MessageLookupByLibrary.simpleMessage("QR code"),
    "qrcodeDesc": MessageLookupByLibrary.simpleMessage(
      "Scan QR code to obtain profile",
    ),
    "quickFill": MessageLookupByLibrary.simpleMessage("Quick fill"),
    "rainbowScheme": MessageLookupByLibrary.simpleMessage("Rainbow"),
    "reason": MessageLookupByLibrary.simpleMessage("Reason"),
    "redirPort": MessageLookupByLibrary.simpleMessage("Redir Port"),
    "redo": MessageLookupByLibrary.simpleMessage("redo"),
    "reduceRtt": MessageLookupByLibrary.simpleMessage("Reduce RTT"),
    "remote": MessageLookupByLibrary.simpleMessage("Remote"),
    "remoteBackupDesc": MessageLookupByLibrary.simpleMessage(
      "Backup local data to WebDAV",
    ),
    "remoteDestination": MessageLookupByLibrary.simpleMessage(
      "Remote destination",
    ),
    "remove": MessageLookupByLibrary.simpleMessage("Remove"),
    "rename": MessageLookupByLibrary.simpleMessage("Rename"),
    "request": MessageLookupByLibrary.simpleMessage("Request"),
    "requests": MessageLookupByLibrary.simpleMessage("Requests"),
    "requestsDesc": MessageLookupByLibrary.simpleMessage(
      "View recently request records",
    ),
    "reset": MessageLookupByLibrary.simpleMessage("Reset"),
    "resetPageChangesTip": MessageLookupByLibrary.simpleMessage(
      "The current page has changes. Are you sure you want to reset?",
    ),
    "resetTip": MessageLookupByLibrary.simpleMessage("Make sure to reset"),
    "resources": MessageLookupByLibrary.simpleMessage("Resources"),
    "resourcesDesc": MessageLookupByLibrary.simpleMessage(
      "External resource related info",
    ),
    "respectRules": MessageLookupByLibrary.simpleMessage("Respect rules"),
    "respectRulesDesc": MessageLookupByLibrary.simpleMessage(
      "DNS connection following rules, need to configure proxy-server-nameserver",
    ),
    "restart": MessageLookupByLibrary.simpleMessage("Restart"),
    "restartCoreTip": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to restart the core?",
    ),
    "restore": MessageLookupByLibrary.simpleMessage("Restore"),
    "restoreAllData": MessageLookupByLibrary.simpleMessage("Restore all data"),
    "restoreException": MessageLookupByLibrary.simpleMessage(
      "Recovery exception",
    ),
    "restoreFromFileDesc": MessageLookupByLibrary.simpleMessage(
      "Restore data via file",
    ),
    "restoreFromWebDAVDesc": MessageLookupByLibrary.simpleMessage(
      "Restore data via WebDAV",
    ),
    "restoreOnlyConfig": MessageLookupByLibrary.simpleMessage(
      "Restore configuration files only",
    ),
    "restoreStrategy": MessageLookupByLibrary.simpleMessage("Restore strategy"),
    "restoreStrategy_compatible": MessageLookupByLibrary.simpleMessage(
      "Compatible",
    ),
    "restoreStrategy_override": MessageLookupByLibrary.simpleMessage(
      "Override",
    ),
    "restoreSuccess": MessageLookupByLibrary.simpleMessage("Restore success"),
    "routeAddress": MessageLookupByLibrary.simpleMessage("Route address"),
    "routeAddressDesc": MessageLookupByLibrary.simpleMessage(
      "Config listen route address",
    ),
    "routeMode": MessageLookupByLibrary.simpleMessage("Route mode"),
    "routeMode_bypassPrivate": MessageLookupByLibrary.simpleMessage(
      "Bypass private route address",
    ),
    "routeMode_config": MessageLookupByLibrary.simpleMessage("Use config"),
    "ru": MessageLookupByLibrary.simpleMessage("Russian"),
    "rule": MessageLookupByLibrary.simpleMessage("Rule"),
    "ruleActionAndDesc": MessageLookupByLibrary.simpleMessage(
      "Logical rule AND",
    ),
    "ruleActionDomainDesc": MessageLookupByLibrary.simpleMessage(
      "Match full domain",
    ),
    "ruleActionDomainKeywordDesc": MessageLookupByLibrary.simpleMessage(
      "Match domain keyword",
    ),
    "ruleActionDomainRegexDesc": MessageLookupByLibrary.simpleMessage(
      "Wildcard match, only supports * and ? wildcards",
    ),
    "ruleActionDomainSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "Match domain suffix",
    ),
    "ruleActionDscpDesc": MessageLookupByLibrary.simpleMessage(
      "Match DSCP mark (tproxy udp inbound only)",
    ),
    "ruleActionDstPortDesc": MessageLookupByLibrary.simpleMessage(
      "Match request target port range",
    ),
    "ruleActionGeoipDesc": MessageLookupByLibrary.simpleMessage(
      "Match IP\'s country code",
    ),
    "ruleActionGeositeDesc": MessageLookupByLibrary.simpleMessage(
      "Match domains within Geosite",
    ),
    "ruleActionInNameDesc": MessageLookupByLibrary.simpleMessage(
      "Match inbound name",
    ),
    "ruleActionInPortDesc": MessageLookupByLibrary.simpleMessage(
      "Match inbound port",
    ),
    "ruleActionInTypeDesc": MessageLookupByLibrary.simpleMessage(
      "Match inbound type",
    ),
    "ruleActionInUserDesc": MessageLookupByLibrary.simpleMessage(
      "Match inbound username, supports multiple usernames separated by /",
    ),
    "ruleActionIpAsnDesc": MessageLookupByLibrary.simpleMessage(
      "Match IP\'s ASN",
    ),
    "ruleActionIpCidr6Desc": MessageLookupByLibrary.simpleMessage(
      "Match IP address range, IP-CIDR6 is just an alias",
    ),
    "ruleActionIpCidrDesc": MessageLookupByLibrary.simpleMessage(
      "Match IP address range",
    ),
    "ruleActionIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "Match IP suffix range",
    ),
    "ruleActionMatchDesc": MessageLookupByLibrary.simpleMessage(
      "Match all requests, no conditions needed",
    ),
    "ruleActionNetworkDesc": MessageLookupByLibrary.simpleMessage(
      "Match TCP or UDP",
    ),
    "ruleActionNotDesc": MessageLookupByLibrary.simpleMessage(
      "Logical rule NOT",
    ),
    "ruleActionOrDesc": MessageLookupByLibrary.simpleMessage("Logical rule OR"),
    "ruleActionProcessNameDesc": MessageLookupByLibrary.simpleMessage(
      "Match using process name, matches package name on Android",
    ),
    "ruleActionProcessNameRegexDesc": MessageLookupByLibrary.simpleMessage(
      "Match using process name regex, matches package name on Android",
    ),
    "ruleActionProcessPathDesc": MessageLookupByLibrary.simpleMessage(
      "Match using full process path",
    ),
    "ruleActionProcessPathRegexDesc": MessageLookupByLibrary.simpleMessage(
      "Match using process path regex",
    ),
    "ruleActionRuleSetDesc": MessageLookupByLibrary.simpleMessage(
      "Reference rule set, requires rule-providers configuration",
    ),
    "ruleActionSrcGeoipDesc": MessageLookupByLibrary.simpleMessage(
      "Match source IP\'s country code",
    ),
    "ruleActionSrcIpAsnDesc": MessageLookupByLibrary.simpleMessage(
      "Match source IP\'s ASN",
    ),
    "ruleActionSrcIpCidrDesc": MessageLookupByLibrary.simpleMessage(
      "Match source IP address range",
    ),
    "ruleActionSrcIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "Match source IP suffix range",
    ),
    "ruleActionSrcPortDesc": MessageLookupByLibrary.simpleMessage(
      "Match request source port range",
    ),
    "ruleActionSubRuleDesc": MessageLookupByLibrary.simpleMessage(
      "Match to sub-rule, pay attention to the use of parentheses",
    ),
    "ruleActionUidDesc": MessageLookupByLibrary.simpleMessage(
      "Match Linux USER ID",
    ),
    "ruleEmpty": MessageLookupByLibrary.simpleMessage("Rule is empty"),
    "ruleName": MessageLookupByLibrary.simpleMessage("Rule name"),
    "ruleProviders": MessageLookupByLibrary.simpleMessage("Rule providers"),
    "ruleSet": MessageLookupByLibrary.simpleMessage("Rule set"),
    "ruleTarget": MessageLookupByLibrary.simpleMessage("Rule target"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "saveAndReload": MessageLookupByLibrary.simpleMessage("Save and reload"),
    "saveChanges": MessageLookupByLibrary.simpleMessage(
      "Do you want to save the changes?",
    ),
    "script": MessageLookupByLibrary.simpleMessage("Script"),
    "scriptModeDesc": MessageLookupByLibrary.simpleMessage(
      "Script mode, use external extension scripts, provide one-click override configuration capability",
    ),
    "search": MessageLookupByLibrary.simpleMessage("Search"),
    "searchLocalProxy": MessageLookupByLibrary.simpleMessage(
      "Search name / protocol / server",
    ),
    "seconds": MessageLookupByLibrary.simpleMessage("Seconds"),
    "selectAll": MessageLookupByLibrary.simpleMessage("Select all"),
    "selectProxies": MessageLookupByLibrary.simpleMessage("Select proxies"),
    "selectProxyProviders": MessageLookupByLibrary.simpleMessage(
      "Select proxy providers",
    ),
    "selectRuleSet": MessageLookupByLibrary.simpleMessage(
      "Please select rule set",
    ),
    "selectSplitStrategy": MessageLookupByLibrary.simpleMessage(
      "Please select split strategy",
    ),
    "selectSubRule": MessageLookupByLibrary.simpleMessage(
      "Please select sub rule",
    ),
    "selectTargetGroups": MessageLookupByLibrary.simpleMessage(
      "Select target proxy groups",
    ),
    "selected": MessageLookupByLibrary.simpleMessage("Selected"),
    "selectedCountTitle": m21,
    "server": MessageLookupByLibrary.simpleMessage("Server"),
    "servername": MessageLookupByLibrary.simpleMessage("Server Name"),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "show": MessageLookupByLibrary.simpleMessage("Show"),
    "shrink": MessageLookupByLibrary.simpleMessage("Shrink"),
    "silentLaunch": MessageLookupByLibrary.simpleMessage("SilentLaunch"),
    "silentLaunchDesc": MessageLookupByLibrary.simpleMessage(
      "Start in the background",
    ),
    "size": MessageLookupByLibrary.simpleMessage("Size"),
    "skipCertVerify": MessageLookupByLibrary.simpleMessage("Skip cert verify"),
    "sni": MessageLookupByLibrary.simpleMessage("SNI"),
    "socksPort": MessageLookupByLibrary.simpleMessage("Socks Port"),
    "sort": MessageLookupByLibrary.simpleMessage("Sort"),
    "source": MessageLookupByLibrary.simpleMessage("Source"),
    "sourceIp": MessageLookupByLibrary.simpleMessage("Source IP"),
    "spec": MessageLookupByLibrary.simpleMessage("Spec"),
    "specialProxy": MessageLookupByLibrary.simpleMessage("Special proxy"),
    "specialRules": MessageLookupByLibrary.simpleMessage("special rules"),
    "speedStatistics": MessageLookupByLibrary.simpleMessage("Speed statistics"),
    "splitStrategy": MessageLookupByLibrary.simpleMessage("Split strategy"),
    "splitStrategyNotEmpty": MessageLookupByLibrary.simpleMessage(
      "Split strategy cannot be empty",
    ),
    "ss": MessageLookupByLibrary.simpleMessage("Shadowsocks"),
    "ssidsEmpty": MessageLookupByLibrary.simpleMessage("SSIDs is empty"),
    "stackMode": MessageLookupByLibrary.simpleMessage("Stack mode"),
    "standard": MessageLookupByLibrary.simpleMessage("Standard"),
    "standardModeDesc": MessageLookupByLibrary.simpleMessage(
      "Standard mode, override basic configuration, provide simple rule addition capability",
    ),
    "start": MessageLookupByLibrary.simpleMessage("Start"),
    "startSetup": MessageLookupByLibrary.simpleMessage("Start Setup"),
    "startVpn": MessageLookupByLibrary.simpleMessage("Starting VPN..."),
    "status": MessageLookupByLibrary.simpleMessage("Status"),
    "statusDesc": MessageLookupByLibrary.simpleMessage(
      "System DNS will be used when turned off",
    ),
    "stop": MessageLookupByLibrary.simpleMessage("Stop"),
    "stopVpn": MessageLookupByLibrary.simpleMessage("Stopping VPN..."),
    "style": MessageLookupByLibrary.simpleMessage("Style"),
    "subRule": MessageLookupByLibrary.simpleMessage("Sub rule"),
    "subRuleEmpty": MessageLookupByLibrary.simpleMessage("Sub rule is empty"),
    "subRuleNotEmpty": MessageLookupByLibrary.simpleMessage(
      "Sub rule cannot be empty",
    ),
    "submit": MessageLookupByLibrary.simpleMessage("Submit"),
    "supportedProtocols": MessageLookupByLibrary.simpleMessage(
      "Supported protocols",
    ),
    "suspended": MessageLookupByLibrary.simpleMessage("Suspended..."),
    "sync": MessageLookupByLibrary.simpleMessage("Sync"),
    "system": MessageLookupByLibrary.simpleMessage("System"),
    "systemApp": MessageLookupByLibrary.simpleMessage("System APP"),
    "systemProxy": MessageLookupByLibrary.simpleMessage("System proxy"),
    "systemProxyDesc": MessageLookupByLibrary.simpleMessage(
      "Attach HTTP proxy to VpnService",
    ),
    "tab": MessageLookupByLibrary.simpleMessage("Tab"),
    "tabAnimation": MessageLookupByLibrary.simpleMessage("Tab animation"),
    "tabAnimationDesc": MessageLookupByLibrary.simpleMessage(
      "Effective only in mobile view",
    ),
    "tapToAuthorize": MessageLookupByLibrary.simpleMessage("Tap to authorize"),
    "tcpConcurrent": MessageLookupByLibrary.simpleMessage("TCP concurrent"),
    "tcpConcurrentDesc": MessageLookupByLibrary.simpleMessage(
      "Enabling it will allow TCP concurrency",
    ),
    "testInterval": MessageLookupByLibrary.simpleMessage("Test interval"),
    "testUrl": MessageLookupByLibrary.simpleMessage("Test url"),
    "testWhenUsed": MessageLookupByLibrary.simpleMessage("Test when used"),
    "textScale": MessageLookupByLibrary.simpleMessage("Text Scaling"),
    "theme": MessageLookupByLibrary.simpleMessage("Theme"),
    "themeColor": MessageLookupByLibrary.simpleMessage("Theme color"),
    "themeDesc": MessageLookupByLibrary.simpleMessage(
      "Set dark mode,adjust the color",
    ),
    "themeMode": MessageLookupByLibrary.simpleMessage("Theme mode"),
    "tight": MessageLookupByLibrary.simpleMessage("Tight"),
    "time": MessageLookupByLibrary.simpleMessage("Time"),
    "timeout": MessageLookupByLibrary.simpleMessage("Timeout"),
    "tip": MessageLookupByLibrary.simpleMessage("tip"),
    "tls": MessageLookupByLibrary.simpleMessage("TLS"),
    "toggle": MessageLookupByLibrary.simpleMessage("Toggle"),
    "tonalSpotScheme": MessageLookupByLibrary.simpleMessage("TonalSpot"),
    "tools": MessageLookupByLibrary.simpleMessage("Tools"),
    "tproxyPort": MessageLookupByLibrary.simpleMessage("Tproxy Port"),
    "trafficUsage": MessageLookupByLibrary.simpleMessage("Traffic usage"),
    "transportSettings": MessageLookupByLibrary.simpleMessage(
      "Transport settings",
    ),
    "trojan": MessageLookupByLibrary.simpleMessage("Trojan"),
    "tun": MessageLookupByLibrary.simpleMessage("TUN"),
    "tunDesc": MessageLookupByLibrary.simpleMessage(
      "only effective in administrator mode",
    ),
    "turnOff": MessageLookupByLibrary.simpleMessage("Turn Off"),
    "turnOn": MessageLookupByLibrary.simpleMessage("Turn On"),
    "udp": MessageLookupByLibrary.simpleMessage("UDP"),
    "undo": MessageLookupByLibrary.simpleMessage("undo"),
    "unifiedDelay": MessageLookupByLibrary.simpleMessage("Unified delay"),
    "unifiedDelayDesc": MessageLookupByLibrary.simpleMessage(
      "Remove extra delays such as handshaking",
    ),
    "unknown": MessageLookupByLibrary.simpleMessage("Unknown"),
    "unknownNetworkError": MessageLookupByLibrary.simpleMessage(
      "Unknown network error",
    ),
    "unnamed": MessageLookupByLibrary.simpleMessage("Unnamed"),
    "up": MessageLookupByLibrary.simpleMessage("Up"),
    "update": MessageLookupByLibrary.simpleMessage("Update"),
    "upload": MessageLookupByLibrary.simpleMessage("Upload"),
    "url": MessageLookupByLibrary.simpleMessage("URL"),
    "urlDesc": MessageLookupByLibrary.simpleMessage(
      "Obtain profile through URL",
    ),
    "urlTip": m22,
    "useHosts": MessageLookupByLibrary.simpleMessage("Use hosts"),
    "useSystemHosts": MessageLookupByLibrary.simpleMessage("Use system hosts"),
    "uuid": MessageLookupByLibrary.simpleMessage("UUID"),
    "value": MessageLookupByLibrary.simpleMessage("Value"),
    "vibrantScheme": MessageLookupByLibrary.simpleMessage("Vibrant"),
    "view": MessageLookupByLibrary.simpleMessage("View"),
    "vless": MessageLookupByLibrary.simpleMessage("VLESS"),
    "vpnConfigChangeDetected": MessageLookupByLibrary.simpleMessage(
      "VPN configuration change detected",
    ),
    "vpnEnableDesc": MessageLookupByLibrary.simpleMessage(
      "Auto routes all system traffic through VpnService",
    ),
    "vpnTip": MessageLookupByLibrary.simpleMessage(
      "Changes take effect after restarting the VPN",
    ),
    "webDAVConfiguration": MessageLookupByLibrary.simpleMessage(
      "WebDAV configuration",
    ),
    "whitelistMode": MessageLookupByLibrary.simpleMessage("Whitelist mode"),
    "wifiWatchExcluded": MessageLookupByLibrary.simpleMessage("Excluded"),
    "wifiWatchExcludedInactive": MessageLookupByLibrary.simpleMessage(
      "Excluded (inactive)",
    ),
    "wifiWatchExcludedWillSuspend": m23,
    "wifiWatchListening": MessageLookupByLibrary.simpleMessage("Watching..."),
    "wifiWatchNoWifi": MessageLookupByLibrary.simpleMessage("No WiFi"),
    "wifiWatchResolving": MessageLookupByLibrary.simpleMessage(
      "Resolving SSID...",
    ),
    "wifiWatchSignal": m24,
    "wifiWatchSuspendingNow": MessageLookupByLibrary.simpleMessage(
      "Suspending...",
    ),
    "wifiWatchTitle": MessageLookupByLibrary.simpleMessage("On Demand"),
    "wifiWatchTrusted": MessageLookupByLibrary.simpleMessage("Trusted network"),
    "wifiWatchWillSuspend": m25,
    "yearsAgo": m26,
    "zh_CN": MessageLookupByLibrary.simpleMessage("Simplified Chinese"),
  };
}
