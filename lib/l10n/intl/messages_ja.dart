// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ja locale. All the
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
  String get localeName => 'ja';

  static String m0(count, skipped) => "${count}件を追加、${skipped}件は既存のためスキップ";

  static String m1(detail) => "データを消去できませんでした：${detail}";

  static String m2(code) =>
      "Windows が FlClashCore.exe の実行を拒否しました（エラー ${code}）。スマート アプリ コントロールや AppLocker などのアプリ制御ポリシーは未署名のプログラムをブロックします。ポリシーで FlClash を許可するか、ポリシーを無効にしてから再試行してください。";

  static String m3(name) =>
      "アプリの起動が2回連続で完了しませんでした。クラッシュループを断ち切るため、プロファイル ${name} の選択を解除し、今回の自動セットアップをスキップしました。いつでも選択し直せます。";

  static String m4(url) => "${url} からプロファイルを作成しますか？";

  static String m5(message) => "コアがこのプロキシを解析できません：${message}";

  static String m6(proxy, target) =>
      "${proxy} は ${target} 経由で接続しますが、${target} から再び ${proxy} に戻るため、ループになります";

  static String m7(name) => "名前 ${name} は他のプロキシまたはプロキシグループで使用されています";

  static String m8(path) => "プロキシグループが循環参照しています：${path}";

  static String m9(name) =>
      "空グループのフォールバックはプロキシである必要がありますが、${name} は存在しないかプロキシグループです";

  static String m10(name, message) => "${name}は有効な正規表現ではありません：${message}";

  static String m11(name) => "ダイヤラープロキシ ${name} が存在しません";

  static String m12(names) => "次のプロキシプロバイダーは存在しません：${names}";

  static String m13(names) => "次のプロキシまたはポリシーは存在しません：${names}";

  static String m14(name) => "${name} は組み込みポリシー名のため使用できません";

  static String m15(count) => "${count} 件に問題があり、プロファイルの適用に失敗する可能性があります";

  static String m16(count) => "${count} 日前";

  static String m17(count) => "${count} 日前";

  static String m18(label) => "選択した${label}を削除してもよろしいですか？";

  static String m19(label) => "この${label}を削除してもよろしいですか？";

  static String m20(label) => "${label}の詳細";

  static String m21(name) => "${name} 経由の接続が使用元のプロキシに戻るため、接続を中止しました";

  static String m22(label) => "${label}は空にできません";

  static String m23(label) => "${label}はすでに存在します";

  static String m24(count) => "${count} 件が失敗しました";

  static String m25(label, message) => "${label}：${message}";

  static String m26(name) => "${name} はすでに最新です";

  static String m27(name) => "${name} を更新しました";

  static String m28(action) => "「${action}」で使用中です。保存するとこちらに移動します。";

  static String m29(modifiers) => "${modifiers} のいずれかを含めてください";

  static String m30(count) => "${count} 時間前";

  static String m31(count) => "${count} 時間前";

  static String m32(count) => "${count} 時間";

  static String m33(target) => "${target} は無効なポリシーです";

  static String m34(proxyName) => "${proxyName} は無効なプロキシです";

  static String m35(providerName) => "${providerName} は無効なプロキシプロバイダーです";

  static String m36(ruleSet) => "${ruleSet} は無効なルールセットです";

  static String m37(subRule) => "${subRule} は無効な SUB_RULE です";

  static String m38(count) => "${count} 件";

  static String m39(line, message) => "${line}行目：${message}";

  static String m40(groups) => "対象グループ ${groups} が存在しません。再選択してください。";

  static String m41(total, enabled, groups) =>
      "${total} ノード · ${enabled} 有効 · グループ：${groups}";

  static String m42(total, enabled) => "${total} ノード · ${enabled} 有効";

  static String m43(total, enabled) => "${total} ルール · ${enabled} 有効";

  static String m44(total, enabled, skipped) =>
      "${total} ルール · ${enabled} 有効 · このサブスクリプションでは ${skipped} 件をスキップ";

  static String m45(appName) =>
      "1. システム設定 > プライバシーとセキュリティ を開く\n2. 位置情報サービス を選択\n3. リストで ${appName} を見つけてチェックを入れる\n\n設定が完了したらアプリに戻ると、通常どおり使用できます。ご協力ありがとうございます。";

  static String m46(label, max) => "${label}は最大${max}文字です";

  static String m47(size) => "${size} を解放しました";

  static String m48(count) => "${count} 分前";

  static String m49(count) => "${count} 分前";

  static String m50(count) => "${count} か月前";

  static String m51(count) => "${count} か月前";

  static String m52(code) =>
      "サーバーがアクセスを拒否しました（HTTP ${code}）。リンクの期限切れか、認証情報が誤っている可能性があります";

  static String m53(code) => "サーバーがリクエストを拒否しました（HTTP ${code}）";

  static String m54(code) =>
      "このアドレスには何も見つかりませんでした（HTTP ${code}）。URL が正しいか確認してください";

  static String m55(detail) => "ネットワークリクエストに失敗しました：${detail}";

  static String m56(code) => "サーバーで問題が発生しました（HTTP ${code}）。しばらくしてから再試行してください";

  static String m57(label) => "${label}はまだありません";

  static String m58(label, min, max) => "${label}は${min}から${max}の範囲で指定してください";

  static String m59(label) => "${label}は数値である必要があります";

  static String m60(valid, invalid) => "${valid} 件利用可能、${invalid} 件失敗";

  static String m61(label) => "${label} は 1024〜49151 の範囲で指定してください";

  static String m62(label, profiles) =>
      "${label} は ${profiles} でまだ使用されており、削除するとそれらが正常に動作しなくなります。削除してもよろしいですか？";

  static String m63(count, label) =>
      "${Intl.plural(count, other: 'プロキシ ${label} 件')}";

  static String m64(name, count) => "${name} など${count}件のプロキシ";

  static String m65(removed) =>
      "次のプロキシが削除されます：${removed}。名前を変えた行は新しいプロキシとして扱われ、削除されたプロキシを参照するカスタムプロファイルでは見つからないと表示されます。適用しますか？";

  static String m66(removed, added) =>
      "次のプロキシが削除されます：${removed}。次のプロキシが追加されます：${added}。名前を変えた行は新しいプロキシとして扱われ、削除されたプロキシを参照するカスタムプロファイルでは見つからないと表示されます。適用しますか？";

  static String m67(label) =>
      "${label} はこのプロファイルのルール、プロキシグループ、ダイヤラープロキシ、DNS または NTP からまだ参照されており、削除するとそれらの参照は無効になります。削除してもよろしいですか？";

  static String m68(count, label) =>
      "${Intl.plural(count, other: 'ルール ${label} 件')}";

  static String m69(appName) => "${appName}（セーフモード）";

  static String m70(count) => "${count} 秒";

  static String m71(count) => "${count} 件が有効";

  static String m72(count) => "${count} 件選択中";

  static String m73(time) => "${time} に検査";

  static String m74(count) => "設定 ${count} 件";

  static String m75(link) => "${link} からプロキシを読み取れませんでした";

  static String m76(label) => "${label}は1項目のみ指定できます";

  static String m77(label) => "${label}はURLである必要があります";

  static String m78(seconds) => "${seconds}秒後に一時停止";

  static String m79(seconds) => "Suspend in ${seconds}s";

  static String m80(count) => "${count} 年前";

  static String m81(count) => "${count} 年前";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("アプリについて"),
    "acceptDns": MessageLookupByLibrary.simpleMessage("DNS を受け入れる"),
    "accessControl": MessageLookupByLibrary.simpleMessage("アクセス制御"),
    "accessControlAllowDesc": MessageLookupByLibrary.simpleMessage(
      "選択したアプリのみVPNを経由します",
    ),
    "accessControlDesc": MessageLookupByLibrary.simpleMessage(
      "プロキシを利用するアプリを設定します",
    ),
    "accessControlDisabledDesc": MessageLookupByLibrary.simpleMessage(
      "アプリアクセス制御は無効です",
    ),
    "accessControlNotAllowDesc": MessageLookupByLibrary.simpleMessage(
      "選択したアプリはVPNから除外されます",
    ),
    "accessControlSettings": MessageLookupByLibrary.simpleMessage("アクセス制御の設定"),
    "account": MessageLookupByLibrary.simpleMessage("アカウント"),
    "action": MessageLookupByLibrary.simpleMessage("アクション"),
    "actionDelayTest": MessageLookupByLibrary.simpleMessage("すべての遅延をテスト"),
    "actionDirectMode": MessageLookupByLibrary.simpleMessage("ダイレクトモード"),
    "actionGlobalMode": MessageLookupByLibrary.simpleMessage("グローバルモード"),
    "actionMode": MessageLookupByLibrary.simpleMessage("モード切替"),
    "actionProxy": MessageLookupByLibrary.simpleMessage("システムプロキシ"),
    "actionRuleMode": MessageLookupByLibrary.simpleMessage("ルールモード"),
    "actionStart": MessageLookupByLibrary.simpleMessage("開始/停止"),
    "actionTun": MessageLookupByLibrary.simpleMessage("TUN"),
    "actionUpdateProfiles": MessageLookupByLibrary.simpleMessage("プロファイルを更新"),
    "actionView": MessageLookupByLibrary.simpleMessage("表示/非表示"),
    "add": MessageLookupByLibrary.simpleMessage("追加"),
    "addCustomProxy": MessageLookupByLibrary.simpleMessage("プロキシを追加"),
    "addFilters": MessageLookupByLibrary.simpleMessage("フィルターを追加"),
    "addLocalProxy": MessageLookupByLibrary.simpleMessage("ローカルプロキシを追加"),
    "addLocalRule": MessageLookupByLibrary.simpleMessage("ローカルルールを追加"),
    "addNodes": MessageLookupByLibrary.simpleMessage("ノードを追加"),
    "addOverrideEntry": MessageLookupByLibrary.simpleMessage("上書き項目を追加"),
    "addProfile": MessageLookupByLibrary.simpleMessage("プロファイルを追加"),
    "addProxyGroup": MessageLookupByLibrary.simpleMessage("プロキシグループを追加"),
    "addProxyProviders": MessageLookupByLibrary.simpleMessage("プロキシプロバイダーを追加"),
    "addRule": MessageLookupByLibrary.simpleMessage("ルールを追加"),
    "addSettingEntry": MessageLookupByLibrary.simpleMessage("設定項目を追加"),
    "addSsid": MessageLookupByLibrary.simpleMessage("SSIDを追加"),
    "addWidget": MessageLookupByLibrary.simpleMessage("ウィジェットを追加"),
    "addedRules": MessageLookupByLibrary.simpleMessage("追加ルール"),
    "additionalParameters": MessageLookupByLibrary.simpleMessage("追加パラメータ"),
    "additionalPrefix": MessageLookupByLibrary.simpleMessage("名前のプレフィックス"),
    "additionalSuffix": MessageLookupByLibrary.simpleMessage("名前のサフィックス"),
    "address": MessageLookupByLibrary.simpleMessage("アドレス"),
    "addressHelp": MessageLookupByLibrary.simpleMessage("WebDAVサーバーのアドレス"),
    "addressTip": MessageLookupByLibrary.simpleMessage(
      "有効なWebDAVアドレスを入力してください",
    ),
    "advancedConfig": MessageLookupByLibrary.simpleMessage("詳細設定"),
    "advancedConfigDesc": MessageLookupByLibrary.simpleMessage(
      "ネットワーク、DNS、追加ルール、スクリプト",
    ),
    "advancedSettings": MessageLookupByLibrary.simpleMessage("詳細設定"),
    "ageEncryptedProfile": MessageLookupByLibrary.simpleMessage("暗号化されたプロファイル"),
    "ageSecretKey": MessageLookupByLibrary.simpleMessage("age 秘密鍵"),
    "ageSecretKeyRequiredTip": MessageLookupByLibrary.simpleMessage(
      "このプロファイルは age で暗号化されており、復号には age 秘密鍵が必要です",
    ),
    "agree": MessageLookupByLibrary.simpleMessage("同意する"),
    "aiServices": MessageLookupByLibrary.simpleMessage("AI サービス"),
    "allNodes": MessageLookupByLibrary.simpleMessage("すべてのノード"),
    "allowBypass": MessageLookupByLibrary.simpleMessage("アプリによるVPNバイパスを許可"),
    "allowLan": MessageLookupByLibrary.simpleMessage("LANプロキシ"),
    "allowedIps": MessageLookupByLibrary.simpleMessage("許可する IP"),
    "alpn": MessageLookupByLibrary.simpleMessage("ALPN"),
    "answers": MessageLookupByLibrary.simpleMessage("応答"),
    "anytls": MessageLookupByLibrary.simpleMessage("AnyTLS"),
    "app": MessageLookupByLibrary.simpleMessage("アプリ"),
    "appAccessControl": MessageLookupByLibrary.simpleMessage("アプリアクセス制御"),
    "appIconDesign": MessageLookupByLibrary.simpleMessage("アプリアイコンのデザイン"),
    "appProxiesEmpty": MessageLookupByLibrary.simpleMessage("ローカルプロキシがありません"),
    "appendSystemDns": MessageLookupByLibrary.simpleMessage("システムDNSを追加"),
    "application": MessageLookupByLibrary.simpleMessage("アプリケーション"),
    "applicationDesc": MessageLookupByLibrary.simpleMessage("アプリ関連設定を変更"),
    "authentication": MessageLookupByLibrary.simpleMessage("認証"),
    "authenticationDesc": MessageLookupByLibrary.simpleMessage(
      "認証を有効にすると、ローカルプロキシポートの利用にユーザー名とパスワードが必要になります。",
    ),
    "authenticationSystemProxyDesc": MessageLookupByLibrary.simpleMessage(
      "認証が有効な間、システムプロキシは適用されません。",
    ),
    "authorize": MessageLookupByLibrary.simpleMessage("許可"),
    "authorized": MessageLookupByLibrary.simpleMessage("許可済み"),
    "auto": MessageLookupByLibrary.simpleMessage("自動"),
    "autoCheckUpdate": MessageLookupByLibrary.simpleMessage("更新の自動チェック"),
    "autoCheckUpdateDesc": MessageLookupByLibrary.simpleMessage(
      "起動時に更新を自動チェック",
    ),
    "autoCloseConnections": MessageLookupByLibrary.simpleMessage("接続を自動的に閉じる"),
    "autoCloseConnectionsDesc": MessageLookupByLibrary.simpleMessage(
      "プロキシを切り替えると、既存の接続を自動的に閉じます。",
    ),
    "autoLaunch": MessageLookupByLibrary.simpleMessage("自動起動"),
    "autoLaunchDesc": MessageLookupByLibrary.simpleMessage("システムの自動起動に従う"),
    "autoRun": MessageLookupByLibrary.simpleMessage("自動実行"),
    "autoRunDesc": MessageLookupByLibrary.simpleMessage(
      "自動実行はアプリを開いたときにプロキシを開始します。",
    ),
    "autoSetSystemDns": MessageLookupByLibrary.simpleMessage("システムDNSを自動設定"),
    "autoUpdate": MessageLookupByLibrary.simpleMessage("自動更新"),
    "autoUpdateInterval": MessageLookupByLibrary.simpleMessage("自動更新間隔（分）"),
    "back": MessageLookupByLibrary.simpleMessage("戻る"),
    "backgroundLocationPermission": MessageLookupByLibrary.simpleMessage(
      "Background Location Permission",
    ),
    "backgroundLocationPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "Required to obtain the Wi-Fi name while the app is in the background, so that On Demand can trigger reliably.",
    ),
    "backup": MessageLookupByLibrary.simpleMessage("バックアップ"),
    "backupAndRestore": MessageLookupByLibrary.simpleMessage("バックアップと復元"),
    "backupAndRestoreDesc": MessageLookupByLibrary.simpleMessage(
      "WebDAVまたはファイルでデータを同期します",
    ),
    "backupFromNewerVersion": MessageLookupByLibrary.simpleMessage(
      "このバックアップは新しいバージョンのアプリで作成されています。アプリを更新してから復元してください",
    ),
    "backupSuccess": MessageLookupByLibrary.simpleMessage("バックアップが完了しました"),
    "basicInfo": MessageLookupByLibrary.simpleMessage("基本情報"),
    "basicStrategy": MessageLookupByLibrary.simpleMessage("基本ポリシー"),
    "batchAdd": MessageLookupByLibrary.simpleMessage("一括追加"),
    "batchImport": MessageLookupByLibrary.simpleMessage("一括インポート"),
    "batchLinkInputTip": MessageLookupByLibrary.simpleMessage(
      "1行に1つのリンクを入力してください",
    ),
    "batchListInputTip": MessageLookupByLibrary.simpleMessage(
      "1行に1項目、またはカンマ区切りで入力してください",
    ),
    "batchMapInputTip": MessageLookupByLibrary.simpleMessage(
      "1行に1件、キーと値はスペースで区切ってください",
    ),
    "batchPreviewTip": m0,
    "batchUrlInputTip": MessageLookupByLibrary.simpleMessage(
      "1行に1つのURLを入力してください",
    ),
    "batteryOptimizationDesc": MessageLookupByLibrary.simpleMessage(
      "電池の最適化を無視すると、アプリがバックグラウンドで動作し続けます。",
    ),
    "bind": MessageLookupByLibrary.simpleMessage("連携"),
    "blacklistMode": MessageLookupByLibrary.simpleMessage("ブラックリストモード"),
    "blockConnection": MessageLookupByLibrary.simpleMessage("接続をブロック"),
    "bypassDomain": MessageLookupByLibrary.simpleMessage("除外ドメイン"),
    "bypassDomainDesc": MessageLookupByLibrary.simpleMessage(
      "除外ドメインはシステムプロキシが有効な場合のみ適用されます。",
    ),
    "bypassPrivateRoute": MessageLookupByLibrary.simpleMessage(
      "プライベートアドレスをバイパス",
    ),
    "bypassPrivateRouteDesc": MessageLookupByLibrary.simpleMessage(
      "プライベートアドレスをバイパスすると、LAN・ループバック・マルチキャストのアドレスは TUN を通りません。",
    ),
    "cache": MessageLookupByLibrary.simpleMessage("キャッシュ"),
    "cacheAlgorithm": MessageLookupByLibrary.simpleMessage("キャッシュアルゴリズム"),
    "cacheCorrupt": MessageLookupByLibrary.simpleMessage(
      "キャッシュが破損しています。クリアしますか？",
    ),
    "cacheMaxSize": MessageLookupByLibrary.simpleMessage("キャッシュサイズ"),
    "cameraPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "QRコードをスキャンするには、システム設定でカメラへのアクセスを許可するか、アルバムからQRコード画像を選択してください。",
    ),
    "cameraPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "カメラの権限が必要です",
    ),
    "cameraUnavailable": MessageLookupByLibrary.simpleMessage("カメラを使用できません"),
    "cancel": MessageLookupByLibrary.simpleMessage("キャンセル"),
    "cancelSelectAll": MessageLookupByLibrary.simpleMessage("すべて選択解除"),
    "cannotSave": MessageLookupByLibrary.simpleMessage("保存できません"),
    "cannotSaveLocalMixin": MessageLookupByLibrary.simpleMessage(
      "ローカルプロキシ混入設定を保存できません",
    ),
    "certificate": MessageLookupByLibrary.simpleMessage("証明書"),
    "certificatePin": MessageLookupByLibrary.simpleMessage("証明書ピン留め"),
    "changeProxyFailedTip": MessageLookupByLibrary.simpleMessage(
      "プロキシの切り替えに失敗したため、前回の選択に戻しました",
    ),
    "changelogBreaking": MessageLookupByLibrary.simpleMessage("破壊的変更"),
    "changelogFeatures": MessageLookupByLibrary.simpleMessage("新機能"),
    "changelogFixes": MessageLookupByLibrary.simpleMessage("不具合修正"),
    "changelogPerformance": MessageLookupByLibrary.simpleMessage("パフォーマンス"),
    "changelogReverts": MessageLookupByLibrary.simpleMessage("取り消し"),
    "checkCertificate": MessageLookupByLibrary.simpleMessage("TLS証明書を検証"),
    "checkCertificateDesc": MessageLookupByLibrary.simpleMessage(
      "TLS 証明書の検証を無効にすると、サブスクリプションとバックアップが中間者攻撃にさらされます。",
    ),
    "checkUpdate": MessageLookupByLibrary.simpleMessage("更新を確認"),
    "checkUpdateError": MessageLookupByLibrary.simpleMessage("すでに最新バージョンです"),
    "cipher": MessageLookupByLibrary.simpleMessage("暗号方式"),
    "clearData": MessageLookupByLibrary.simpleMessage("データを消去"),
    "clearDataAndExitTip": MessageLookupByLibrary.simpleMessage(
      "すべてのプロファイル、設定、ローカルデータを削除してアプリを終了します。もう一度開くと最初から始められます。",
    ),
    "clearDataFailed": m1,
    "clearSearch": MessageLookupByLibrary.simpleMessage("検索をクリア"),
    "clientFingerprint": MessageLookupByLibrary.simpleMessage(
      "クライアントフィンガープリント",
    ),
    "clipboardExport": MessageLookupByLibrary.simpleMessage("クリップボードへエクスポート"),
    "clipboardImport": MessageLookupByLibrary.simpleMessage("クリップボードからインポート"),
    "clipboardWriteFailed": MessageLookupByLibrary.simpleMessage(
      "クリップボードにコピーできませんでした。選択範囲が大きすぎる可能性があります",
    ),
    "close": MessageLookupByLibrary.simpleMessage("閉じる"),
    "closeConnections": MessageLookupByLibrary.simpleMessage("接続を閉じる"),
    "color": MessageLookupByLibrary.simpleMessage("カラー"),
    "colorSchemes": MessageLookupByLibrary.simpleMessage("カラースキーム"),
    "columns": MessageLookupByLibrary.simpleMessage("列数"),
    "compatible": MessageLookupByLibrary.simpleMessage("互換モード"),
    "confirm": MessageLookupByLibrary.simpleMessage("OK"),
    "confirmClearAllData": MessageLookupByLibrary.simpleMessage(
      "すべてのデータを消去してもよろしいですか？",
    ),
    "confirmDeleteProxyGroup": MessageLookupByLibrary.simpleMessage(
      "このプロキシグループを削除してもよろしいですか？",
    ),
    "confirmExitWindow": MessageLookupByLibrary.simpleMessage(
      "現在のウィンドウを閉じてもよろしいですか？",
    ),
    "confirmForceCrashCore": MessageLookupByLibrary.simpleMessage(
      "コアを強制クラッシュさせてもよろしいですか？",
    ),
    "congestionControl": MessageLookupByLibrary.simpleMessage("輻輳制御"),
    "congestionController": MessageLookupByLibrary.simpleMessage("TCP 輻輳制御"),
    "congestionWindow": MessageLookupByLibrary.simpleMessage("輻輳ウィンドウ"),
    "connected": MessageLookupByLibrary.simpleMessage("接続済み"),
    "connecting": MessageLookupByLibrary.simpleMessage("接続中…"),
    "connection": MessageLookupByLibrary.simpleMessage("接続"),
    "connections": MessageLookupByLibrary.simpleMessage("接続"),
    "connectionsLimitDisplay": MessageLookupByLibrary.simpleMessage(
      "表示する接続数を制限",
    ),
    "connectionsShowAll": MessageLookupByLibrary.simpleMessage("すべての接続を表示"),
    "connectivity": MessageLookupByLibrary.simpleMessage("接続状態："),
    "content": MessageLookupByLibrary.simpleMessage("内容"),
    "contentNotEmpty": MessageLookupByLibrary.simpleMessage("内容は空にできません"),
    "contentScheme": MessageLookupByLibrary.simpleMessage("コンテンツ"),
    "controlGlobalAddedRules": MessageLookupByLibrary.simpleMessage(
      "グローバル追加ルールを管理",
    ),
    "copy": MessageLookupByLibrary.simpleMessage("コピー"),
    "copyEnvVar": MessageLookupByLibrary.simpleMessage("環境変数をコピー"),
    "copyLink": MessageLookupByLibrary.simpleMessage("リンクをコピー"),
    "copySuccess": MessageLookupByLibrary.simpleMessage("コピーしました"),
    "core": MessageLookupByLibrary.simpleMessage("コア"),
    "coreBlockedByPolicyTip": m2,
    "coreBlockedBySmartAppControlTip": MessageLookupByLibrary.simpleMessage(
      "Windows のスマート アプリ コントロールが、署名されていない FlClashCore.exe をブロックしました。Windows セキュリティ → アプリとブラウザーの制御 → スマート アプリ コントロールの設定で「オフ」を選び、FlClash を再起動してください。一度オフにすると、Windows を再インストールしない限り再度オンにはできません。",
    ),
    "coreMemoryInfo": MessageLookupByLibrary.simpleMessage("コアメモリ"),
    "coreStatus": MessageLookupByLibrary.simpleMessage("コアの状態"),
    "country": MessageLookupByLibrary.simpleMessage("地域"),
    "crashDetected": MessageLookupByLibrary.simpleMessage("クラッシュを検出しました"),
    "crashDetectedTip": m3,
    "crashTest": MessageLookupByLibrary.simpleMessage("クラッシュテスト"),
    "crashlytics": MessageLookupByLibrary.simpleMessage("クラッシュ分析"),
    "crashlyticsTip": MessageLookupByLibrary.simpleMessage(
      "クラッシュ分析を有効にすると、クラッシュ時に機密情報を含まないログをアップロードします。",
    ),
    "create": MessageLookupByLibrary.simpleMessage("作成"),
    "createProfileFromUrlTip": m4,
    "creationTime": MessageLookupByLibrary.simpleMessage("作成日時"),
    "currentWifiConnection": MessageLookupByLibrary.simpleMessage("現在の接続"),
    "currentWifiSignal": MessageLookupByLibrary.simpleMessage("信号強度"),
    "currentWifiSsid": MessageLookupByLibrary.simpleMessage("SSID"),
    "currentWifiStatus": MessageLookupByLibrary.simpleMessage("状態"),
    "custom": MessageLookupByLibrary.simpleMessage("カスタム"),
    "customIssueCoreRejected": m5,
    "customIssueDialerLoop": m6,
    "customIssueDuplicateName": m7,
    "customIssueEmptyName": MessageLookupByLibrary.simpleMessage("名前が空です"),
    "customIssueGroupLoop": m8,
    "customIssueInvalidEmptyFallback": m9,
    "customIssueInvalidFilter": m10,
    "customIssueMissingDialer": m11,
    "customIssueMissingProviders": m12,
    "customIssueMissingProxies": m13,
    "customIssueNoProxySource": MessageLookupByLibrary.simpleMessage(
      "プロキシもプロキシプロバイダーも選択されていないため、コアはこのグループを拒否します",
    ),
    "customIssueReservedName": m14,
    "customIssuesSummary": m15,
    "customProfile": MessageLookupByLibrary.simpleMessage("カスタム"),
    "customProfileDesc": MessageLookupByLibrary.simpleMessage(
      "アプリのプロキシと他のプロファイルからプロキシグループとルールを組み立てます",
    ),
    "customProfileResources": MessageLookupByLibrary.simpleMessage(
      "カスタムプロファイルのリソース",
    ),
    "customProfileResourcesDesc": MessageLookupByLibrary.simpleMessage(
      "プロキシ、ルールプロバイダー、フィルター、アイコンセット",
    ),
    "cut": MessageLookupByLibrary.simpleMessage("切り取り"),
    "cwnd": MessageLookupByLibrary.simpleMessage("CWND"),
    "dark": MessageLookupByLibrary.simpleMessage("ダーク"),
    "dashboard": MessageLookupByLibrary.simpleMessage("ダッシュボード"),
    "dataCollectionContent": MessageLookupByLibrary.simpleMessage(
      "本アプリは、安定性向上のために Firebase Crashlytics を使用してクラッシュ情報を収集します。\n収集されるデータにはデバイス情報とクラッシュの詳細が含まれますが、個人の機密データは含まれません。\nこの機能は設定で無効にできます。",
    ),
    "dataCollectionTip": MessageLookupByLibrary.simpleMessage("データ収集について"),
    "databaseWriteFailedTip": MessageLookupByLibrary.simpleMessage(
      "変更の保存に失敗したため、元に戻しました",
    ),
    "daysAgo": m16,
    "daysAgoShort": m17,
    "defaultSelected": MessageLookupByLibrary.simpleMessage("デフォルトの選択"),
    "defaultText": MessageLookupByLibrary.simpleMessage("デフォルト"),
    "definitionNotMap": MessageLookupByLibrary.simpleMessage(
      "設定は name と type を含む YAML マッピングである必要があります",
    ),
    "delay": MessageLookupByLibrary.simpleMessage("遅延"),
    "delayFailed": MessageLookupByLibrary.simpleMessage("失敗"),
    "delayTest": MessageLookupByLibrary.simpleMessage("遅延テスト"),
    "delete": MessageLookupByLibrary.simpleMessage("削除"),
    "deleteMultipTip": m18,
    "deleteTip": m19,
    "desc": MessageLookupByLibrary.simpleMessage(
      "ClashMetaベースのマルチプラットフォーム対応プロキシクライアント。シンプルで使いやすく、オープンソースで広告もありません。",
    ),
    "destination": MessageLookupByLibrary.simpleMessage("宛先"),
    "destinationGeoIP": MessageLookupByLibrary.simpleMessage("宛先GeoIP"),
    "destinationIPASN": MessageLookupByLibrary.simpleMessage("宛先IP ASN"),
    "details": m20,
    "detectionTip": MessageLookupByLibrary.simpleMessage(
      "サードパーティAPIに依存しているため、参考値です",
    ),
    "developerMode": MessageLookupByLibrary.simpleMessage("開発者モード"),
    "developerModeEnableTip": MessageLookupByLibrary.simpleMessage(
      "開発者モードが有効になりました。",
    ),
    "dhcp": MessageLookupByLibrary.simpleMessage("DHCP"),
    "dial4": MessageLookupByLibrary.simpleMessage("IPv4 送信元アドレス"),
    "dial6": MessageLookupByLibrary.simpleMessage("IPv6 送信元アドレス"),
    "dialerProxy": MessageLookupByLibrary.simpleMessage("ダイヤラープロキシ"),
    "dialerProxyDesc": MessageLookupByLibrary.simpleMessage(
      "ダイヤラープロキシは NTP サーバーへの接続に使用するアウトバウンドです。",
    ),
    "dialerProxyLoopStopped": m21,
    "direct": MessageLookupByLibrary.simpleMessage("ダイレクト"),
    "disableIcmpForwarding": MessageLookupByLibrary.simpleMessage(
      "ICMP 転送を無効化",
    ),
    "disableIcmpForwardingDesc": MessageLookupByLibrary.simpleMessage(
      "ICMP 転送を無効にすると TUN が ping に直接応答するため、ping に実際の遅延が表示されなくなります。",
    ),
    "disableKcpInput": MessageLookupByLibrary.simpleMessage("KCP 入力を無効化"),
    "disableKeepAlive": MessageLookupByLibrary.simpleMessage("TCP キープアライブを無効化"),
    "disableP2p": MessageLookupByLibrary.simpleMessage("P2P を無効化"),
    "disableQuicInput": MessageLookupByLibrary.simpleMessage("QUIC 入力を無効化"),
    "disableUDP": MessageLookupByLibrary.simpleMessage("UDPを無効化"),
    "disabled": MessageLookupByLibrary.simpleMessage("無効"),
    "discardChanges": MessageLookupByLibrary.simpleMessage("変更を破棄しますか？"),
    "disclaimer": MessageLookupByLibrary.simpleMessage("免責事項"),
    "disclaimerAcceptContent": MessageLookupByLibrary.simpleMessage(
      "本ソフトウェアをインストール、複製または使用した時点で、本声明のすべての内容を読み、同意したものとみなされます。いずれかの条項に同意いただけない場合は、直ちに使用を中止し、本ソフトウェアをアンインストールしてください。",
    ),
    "disclaimerAcceptTitle": MessageLookupByLibrary.simpleMessage("声明への同意"),
    "disclaimerAnalyticsContent": MessageLookupByLibrary.simpleMessage(
      "Firebase により基本的なアプリ利用統計が自動的に収集されます。\n\n収集内容：初回起動、アプリの起動とセッション時間、アプリの更新などの基本イベント、アプリインスタンス ID、端末のモデル、OS のバージョン、システム言語、および IP アドレスから推定される国または地域レベルのおおよその位置情報。\n\n目的：アクティブな端末数、バージョン分布、OS の互換性を把握するためにのみ使用します。開発者はこれらのデータを広告に使用したり、販売したり、サブスクリプションや設定と関連付けたりすることはありません。",
    ),
    "disclaimerAnalyticsTitle": MessageLookupByLibrary.simpleMessage(
      "Firebase Analytics（利用統計）",
    ),
    "disclaimerAndroidOnly": MessageLookupByLibrary.simpleMessage("Android のみ"),
    "disclaimerChangesContent": MessageLookupByLibrary.simpleMessage(
      "開発者はバージョンの更新に伴い本声明を変更することがあり、変更内容は新しいバージョンの公開とともに効力を生じます。更新後も本ソフトウェアを引き続き使用した場合、変更後の声明に同意したものとみなされます。",
    ),
    "disclaimerChangesTitle": MessageLookupByLibrary.simpleMessage("本声明の変更"),
    "disclaimerCrashlyticsContent": MessageLookupByLibrary.simpleMessage(
      "アプリがクラッシュした際に、クラッシュレポートを自動的に送信します。\n\n収集内容：クラッシュのスタックトレースとエラー情報、発生日時、アプリのバージョンとビルド番号、端末のメーカーとモデル、Android のバージョン、画面の向き、空きメモリと空きストレージ、root 化の有無、およびインストール時に生成され再インストールでリセットされるランダムなインストール ID。\n\n目的：クラッシュの特定と修正のためにのみ使用します。\n\n「ツール > 一般 > クラッシュ分析」からいつでもオフにできます。",
    ),
    "disclaimerCrashlyticsTitle": MessageLookupByLibrary.simpleMessage(
      "Firebase Crashlytics（クラッシュ分析）",
    ),
    "disclaimerDataProcessingContent": MessageLookupByLibrary.simpleMessage(
      "これらのデータは Google が代わりに処理・保存し、お住まいの国または地域外（米国など）のサーバーに転送される場合があり、Google のプライバシーポリシーおよび Firebase のプライバシーとセキュリティに関する説明に従って取り扱われます。クラッシュレポートは最大 90 日間保存され、統計データは Firebase の既定の保存ポリシーに従って保存されます。",
    ),
    "disclaimerDesc": MessageLookupByLibrary.simpleMessage(
      "FlClash（以下「本ソフトウェア」）をご利用になる前に、本声明の内容をよくお読みになり、十分にご理解ください。「同意する」をタップすると、以下のすべての条項を読み、理解し、承諾したものとみなされます。同意いただけない場合は「終了」をタップし、本ソフトウェアの使用を中止してください。",
    ),
    "disclaimerFirebasePrivacy": MessageLookupByLibrary.simpleMessage(
      "Firebase のプライバシーとセキュリティ",
    ),
    "disclaimerGooglePrivacy": MessageLookupByLibrary.simpleMessage(
      "Google プライバシーポリシー",
    ),
    "disclaimerLiabilityContent": MessageLookupByLibrary.simpleMessage(
      "適用法で認められる最大限の範囲において、開発者およびすべての貢献者は、本ソフトウェアの使用または使用不能に起因する直接的、間接的、偶発的、特別、懲罰的または結果的な損害（データの消失、機器の損傷、ネットワーク障害、業務の中断、逸失利益、およびそれに起因する法的紛争を含むがこれらに限らない）について、その可能性を知らされていた場合であっても、一切責任を負いません。",
    ),
    "disclaimerLiabilityTitle": MessageLookupByLibrary.simpleMessage("責任の制限"),
    "disclaimerLicenseContent": MessageLookupByLibrary.simpleMessage(
      "本ソフトウェアは GPL-3.0 ライセンスのもとでオープンソースとして公開されています。同ライセンスを遵守する限り、自由に使用、改変、再配布できますが、派生物も GPL-3.0 で公開し、原著作者の著作権表示を保持する必要があります。\n\n本ソフトウェアに含まれるサードパーティのコンポーネント（Clash.Meta コアを含む）は、それぞれのライセンスに従います。改変版や再配布版に起因する問題について、原著作者は責任を負いません。",
    ),
    "disclaimerLicenseTitle": MessageLookupByLibrary.simpleMessage(
      "オープンソースライセンス",
    ),
    "disclaimerNoServiceStatement": MessageLookupByLibrary.simpleMessage(
      "本ソフトウェア自体は、プロキシサーバー、ノード、サブスクリプション、ネットワーク接続サービスを一切提供しておらず、それらのサービス提供者と提携、代理、保証の関係はありません。",
    ),
    "disclaimerPrivacyContent": MessageLookupByLibrary.simpleMessage(
      "本ソフトウェアは、サブスクリプション URL、ノード情報、設定内容、閲覧したウェブサイト、接続記録、通信内容、ログを収集またはアップロードしません。これらのデータは端末内にのみ保存され、開発者がアクセスすることはできません。\n\n本ソフトウェアが外部ネットワークにアクセスするのは、プロファイル更新時に指定されたサブスクリプション URL へアクセスする場合や、アップデート確認時に GitHub へアクセスする場合など、該当する機能を使用したときのみです。\n\nデスクトップ版（Windows、macOS、Linux）には、統計やクラッシュレポートのサービスは一切組み込まれていません。Android 版には、安定性向上のため以下の 2 つの Google Firebase サービスが組み込まれています。",
    ),
    "disclaimerPrivacyTitle": MessageLookupByLibrary.simpleMessage(
      "データ収集とプライバシー",
    ),
    "disclaimerReadToEnd": MessageLookupByLibrary.simpleMessage("最後までお読みください"),
    "disclaimerResponsibilityContent": MessageLookupByLibrary.simpleMessage(
      "お住まいの国または地域で本ソフトウェアの使用が合法であることはご自身で確認する必要があり、本ソフトウェアを使用したすべての行為とその結果について、ご自身が単独で法的責任を負います。\n\nインポートするサブスクリプション、ノード、設定はご自身の判断で選択したものです。その出所の適法性、内容の安全性、サービスの安定性については、利用者と各提供者の間で解決してください。",
    ),
    "disclaimerResponsibilityTitle": MessageLookupByLibrary.simpleMessage(
      "利用者の責任",
    ),
    "disclaimerRestateHint": MessageLookupByLibrary.simpleMessage("上記の声明を入力"),
    "disclaimerRestateMismatch": MessageLookupByLibrary.simpleMessage(
      "声明の内容と一致しません",
    ),
    "disclaimerRestateTip": MessageLookupByLibrary.simpleMessage(
      "内容を理解したことを確認するため、以下の声明を下の入力欄に正確に入力してください：",
    ),
    "disclaimerRestateTitle": MessageLookupByLibrary.simpleMessage("声明の復唱"),
    "disclaimerSoftwareContent": MessageLookupByLibrary.simpleMessage(
      "本ソフトウェアは Clash.Meta（mihomo）コアをベースとしたオープンソースのネットワークプロキシクライアントであり、設定管理、ルールによる振り分け、トラフィック転送などのローカルツール機能のみを提供します。",
    ),
    "disclaimerSoftwareTitle": MessageLookupByLibrary.simpleMessage(
      "ソフトウェアの性質",
    ),
    "disclaimerThirdPartyContent": MessageLookupByLibrary.simpleMessage(
      "サブスクリプションリンク、設定ファイル、ルールセット、スクリプト、外部リソース、外部リンクはすべて第三者が提供するものであり、開発者はその適法性、正確性、安全性、可用性を審査または保証することはできず、また行いません。\n\nサードパーティのコンテンツの使用に起因する情報漏えい、財産上の損失、アカウント停止その他の損失は、利用者と第三者の間で解決するものとし、開発者は一切責任を負いません。",
    ),
    "disclaimerThirdPartyTitle": MessageLookupByLibrary.simpleMessage(
      "サードパーティのコンテンツ",
    ),
    "disclaimerUsageContent": MessageLookupByLibrary.simpleMessage(
      "本ソフトウェアは学習、交流、技術研究などの非商用目的でのみ使用できます。有償配布、抱き合わせ販売、商用サービスの一部としての利用、本ソフトウェアの名義での事業活動など、あらゆる商用目的での使用を固く禁じます。いかなる商業行為も本ソフトウェアおよび開発者とは一切関係ありません。\n\nお住まいの国または地域の法令に違反する目的での使用を固く禁じます。これには、法に基づくネットワークアクセス制限の回避、違法情報の拡散、サイバー攻撃、他者の権利の侵害などが含まれますが、これらに限りません。",
    ),
    "disclaimerUsageTitle": MessageLookupByLibrary.simpleMessage("使用の制限"),
    "disclaimerWarrantyContent": MessageLookupByLibrary.simpleMessage(
      "本ソフトウェアは「現状のまま」かつ「提供可能な範囲で」提供され、商品性、特定目的への適合性、非侵害、継続的な可用性、エラーやセキュリティ上の脆弱性がないことの保証を含め、明示または黙示を問わずいかなる保証も伴いません。\n\n開発者は、本ソフトウェアが利用者の要件を満たすこと、また中断やエラーなく動作することを保証しません。",
    ),
    "disclaimerWarrantyTitle": MessageLookupByLibrary.simpleMessage("無保証"),
    "disconnected": MessageLookupByLibrary.simpleMessage("切断済み"),
    "discoverNewVersion": MessageLookupByLibrary.simpleMessage(
      "新しいバージョンが見つかりました",
    ),
    "dnsHijacking": MessageLookupByLibrary.simpleMessage("DNSハイジャック"),
    "dnsMode": MessageLookupByLibrary.simpleMessage("DNSモード"),
    "dnsOverrideDesc": MessageLookupByLibrary.simpleMessage(
      "ここで追加した項目は、すべての URL・ファイルプロファイルの DNS を上書きします。追加していない項目はプロファイル自身の設定のままです。カスタムプロファイルの DNS はその内容で設定します。",
    ),
    "dnsQueries": MessageLookupByLibrary.simpleMessage("DNSクエリ"),
    "docked": MessageLookupByLibrary.simpleMessage("固定"),
    "domain": MessageLookupByLibrary.simpleMessage("ドメイン"),
    "down": MessageLookupByLibrary.simpleMessage("ダウン"),
    "download": MessageLookupByLibrary.simpleMessage("ダウンロード"),
    "downloadBandwidth": MessageLookupByLibrary.simpleMessage("ダウンロード帯域幅"),
    "downloadCarrier": MessageLookupByLibrary.simpleMessage("ダウンロードキャリア"),
    "downloadSpeed": MessageLookupByLibrary.simpleMessage("ダウンロード速度"),
    "downloaded": MessageLookupByLibrary.simpleMessage("ダウンロード済み"),
    "earlyDataHeaderName": MessageLookupByLibrary.simpleMessage(
      "Early Data Header",
    ),
    "easytier": MessageLookupByLibrary.simpleMessage("EasyTier"),
    "ech": MessageLookupByLibrary.simpleMessage("ECH"),
    "echConfig": MessageLookupByLibrary.simpleMessage("ECH 設定"),
    "echQueryServerName": MessageLookupByLibrary.simpleMessage("ECH クエリサーバー名"),
    "edit": MessageLookupByLibrary.simpleMessage("編集"),
    "editGlobalRules": MessageLookupByLibrary.simpleMessage("グローバルルールを編集"),
    "editLocalProxy": MessageLookupByLibrary.simpleMessage("ローカルプロキシを編集"),
    "editLocalRule": MessageLookupByLibrary.simpleMessage("ローカルルールを編集"),
    "editProxy": MessageLookupByLibrary.simpleMessage("プロキシを編集"),
    "editProxyGroup": MessageLookupByLibrary.simpleMessage("プロキシグループを編集"),
    "editRule": MessageLookupByLibrary.simpleMessage("ルールを編集"),
    "editSsid": MessageLookupByLibrary.simpleMessage("SSIDを編集"),
    "editorUnavailable": MessageLookupByLibrary.simpleMessage("エディターを利用できません"),
    "effectiveConfig": MessageLookupByLibrary.simpleMessage("有効な設定"),
    "emptyFallback": MessageLookupByLibrary.simpleMessage("空グループのフォールバック"),
    "emptyTip": m22,
    "en": MessageLookupByLibrary.simpleMessage("英語"),
    "enableEncryption": MessageLookupByLibrary.simpleMessage("暗号化を有効化"),
    "enableExitNode": MessageLookupByLibrary.simpleMessage("出口ノードとして動作"),
    "enableHealthCheck": MessageLookupByLibrary.simpleMessage("ヘルスチェックを有効化"),
    "enableKcpProxy": MessageLookupByLibrary.simpleMessage("KCP プロキシを有効化"),
    "enableLocalProxyMixin": MessageLookupByLibrary.simpleMessage(
      "ローカルプロキシ混入を有効化",
    ),
    "enableQuicProxy": MessageLookupByLibrary.simpleMessage("QUIC プロキシを有効化"),
    "enabled": MessageLookupByLibrary.simpleMessage("有効"),
    "enabledNodes": MessageLookupByLibrary.simpleMessage("有効なノード"),
    "encryption": MessageLookupByLibrary.simpleMessage("暗号化"),
    "encryptionAlgorithm": MessageLookupByLibrary.simpleMessage("暗号化アルゴリズム"),
    "entries": MessageLookupByLibrary.simpleMessage(" 件"),
    "error": MessageLookupByLibrary.simpleMessage("エラー"),
    "errorDetails": MessageLookupByLibrary.simpleMessage("エラーの詳細"),
    "exclude": MessageLookupByLibrary.simpleMessage("最近のタスクから隠す"),
    "excludeDesc": MessageLookupByLibrary.simpleMessage(
      "アプリがバックグラウンド時に最近のタスクから非表示",
    ),
    "excludeFilter": MessageLookupByLibrary.simpleMessage("除外フィルター"),
    "excludeInterface": MessageLookupByLibrary.simpleMessage("除外インターフェース"),
    "excludeInterfaceDesc": MessageLookupByLibrary.simpleMessage(
      "除外インターフェースは Linux でのみ有効です。docker0 などから入る通信は TUN を通りません。",
    ),
    "excludeSsids": MessageLookupByLibrary.simpleMessage("除外SSID"),
    "excludeSsidsDesc": MessageLookupByLibrary.simpleMessage(
      "除外した SSID の Wi-Fi に接続すると、アプリの実行状態が自動的に切り替わります。",
    ),
    "existsTip": m23,
    "exit": MessageLookupByLibrary.simpleMessage("終了"),
    "exitFullScreen": MessageLookupByLibrary.simpleMessage("全画面表示を終了"),
    "exitNodes": MessageLookupByLibrary.simpleMessage("出口ノード"),
    "expand": MessageLookupByLibrary.simpleMessage("標準"),
    "expectedStatus": MessageLookupByLibrary.simpleMessage("期待するステータス"),
    "expireTime": MessageLookupByLibrary.simpleMessage("有効期限"),
    "exportFile": MessageLookupByLibrary.simpleMessage("ファイルをエクスポート"),
    "exportLogs": MessageLookupByLibrary.simpleMessage("ログをエクスポート"),
    "exportSuccess": MessageLookupByLibrary.simpleMessage("エクスポートが完了しました"),
    "expressiveScheme": MessageLookupByLibrary.simpleMessage("エクスプレッシブ"),
    "extend": MessageLookupByLibrary.simpleMessage("拡張"),
    "extendMode": MessageLookupByLibrary.simpleMessage("拡張モード"),
    "extendScript": MessageLookupByLibrary.simpleMessage("拡張スクリプト"),
    "externalController": MessageLookupByLibrary.simpleMessage("外部コントローラー"),
    "externalControllerDesc": MessageLookupByLibrary.simpleMessage(
      "外部コントローラーを有効にすると、ポート 9090 でコアを制御できます。",
    ),
    "externalControllerSecret": MessageLookupByLibrary.simpleMessage(
      "外部コントローラーのシークレット",
    ),
    "externalLink": MessageLookupByLibrary.simpleMessage("外部リンク"),
    "extraLarge": MessageLookupByLibrary.simpleMessage("特大"),
    "fade": MessageLookupByLibrary.simpleMessage("フェード"),
    "failedCount": m24,
    "failedItem": m25,
    "fakeipFilter": MessageLookupByLibrary.simpleMessage("Fake-IPフィルター"),
    "fakeipFilterMode": MessageLookupByLibrary.simpleMessage("Fake-IPフィルターモード"),
    "fakeipFilterModeDesc": MessageLookupByLibrary.simpleMessage(
      "Fake-IP フィルターモードでは、blacklist は一致を除外、whitelist は一致のみ、rule はルールで判定します。",
    ),
    "fakeipRange": MessageLookupByLibrary.simpleMessage("Fake-IP範囲"),
    "fakeipRange6": MessageLookupByLibrary.simpleMessage("Fake-IP範囲（IPv6）"),
    "fakeipTtl": MessageLookupByLibrary.simpleMessage("Fake-IP TTL"),
    "fallbackFilter": MessageLookupByLibrary.simpleMessage("フォールバックフィルター"),
    "fidelityScheme": MessageLookupByLibrary.simpleMessage("フィデリティ"),
    "file": MessageLookupByLibrary.simpleMessage("ファイル"),
    "fileDesc": MessageLookupByLibrary.simpleMessage("プロファイルファイルを直接アップロードします"),
    "fileIsUpdate": MessageLookupByLibrary.simpleMessage(
      "ファイルが変更されています。変更を保存しますか？",
    ),
    "filter": MessageLookupByLibrary.simpleMessage("フィルター"),
    "filters": MessageLookupByLibrary.simpleMessage("フィルター"),
    "finalConfig": MessageLookupByLibrary.simpleMessage("最終設定"),
    "findProcessMode": MessageLookupByLibrary.simpleMessage("プロセス検出"),
    "fingerprint": MessageLookupByLibrary.simpleMessage("フィンガープリント"),
    "floating": MessageLookupByLibrary.simpleMessage("フローティング"),
    "flow": MessageLookupByLibrary.simpleMessage("フロー"),
    "followProfile": MessageLookupByLibrary.simpleMessage("プロファイルに従う"),
    "followSystem": MessageLookupByLibrary.simpleMessage("システムに従う"),
    "fontFamily": MessageLookupByLibrary.simpleMessage("フォント"),
    "fontSize": MessageLookupByLibrary.simpleMessage("サイズ"),
    "forceDnsMapping": MessageLookupByLibrary.simpleMessage("DNSマッピングを強制"),
    "forceDnsMappingDesc": MessageLookupByLibrary.simpleMessage(
      "DNS マッピングを強制すると、DNS マッピングでドメインを得た接続もスニッフィングします。",
    ),
    "forceDomain": MessageLookupByLibrary.simpleMessage("強制するドメイン"),
    "forceDomainDesc": MessageLookupByLibrary.simpleMessage(
      "強制するドメインもスニッフィングします。ドメインを持つその他の接続は対象外です。",
    ),
    "forceRestartCoreTip": MessageLookupByLibrary.simpleMessage(
      "コアを強制再起動してもよろしいですか？",
    ),
    "fruitSaladScheme": MessageLookupByLibrary.simpleMessage("フルーツサラダ"),
    "general": MessageLookupByLibrary.simpleMessage("一般"),
    "geoResources": MessageLookupByLibrary.simpleMessage("Geo"),
    "geoSkipped": m26,
    "geoUpdated": m27,
    "geodataLoader": MessageLookupByLibrary.simpleMessage("Geo低メモリモード"),
    "global": MessageLookupByLibrary.simpleMessage("グローバル"),
    "go": MessageLookupByLibrary.simpleMessage("開く"),
    "goDownload": MessageLookupByLibrary.simpleMessage("ダウンロードへ"),
    "goToConfigureAddedRules": MessageLookupByLibrary.simpleMessage(
      "追加ルール設定へ移動",
    ),
    "goToConfigureScript": MessageLookupByLibrary.simpleMessage("スクリプト設定へ移動"),
    "grpcServiceName": MessageLookupByLibrary.simpleMessage(
      "gRPC Service Name",
    ),
    "grpcUserAgent": MessageLookupByLibrary.simpleMessage("gRPC User Agent"),
    "hasCacheChange": MessageLookupByLibrary.simpleMessage("変更をキャッシュしますか？"),
    "hashByInUser": MessageLookupByLibrary.simpleMessage("インバウンドユーザーでハッシュ"),
    "healthCheck": MessageLookupByLibrary.simpleMessage("ヘルスチェック"),
    "healthCheckInterval": MessageLookupByLibrary.simpleMessage("間隔（秒）"),
    "healthCheckTimeout": MessageLookupByLibrary.simpleMessage("タイムアウト（ミリ秒）"),
    "healthCheckUrl": MessageLookupByLibrary.simpleMessage("チェック URL"),
    "helperCorruptTip": MessageLookupByLibrary.simpleMessage(
      "Helper サービスが利用できないため、TUN モードを有効にできません。FlClash を再インストールしてください。",
    ),
    "hideFromList": MessageLookupByLibrary.simpleMessage("リストから隠す"),
    "hideIp": MessageLookupByLibrary.simpleMessage("IP を隠す"),
    "hidePassword": MessageLookupByLibrary.simpleMessage("パスワードを隠す"),
    "hideTimeoutProxies": MessageLookupByLibrary.simpleMessage(
      "タイムアウトしたプロキシを隠す",
    ),
    "hideTimeoutProxiesDesc": MessageLookupByLibrary.simpleMessage(
      "前回の遅延テストがタイムアウトしたプロキシを表示しない",
    ),
    "hopInterval": MessageLookupByLibrary.simpleMessage("ホップ間隔"),
    "host": MessageLookupByLibrary.simpleMessage("ホスト"),
    "hostKey": MessageLookupByLibrary.simpleMessage("ホストキー"),
    "hostKeyAlgorithms": MessageLookupByLibrary.simpleMessage("ホストキーアルゴリズム"),
    "hostname": MessageLookupByLibrary.simpleMessage("ホスト名"),
    "hotkeyConflictWith": m28,
    "hotkeyDesc": MessageLookupByLibrary.simpleMessage(
      "グローバルホットキーはウィンドウが非表示でも有効です。アクションをタップしてキーの組み合わせを記録します。",
    ),
    "hotkeyManagement": MessageLookupByLibrary.simpleMessage("ホットキー管理"),
    "hotkeyNeedsModifier": m29,
    "hotkeyNotSet": MessageLookupByLibrary.simpleMessage("未設定"),
    "hotkeyUnavailable": MessageLookupByLibrary.simpleMessage(
      "登録できませんでした。他のアプリが使用している可能性があります",
    ),
    "hours": MessageLookupByLibrary.simpleMessage("時間"),
    "hoursAgo": m30,
    "hoursAgoShort": m31,
    "hoursCount": m32,
    "httpMethod": MessageLookupByLibrary.simpleMessage("HTTP Method"),
    "hysteria2": MessageLookupByLibrary.simpleMessage("Hysteria2"),
    "icon": MessageLookupByLibrary.simpleMessage("アイコン"),
    "iconRecords": MessageLookupByLibrary.simpleMessage("アイコン履歴"),
    "iconSets": MessageLookupByLibrary.simpleMessage("アイコンセット"),
    "iconSetsEmptyTip": MessageLookupByLibrary.simpleMessage(
      "アイコンセットはまだありません。「カスタムプロファイルのリソース → アイコンセット」で追加できます",
    ),
    "iconStyle": MessageLookupByLibrary.simpleMessage("アイコンスタイル"),
    "iconStyleFilled": MessageLookupByLibrary.simpleMessage("背景あり"),
    "iconStyleHidden": MessageLookupByLibrary.simpleMessage("非表示"),
    "iconStylePlain": MessageLookupByLibrary.simpleMessage("背景なし"),
    "iconUrl": MessageLookupByLibrary.simpleMessage("アイコンURL"),
    "idleSessionCheckInterval": MessageLookupByLibrary.simpleMessage(
      "アイドルセッション確認間隔",
    ),
    "idleSessionTimeout": MessageLookupByLibrary.simpleMessage(
      "アイドルセッションタイムアウト",
    ),
    "ignoreBatteryOptimization": MessageLookupByLibrary.simpleMessage(
      "電池の最適化を無視",
    ),
    "import": MessageLookupByLibrary.simpleMessage("インポート"),
    "importAvailableNodes": MessageLookupByLibrary.simpleMessage(
      "利用可能なノードをインポート",
    ),
    "importConfigInvalid": MessageLookupByLibrary.simpleMessage(
      "このファイルはインポートできる設定ではありません",
    ),
    "importConfigReplaceTip": MessageLookupByLibrary.simpleMessage(
      "インポートすると、このプロファイルの現在のプロキシグループ、ルール、設定が置き換えられます",
    ),
    "importFile": MessageLookupByLibrary.simpleMessage("ファイルからインポート"),
    "importFromLink": MessageLookupByLibrary.simpleMessage("リンクからインポート"),
    "importUrl": MessageLookupByLibrary.simpleMessage("URLからインポート"),
    "inbound": MessageLookupByLibrary.simpleMessage("インバウンド"),
    "incompleteSupport": MessageLookupByLibrary.simpleMessage("一部未対応"),
    "infiniteTime": MessageLookupByLibrary.simpleMessage("無期限"),
    "init": MessageLookupByLibrary.simpleMessage("初期化"),
    "initFailed": MessageLookupByLibrary.simpleMessage("起動に失敗しました"),
    "initFailedTip": MessageLookupByLibrary.simpleMessage(
      "FlClash の起動中にエラーが発生したため、続行できません。詳細をコピーして問題を報告できます。繰り返し発生する場合は、データを消去すると起動できるようになることがあります。",
    ),
    "initiator": MessageLookupByLibrary.simpleMessage("発信元"),
    "inputProxyGroupName": MessageLookupByLibrary.simpleMessage(
      "プロキシグループ名を入力してください",
    ),
    "inputRuleContent": MessageLookupByLibrary.simpleMessage("ルールの内容を入力してください"),
    "installedAppsPermissionDeniedMessage":
        MessageLookupByLibrary.simpleMessage(
          "アプリ一覧の権限が拒否されたため、インストール済みアプリを取得できません。システム設定から手動で許可してください。",
        ),
    "installedAppsPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "このシステムでは、許可するまでインストール済みアプリの一覧が提供されません。許可すると、アプリごとのプロキシを設定できます。",
    ),
    "installedAppsPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "アプリ一覧の権限が必要です",
    ),
    "installedFonts": MessageLookupByLibrary.simpleMessage("インストール済みのフォント"),
    "instanceName": MessageLookupByLibrary.simpleMessage("インスタンス名"),
    "intelligentSelected": MessageLookupByLibrary.simpleMessage("スマート選択"),
    "interfaceName": MessageLookupByLibrary.simpleMessage("インターフェース名"),
    "interfaceNameDesc": MessageLookupByLibrary.simpleMessage(
      "インターフェース名は、アウトバウンド接続に使用するネットワークインターフェースです。",
    ),
    "interfaceNameMode": MessageLookupByLibrary.simpleMessage(
      "アウトバウンドインターフェース",
    ),
    "interfaceNameModeClear": MessageLookupByLibrary.simpleMessage("クリア"),
    "interfaceNameModeCustom": MessageLookupByLibrary.simpleMessage("カスタム"),
    "interfaceNameModeFollow": MessageLookupByLibrary.simpleMessage("設定に従う"),
    "internet": MessageLookupByLibrary.simpleMessage("インターネット"),
    "interval": MessageLookupByLibrary.simpleMessage("間隔"),
    "intranetIP": MessageLookupByLibrary.simpleMessage("イントラネットIP"),
    "invalidBackupFile": MessageLookupByLibrary.simpleMessage("無効なバックアップファイル"),
    "invalidCidrContent": MessageLookupByLibrary.simpleMessage(
      "192.168.0.0/16 のような CIDR 形式の IP 範囲を入力してください",
    ),
    "invalidDscpContent": MessageLookupByLibrary.simpleMessage(
      "DSCP マークは 63 を超えられません",
    ),
    "invalidHostContent": MessageLookupByLibrary.simpleMessage(
      "ドメインまたは IP アドレスを入力してください",
    ),
    "invalidIconSet": MessageLookupByLibrary.simpleMessage("有効なアイコンセットではありません"),
    "invalidLinkTip": MessageLookupByLibrary.simpleMessage(
      "サブスクリプションリンクまたはプロキシの共有リンクではありません",
    ),
    "invalidListenContent": MessageLookupByLibrary.simpleMessage(
      "0.0.0.0:1053 のようなアドレスとポートを入力してください",
    ),
    "invalidNetworkContent": MessageLookupByLibrary.simpleMessage(
      "tcp または udp のみ対応しています",
    ),
    "invalidPolicy": m33,
    "invalidPortRangeContent": MessageLookupByLibrary.simpleMessage(
      "443 や 8000-9000 のようなポートまたは範囲を入力してください",
    ),
    "invalidProfileQrcode": MessageLookupByLibrary.simpleMessage(
      "このQRコードにはプロファイルのリンクが含まれていません",
    ),
    "invalidProxy": m34,
    "invalidProxyProvider": m35,
    "invalidRangeContent": MessageLookupByLibrary.simpleMessage(
      "80 や 8000-9000 のような数値または範囲を / 区切りで入力してください",
    ),
    "invalidRuleSet": m36,
    "invalidSubRule": m37,
    "ipAddress": MessageLookupByLibrary.simpleMessage("IP アドレス"),
    "ipAsn": MessageLookupByLibrary.simpleMessage("ASN"),
    "ipFlagAbuser": MessageLookupByLibrary.simpleMessage("不正利用の履歴"),
    "ipFlagProxy": MessageLookupByLibrary.simpleMessage("プロキシ"),
    "ipFlagTor": MessageLookupByLibrary.simpleMessage("Tor"),
    "ipFlagVpn": MessageLookupByLibrary.simpleMessage("VPN"),
    "ipFlags": MessageLookupByLibrary.simpleMessage("検出"),
    "ipOrganization": MessageLookupByLibrary.simpleMessage("組織"),
    "ipQualityFailed": MessageLookupByLibrary.simpleMessage(
      "IP タイプを判定できませんでした",
    ),
    "ipQualityGood": MessageLookupByLibrary.simpleMessage("良好"),
    "ipQualityLevel": MessageLookupByLibrary.simpleMessage("レベル"),
    "ipQualityNormal": MessageLookupByLibrary.simpleMessage("普通"),
    "ipQualityRetry": MessageLookupByLibrary.simpleMessage("再確認"),
    "ipQualityRisky": MessageLookupByLibrary.simpleMessage("リスクあり"),
    "ipQualitySource": MessageLookupByLibrary.simpleMessage("採用したソース"),
    "ipQualitySources": MessageLookupByLibrary.simpleMessage("各ソース"),
    "ipSourceIpMismatch": MessageLookupByLibrary.simpleMessage(
      "アウトバウンド IP が不一致",
    ),
    "ipSourceNoType": MessageLookupByLibrary.simpleMessage("判定不可"),
    "ipSourceRateLimited": MessageLookupByLibrary.simpleMessage("レート制限"),
    "ipType": MessageLookupByLibrary.simpleMessage("タイプ"),
    "ipTypeBusiness": MessageLookupByLibrary.simpleMessage("ビジネス"),
    "ipTypeHosting": MessageLookupByLibrary.simpleMessage("データセンター"),
    "ipTypeMobile": MessageLookupByLibrary.simpleMessage("モバイル回線"),
    "ipTypeResidential": MessageLookupByLibrary.simpleMessage("住宅"),
    "ipVersion": MessageLookupByLibrary.simpleMessage("IP バージョン"),
    "ipv6Desc": MessageLookupByLibrary.simpleMessage(
      "IPv6 トラフィックは IPv6 が有効なときだけ受信します。",
    ),
    "ipv6InboundDesc": MessageLookupByLibrary.simpleMessage(
      "IPv6 を有効にすると、VPN で IPv6 インバウンドを許可します。",
    ),
    "ipv6Timeout": MessageLookupByLibrary.simpleMessage("IPv6タイムアウト（ms）"),
    "itemsCount": m38,
    "ja": MessageLookupByLibrary.simpleMessage("日本語"),
    "justNow": MessageLookupByLibrary.simpleMessage("たった今"),
    "keepAliveIdle": MessageLookupByLibrary.simpleMessage("TCP キープアライブ待機時間"),
    "keepAliveIntervalDesc": MessageLookupByLibrary.simpleMessage(
      "TCPキープアライブ間隔",
    ),
    "key": MessageLookupByLibrary.simpleMessage("キー"),
    "label": MessageLookupByLibrary.simpleMessage("ラベル"),
    "language": MessageLookupByLibrary.simpleMessage("言語"),
    "large": MessageLookupByLibrary.simpleMessage("大"),
    "lastUpdated": MessageLookupByLibrary.simpleMessage("最終更新"),
    "latency": MessageLookupByLibrary.simpleMessage("レイテンシ"),
    "latencyFirst": MessageLookupByLibrary.simpleMessage("遅延優先"),
    "launchInterrupted": MessageLookupByLibrary.simpleMessage("起動が完了しませんでした"),
    "launchInterruptedTip": MessageLookupByLibrary.simpleMessage(
      "前回、アプリは起動中に予期せず終了しました。今回の自動セットアップはスキップしました。手動で起動して再試行できます。",
    ),
    "layout": MessageLookupByLibrary.simpleMessage("レイアウト"),
    "light": MessageLookupByLibrary.simpleMessage("ライト"),
    "lineIssueTip": m39,
    "lineWrap": MessageLookupByLibrary.simpleMessage("折り返し"),
    "link": MessageLookupByLibrary.simpleMessage("リンク"),
    "linkDesc": MessageLookupByLibrary.simpleMessage(
      "サブスクリプションリンクまたはプロキシの共有リンクからプロファイルを取得します",
    ),
    "list": MessageLookupByLibrary.simpleMessage("リスト"),
    "listen": MessageLookupByLibrary.simpleMessage("リッスン"),
    "listenRoutingMark": MessageLookupByLibrary.simpleMessage("リッスンのルーティングマーク"),
    "listenRoutingMarkDesc": MessageLookupByLibrary.simpleMessage(
      "リッスンのルーティングマークは Linux でのみ有効です。",
    ),
    "listeners": MessageLookupByLibrary.simpleMessage("リスナー"),
    "liveConnections": MessageLookupByLibrary.simpleMessage("リアルタイム接続"),
    "loading": MessageLookupByLibrary.simpleMessage("読み込み中…"),
    "local": MessageLookupByLibrary.simpleMessage("ローカル"),
    "localFile": MessageLookupByLibrary.simpleMessage("ローカルファイル"),
    "localImage": MessageLookupByLibrary.simpleMessage("ローカル画像"),
    "localMixinDesc": MessageLookupByLibrary.simpleMessage(
      "手動で追加したノードを現在のサブスクリプションに混入し、更新に影響を与えません。",
    ),
    "localMixinDisabled": MessageLookupByLibrary.simpleMessage("無効"),
    "localMixinEnabled": MessageLookupByLibrary.simpleMessage("状態：有効"),
    "localMixinMissingGroups": m40,
    "localMixinStatus": m41,
    "localNetworkDeniedTip": MessageLookupByLibrary.simpleMessage(
      "ローカルネットワークの権限が拒否されたため gvisor スタックを使用します。LAN にはアクセスできません。",
    ),
    "localNodes": MessageLookupByLibrary.simpleMessage("ローカルノード"),
    "localPrivateKey": MessageLookupByLibrary.simpleMessage("ローカル秘密鍵"),
    "localProxies": MessageLookupByLibrary.simpleMessage("ローカルプロキシ"),
    "localProxyAnyTlsPasswordEmpty": MessageLookupByLibrary.simpleMessage(
      "AnyTLS パスワードを入力してください",
    ),
    "localProxyCarrierInvalid": MessageLookupByLibrary.simpleMessage(
      "キャリアは tcp または udp です",
    ),
    "localProxyCount": m42,
    "localProxyEasyTierAdvancedInvalid": MessageLookupByLibrary.simpleMessage(
      "MTU とルーティングマークは整数である必要があります",
    ),
    "localProxyEasyTierKeyPairRequired": MessageLookupByLibrary.simpleMessage(
      "ローカル秘密鍵と公開鍵はセットで入力してください",
    ),
    "localProxyHealthCheckInvalid": MessageLookupByLibrary.simpleMessage(
      "ヘルスチェック設定が無効です",
    ),
    "localProxyIpv4CidrInvalid": MessageLookupByLibrary.simpleMessage(
      "Overlay IPv4 は CIDR 形式である必要があります（例: 10.144.0.1/24）",
    ),
    "localProxyMixin": MessageLookupByLibrary.simpleMessage("ローカルプロキシ混入"),
    "localProxyNameEmpty": MessageLookupByLibrary.simpleMessage(
      "プロキシ名を入力してください",
    ),
    "localProxyNetworkNameEmpty": MessageLookupByLibrary.simpleMessage(
      "ネットワーク名は必須です",
    ),
    "localProxyNowhereAdvancedInvalid": MessageLookupByLibrary.simpleMessage(
      "Nowhere の詳細整数値は 0 以上で、デフォルト適用後の初期バックオフは最大バックオフ以下である必要があります",
    ),
    "localProxyNowhereInputTooLong": MessageLookupByLibrary.simpleMessage(
      "Nowhere の共有キーと ALPN はそれぞれ 255 UTF-8 バイト以内で入力してください",
    ),
    "localProxyNowhereKeyEmpty": MessageLookupByLibrary.simpleMessage(
      "Nowhere 共有キーを入力してください",
    ),
    "localProxyNowhereKeyInvalidNw3": MessageLookupByLibrary.simpleMessage(
      "Nowhere 3 の共有キーは小文字の16進数32文字である必要があります",
    ),
    "localProxyPasswordEmpty": MessageLookupByLibrary.simpleMessage(
      "パスワードを入力してください",
    ),
    "localProxyPeersRequired": MessageLookupByLibrary.simpleMessage(
      "リスナー未設定時はピアを1つ以上追加してください",
    ),
    "localProxyPoolInvalid": MessageLookupByLibrary.simpleMessage(
      "プールは 0-256 です",
    ),
    "localProxyPortInvalid": MessageLookupByLibrary.simpleMessage(
      "ポートは 1-65535 の範囲で入力してください",
    ),
    "localProxyProtocolReimportOnly": MessageLookupByLibrary.simpleMessage(
      "このプロトコルは再インポートでのみ更新できます",
    ),
    "localProxyReloadFailed": MessageLookupByLibrary.simpleMessage(
      "ローカルプロキシの再読み込みに失敗したため、変更を元に戻しました",
    ),
    "localProxyServerEmpty": MessageLookupByLibrary.simpleMessage(
      "サーバーアドレスを入力してください",
    ),
    "localProxySsAuthEmpty": MessageLookupByLibrary.simpleMessage(
      "Shadowsocks の暗号方式とパスワードを入力してください",
    ),
    "localProxySshAuthEmpty": MessageLookupByLibrary.simpleMessage(
      "SSH のパスワードまたは秘密鍵を入力してください",
    ),
    "localProxySshPassphraseWithoutKey": MessageLookupByLibrary.simpleMessage(
      "パスフレーズを使用するには秘密鍵が必要です",
    ),
    "localProxyTlsKeyPairRequired": MessageLookupByLibrary.simpleMessage(
      "証明書と秘密鍵は同時に指定してください",
    ),
    "localProxyUsernameEmpty": MessageLookupByLibrary.simpleMessage(
      "ユーザー名を入力してください",
    ),
    "localProxyUuidEmpty": MessageLookupByLibrary.simpleMessage(
      "VLESS UUID を入力してください",
    ),
    "localPublicKey": MessageLookupByLibrary.simpleMessage("ローカル公開鍵"),
    "localRuleCount": m43,
    "localRuleMixin": MessageLookupByLibrary.simpleMessage("ローカルルール混入"),
    "localRuleMixinStatus": m44,
    "localRuleNodesNeedMixin": MessageLookupByLibrary.simpleMessage(
      "ローカルノードを対象にするには、先にローカルプロキシ混入を有効にしてください。",
    ),
    "localRuleReloadFailed": MessageLookupByLibrary.simpleMessage(
      "ローカルルールの再読み込みに失敗したため、変更を元に戻しました",
    ),
    "localRules": MessageLookupByLibrary.simpleMessage("ローカルルール"),
    "localRulesDesc": MessageLookupByLibrary.simpleMessage(
      "ローカルで編集した分流ルールを現在のサブスクリプションに混入し、更新に影響を与えません。",
    ),
    "locationPermission": MessageLookupByLibrary.simpleMessage("位置情報の権限"),
    "locationPermissionDeniedMessage": MessageLookupByLibrary.simpleMessage(
      "位置情報の権限が拒否されたため、現在の Wi-Fi 名を取得できません。システム設定で位置情報の権限を手動で有効にしてください。",
    ),
    "locationPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "システムの要件により、Wi-Fi 名の取得には位置情報の権限が必要です。Android では「常に許可」を選択してください。そうしないと、アプリがバックグラウンドにあるときに Wi-Fi 名を取得できません。",
    ),
    "locationPermissionGuide": m45,
    "locationPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "位置情報の権限が必要です",
    ),
    "locked": MessageLookupByLibrary.simpleMessage("ブロック"),
    "log": MessageLookupByLibrary.simpleMessage("ログ"),
    "logLevel": MessageLookupByLibrary.simpleMessage("ログレベル"),
    "logcat": MessageLookupByLibrary.simpleMessage("ログキャプチャ"),
    "logcatDesc": MessageLookupByLibrary.simpleMessage(
      "ログキャプチャを無効にすると、ログの入り口が非表示になります。",
    ),
    "logs": MessageLookupByLibrary.simpleMessage("ログ"),
    "logsAndDiagnostics": MessageLookupByLibrary.simpleMessage("ログと診断"),
    "logsTest": MessageLookupByLibrary.simpleMessage("ログテスト"),
    "loopback": MessageLookupByLibrary.simpleMessage("UWP ループバック解除"),
    "loose": MessageLookupByLibrary.simpleMessage("ゆったり"),
    "manageLocalNodes": MessageLookupByLibrary.simpleMessage("ローカルノード管理"),
    "manageLocalRules": MessageLookupByLibrary.simpleMessage("ローカルルール管理"),
    "mappedListeners": MessageLookupByLibrary.simpleMessage("マップ済みリスナー"),
    "matchSourceIp": MessageLookupByLibrary.simpleMessage("送信元IPにマッチ"),
    "matchTarget": MessageLookupByLibrary.simpleMessage("MATCH-TARGET"),
    "maxConcurrentDials": MessageLookupByLibrary.simpleMessage("最大同時接続数"),
    "maxEarlyData": MessageLookupByLibrary.simpleMessage("Max Early Data"),
    "maxFailedTimes": MessageLookupByLibrary.simpleMessage("最大失敗回数"),
    "maxLengthTip": m46,
    "maximize": MessageLookupByLibrary.simpleMessage("最大化"),
    "memoryAppResident": MessageLookupByLibrary.simpleMessage("常駐メモリ"),
    "memoryAppShared": MessageLookupByLibrary.simpleMessage("アプリと共有"),
    "memoryCoreHeapIdle": MessageLookupByLibrary.simpleMessage("未使用のヒープ"),
    "memoryCoreHeapInuse": MessageLookupByLibrary.simpleMessage("使用中のヒープ"),
    "memoryCoreNotRunning": MessageLookupByLibrary.simpleMessage(
      "コアは実行されていません",
    ),
    "memoryCoreRuntime": MessageLookupByLibrary.simpleMessage("ランタイムのオーバーヘッド"),
    "memoryCoreStack": MessageLookupByLibrary.simpleMessage("ゴルーチンスタック"),
    "memoryEstimateDesc": MessageLookupByLibrary.simpleMessage(
      "プロセスの常駐メモリからの推定値で、システムの表示とは異なる場合があります。",
    ),
    "memoryEstimateSharedDesc": MessageLookupByLibrary.simpleMessage(
      "コアはアプリと同じプロセスで動作します。コア分はランタイム統計から推定し、残りはアプリと共有メモリとして計上します。",
    ),
    "memoryInfo": MessageLookupByLibrary.simpleMessage("メモリ情報"),
    "memoryReleased": MessageLookupByLibrary.simpleMessage("メモリを解放しました"),
    "memoryReleasedSize": m47,
    "messageTest": MessageLookupByLibrary.simpleMessage("メッセージテスト"),
    "messageTestTip": MessageLookupByLibrary.simpleMessage("これはメッセージです。"),
    "min": MessageLookupByLibrary.simpleMessage("最小"),
    "minIdleSession": MessageLookupByLibrary.simpleMessage("最小アイドルセッション"),
    "minimize": MessageLookupByLibrary.simpleMessage("最小化"),
    "minimizeOnExit": MessageLookupByLibrary.simpleMessage("終了時に最小化"),
    "minimizeOnExitDesc": MessageLookupByLibrary.simpleMessage(
      "システムの終了イベントを変更",
    ),
    "minutesAgo": m48,
    "minutesAgoShort": m49,
    "mixedPort": MessageLookupByLibrary.simpleMessage("Mixedポート"),
    "mixinSettings": MessageLookupByLibrary.simpleMessage("混入設定"),
    "mode": MessageLookupByLibrary.simpleMessage("モード"),
    "monochromeScheme": MessageLookupByLibrary.simpleMessage("モノクローム"),
    "monthsAgo": m50,
    "monthsAgoShort": m51,
    "more": MessageLookupByLibrary.simpleMessage("その他"),
    "morph": MessageLookupByLibrary.simpleMessage("Morph"),
    "mtu": MessageLookupByLibrary.simpleMessage("MTU"),
    "mux": MessageLookupByLibrary.simpleMessage("TLS Mux"),
    "name": MessageLookupByLibrary.simpleMessage("名前"),
    "navigationBarStyle": MessageLookupByLibrary.simpleMessage("ボトムバー"),
    "network": MessageLookupByLibrary.simpleMessage("ネットワーク"),
    "networkAccessDeniedError": m52,
    "networkBadResponseError": m53,
    "networkCancelledError": MessageLookupByLibrary.simpleMessage(
      "リクエストはキャンセルされました",
    ),
    "networkConnectionError": MessageLookupByLibrary.simpleMessage(
      "サーバーに接続できませんでした。ネットワーク接続またはプロキシ設定を確認してください",
    ),
    "networkDetection": MessageLookupByLibrary.simpleMessage("ネットワーク検出"),
    "networkHostLookupError": MessageLookupByLibrary.simpleMessage(
      "サーバーのアドレスを解決できませんでした。URL が正しいこと、DNS が使えることを確認してください",
    ),
    "networkName": MessageLookupByLibrary.simpleMessage("ネットワーク名"),
    "networkNotFoundError": m54,
    "networkRateLimitedError": MessageLookupByLibrary.simpleMessage(
      "リクエストが多すぎます（HTTP 429）。しばらく待ってから再試行してください",
    ),
    "networkRequestFailed": m55,
    "networkSecret": MessageLookupByLibrary.simpleMessage("ネットワークシークレット"),
    "networkServerError": m56,
    "networkSpeed": MessageLookupByLibrary.simpleMessage("ネットワーク速度"),
    "networkTest": MessageLookupByLibrary.simpleMessage("ネットワークテスト"),
    "networkTimeoutError": MessageLookupByLibrary.simpleMessage(
      "リクエストがタイムアウトしました。ネットワークまたはプロキシを確認してから再試行してください",
    ),
    "networkTlsError": MessageLookupByLibrary.simpleMessage(
      "安全な接続に失敗しました。サーバー証明書が無効か、接続が傍受されている可能性があります",
    ),
    "networkType": MessageLookupByLibrary.simpleMessage("ネットワーク種別"),
    "neutralScheme": MessageLookupByLibrary.simpleMessage("ニュートラル"),
    "nextMatch": MessageLookupByLibrary.simpleMessage("次の一致"),
    "no": MessageLookupByLibrary.simpleMessage("いいえ"),
    "noData": MessageLookupByLibrary.simpleMessage("データがありません"),
    "noInfo": MessageLookupByLibrary.simpleMessage("情報がありません"),
    "noListener": MessageLookupByLibrary.simpleMessage("リスナーを無効化"),
    "noLocalProxy": MessageLookupByLibrary.simpleMessage("ローカルプロキシがありません"),
    "noLocalRule": MessageLookupByLibrary.simpleMessage("ローカルルールはありません"),
    "noLocalRuleGroups": MessageLookupByLibrary.simpleMessage(
      "現在のサブスクリプションにプロキシグループがありません",
    ),
    "noLongerRemind": MessageLookupByLibrary.simpleMessage("今後表示しない"),
    "noNetwork": MessageLookupByLibrary.simpleMessage("ネットワークがありません"),
    "noNetworkApp": MessageLookupByLibrary.simpleMessage("ネットワーク不使用アプリ"),
    "noProxyGroups": MessageLookupByLibrary.simpleMessage(
      "現在の設定にプロキシグループがありません",
    ),
    "noRecords": MessageLookupByLibrary.simpleMessage("記録がありません"),
    "noResolve": MessageLookupByLibrary.simpleMessage("IPを解決しない"),
    "noResolveHostname": MessageLookupByLibrary.simpleMessage("ホスト名を解決しない"),
    "noSearchResults": MessageLookupByLibrary.simpleMessage("一致する結果はありません"),
    "nodes": MessageLookupByLibrary.simpleMessage("ノード"),
    "nonTextProviderFile": MessageLookupByLibrary.simpleMessage(
      "この外部リソースはテキストファイルではありません",
    ),
    "none": MessageLookupByLibrary.simpleMessage("なし"),
    "noneOption": MessageLookupByLibrary.simpleMessage("なし"),
    "notSelectedTip": MessageLookupByLibrary.simpleMessage(
      "現在のプロキシグループは選択できません",
    ),
    "notificationStopAction": MessageLookupByLibrary.simpleMessage("通知の停止ボタン"),
    "notificationStopActionDesc": MessageLookupByLibrary.simpleMessage(
      "VPN 通知に停止アクションを表示する",
    ),
    "nowhere": MessageLookupByLibrary.simpleMessage("Nowhere"),
    "nowhereShareKey": MessageLookupByLibrary.simpleMessage(
      "共有キー (shared key)",
    ),
    "nowhereVersion": MessageLookupByLibrary.simpleMessage("バージョン"),
    "ntpInterval": MessageLookupByLibrary.simpleMessage("同期間隔（分）"),
    "ntpStatusDesc": MessageLookupByLibrary.simpleMessage(
      "NTP を有効にすると、システムクロックではなく NTP サーバーから時刻を取得します。",
    ),
    "nullProfileDesc": MessageLookupByLibrary.simpleMessage(
      "プロファイルを追加して始めましょう",
    ),
    "nullTip": m57,
    "numberRangeTip": m58,
    "numberTip": m59,
    "obfs": MessageLookupByLibrary.simpleMessage("難読化"),
    "obfsHost": MessageLookupByLibrary.simpleMessage("難読化ホスト"),
    "obfsMode": MessageLookupByLibrary.simpleMessage("難読化モード"),
    "obfsParam": MessageLookupByLibrary.simpleMessage("難読化パラメータ"),
    "obfsPassword": MessageLookupByLibrary.simpleMessage("難読化パスワード"),
    "onDemand": MessageLookupByLibrary.simpleMessage("オンデマンド"),
    "onDemandDesc": MessageLookupByLibrary.simpleMessage(
      "オンデマンドは、除外した Wi-Fi に接続している間プロキシを一時停止します。",
    ),
    "onlyStatisticsProxy": MessageLookupByLibrary.simpleMessage(
      "プロキシトラフィックのみ集計",
    ),
    "onlyStatisticsProxyDesc": MessageLookupByLibrary.simpleMessage(
      "有効化するとプロキシトラフィックのみ統計",
    ),
    "optional": MessageLookupByLibrary.simpleMessage("任意"),
    "options": MessageLookupByLibrary.simpleMessage("オプション"),
    "other": MessageLookupByLibrary.simpleMessage("その他"),
    "otherContributors": MessageLookupByLibrary.simpleMessage("その他の貢献者"),
    "outbound": MessageLookupByLibrary.simpleMessage("アウトバウンド"),
    "outboundIp": MessageLookupByLibrary.simpleMessage("アウトバウンド IP"),
    "outboundMode": MessageLookupByLibrary.simpleMessage("アウトバウンドモード"),
    "overlayIpv4": MessageLookupByLibrary.simpleMessage("Overlay IPv4"),
    "overrideDestination": MessageLookupByLibrary.simpleMessage("宛先を上書き"),
    "overrideDestinationDesc": MessageLookupByLibrary.simpleMessage(
      "宛先を上書きすると、元のアドレスではなく検出したドメインに接続します。",
    ),
    "overrideEntries": MessageLookupByLibrary.simpleMessage("上書き項目"),
    "packetEncoding": MessageLookupByLibrary.simpleMessage("Packet Encoding"),
    "palette": MessageLookupByLibrary.simpleMessage("パレット"),
    "parse": MessageLookupByLibrary.simpleMessage("解析"),
    "parseFailed": MessageLookupByLibrary.simpleMessage("解析失敗"),
    "parsePureIp": MessageLookupByLibrary.simpleMessage("純粋なIPを解析"),
    "parsePureIpDesc": MessageLookupByLibrary.simpleMessage(
      "純粋な IP を解析すると、IP アドレスしかない接続をスニッフィングします。",
    ),
    "parseResult": m60,
    "password": MessageLookupByLibrary.simpleMessage("パスワード"),
    "paste": MessageLookupByLibrary.simpleMessage("貼り付け"),
    "pasteNodeLinkHint": MessageLookupByLibrary.simpleMessage(
      "1行に1つのノードリンクを貼り付け",
    ),
    "pasteShareLink": MessageLookupByLibrary.simpleMessage("共有リンクを貼り付け"),
    "peers": MessageLookupByLibrary.simpleMessage("ピア"),
    "pickFromAlbum": MessageLookupByLibrary.simpleMessage("アルバムから選択"),
    "pin": MessageLookupByLibrary.simpleMessage("証明書ピン"),
    "pinWindow": MessageLookupByLibrary.simpleMessage("最前面に固定"),
    "pleaseBindWebDAV": MessageLookupByLibrary.simpleMessage("WebDAVを連携してください"),
    "pleaseEnterScriptName": MessageLookupByLibrary.simpleMessage(
      "スクリプト名を入力してください",
    ),
    "pleaseUploadValidQrcode": MessageLookupByLibrary.simpleMessage(
      "有効なQRコードをアップロードしてください",
    ),
    "plugin": MessageLookupByLibrary.simpleMessage("プラグイン"),
    "pluginHost": MessageLookupByLibrary.simpleMessage("プラグインホスト"),
    "pluginMode": MessageLookupByLibrary.simpleMessage("プラグインモード"),
    "pool": MessageLookupByLibrary.simpleMessage("プール"),
    "port": MessageLookupByLibrary.simpleMessage("ポート"),
    "portConflictTip": MessageLookupByLibrary.simpleMessage("別のポートを入力してください"),
    "portHopping": MessageLookupByLibrary.simpleMessage("ポートホッピング"),
    "portTip": m61,
    "ports": MessageLookupByLibrary.simpleMessage("ポート"),
    "preSharedKey": MessageLookupByLibrary.simpleMessage("事前共有鍵"),
    "prerequisites": MessageLookupByLibrary.simpleMessage("前提条件"),
    "pressKeyboard": MessageLookupByLibrary.simpleMessage("キーの組み合わせを押してください"),
    "preview": MessageLookupByLibrary.simpleMessage("プレビュー"),
    "previousMatch": MessageLookupByLibrary.simpleMessage("前の一致"),
    "prewarmOnStart": MessageLookupByLibrary.simpleMessage("起動時に事前ウォームアップ"),
    "privateKey": MessageLookupByLibrary.simpleMessage("秘密鍵"),
    "privateKeyPassphrase": MessageLookupByLibrary.simpleMessage("秘密鍵のパスフレーズ"),
    "privateMode": MessageLookupByLibrary.simpleMessage("プライベートモード"),
    "process": MessageLookupByLibrary.simpleMessage("プロセス"),
    "profile": MessageLookupByLibrary.simpleMessage("プロファイル"),
    "profileAutoUpdateIntervalInvalidValidationDesc":
        MessageLookupByLibrary.simpleMessage("有効な間隔を入力してください"),
    "profileAutoUpdateIntervalNullValidationDesc":
        MessageLookupByLibrary.simpleMessage("自動更新間隔を入力してください"),
    "profileHasUpdate": MessageLookupByLibrary.simpleMessage(
      "プロファイルが変更されています。自動更新を無効にしますか？",
    ),
    "profileNameNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "プロファイル名を入力してください",
    ),
    "profileSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "このプロファイルにのみ適用されます。追加していない項目はデフォルト値を使用します。",
    ),
    "profileUrlInvalidValidationDesc": MessageLookupByLibrary.simpleMessage(
      "有効なプロファイルURLを入力してください",
    ),
    "profileUrlNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "プロファイルのURLを入力してください",
    ),
    "profiles": MessageLookupByLibrary.simpleMessage("プロファイル"),
    "profilesSort": MessageLookupByLibrary.simpleMessage("プロファイルの並べ替え"),
    "project": MessageLookupByLibrary.simpleMessage("プロジェクト"),
    "protocol": MessageLookupByLibrary.simpleMessage("プロトコル"),
    "protocolAuth": MessageLookupByLibrary.simpleMessage("プロトコル認証"),
    "protocolParam": MessageLookupByLibrary.simpleMessage("プロトコルパラメータ"),
    "protocolVersion": MessageLookupByLibrary.simpleMessage("プロトコルバージョン"),
    "providerInUse": m62,
    "providerInfo": MessageLookupByLibrary.simpleMessage("Provider"),
    "providerName": MessageLookupByLibrary.simpleMessage("Provider 名"),
    "providerType": MessageLookupByLibrary.simpleMessage("Provider 種別"),
    "providerUrlTip": MessageLookupByLibrary.simpleMessage("リモートリソースのみ対応しています"),
    "providers": MessageLookupByLibrary.simpleMessage("外部リソース"),
    "proxies": MessageLookupByLibrary.simpleMessage("プロキシ"),
    "proxiesCount": m63,
    "proxiesEmpty": MessageLookupByLibrary.simpleMessage("プロキシが空です"),
    "proxiesProfileLabel": m64,
    "proxiesRemovedTip": m65,
    "proxiesReplacedTip": m66,
    "proxy": MessageLookupByLibrary.simpleMessage("プロキシ"),
    "proxyAuthentication": MessageLookupByLibrary.simpleMessage("プロキシ認証"),
    "proxyAuthenticationDesc": MessageLookupByLibrary.simpleMessage(
      "ローカル mixed/SOCKS 受信にユーザー名とパスワードを要求する",
    ),
    "proxyChains": MessageLookupByLibrary.simpleMessage("プロキシチェーン"),
    "proxyGroup": MessageLookupByLibrary.simpleMessage("プロキシグループ"),
    "proxyGroupEmpty": MessageLookupByLibrary.simpleMessage("プロキシグループが空です"),
    "proxyGroupInUse": m67,
    "proxyGroupNameDuplicate": MessageLookupByLibrary.simpleMessage(
      "プロキシグループ名が重複しています",
    ),
    "proxyNetworks": MessageLookupByLibrary.simpleMessage("プロキシネットワーク"),
    "proxyProviders": MessageLookupByLibrary.simpleMessage("プロキシプロバイダー"),
    "proxyProvidersEmpty": MessageLookupByLibrary.simpleMessage(
      "プロキシプロバイダーが空です",
    ),
    "proxyProvidersNotEmpty": MessageLookupByLibrary.simpleMessage(
      "プロキシプロバイダーは空にできません",
    ),
    "proxyType": MessageLookupByLibrary.simpleMessage("プロキシタイプ"),
    "pruneCache": MessageLookupByLibrary.simpleMessage("キャッシュを整理"),
    "publicKey": MessageLookupByLibrary.simpleMessage("公開鍵"),
    "pureBlack": MessageLookupByLibrary.simpleMessage("ピュアブラック"),
    "pureBlackMode": MessageLookupByLibrary.simpleMessage("ピュアブラックモード"),
    "qrcode": MessageLookupByLibrary.simpleMessage("QRコード"),
    "qrcodeDesc": MessageLookupByLibrary.simpleMessage(
      "QRコードをスキャンしてプロファイルを取得します",
    ),
    "quicHandshakeTimedOut": MessageLookupByLibrary.simpleMessage(
      "QUIC ハンドシェイクがタイムアウトしました",
    ),
    "quicTest": MessageLookupByLibrary.simpleMessage("QUIC テスト"),
    "quicTestCustomTarget": MessageLookupByLibrary.simpleMessage("カスタム対象"),
    "quicTestCustomTargetHint": MessageLookupByLibrary.simpleMessage(
      "ホスト、ホスト:ポート、または IPv6 アドレス",
    ),
    "quicTestDesc": MessageLookupByLibrary.simpleMessage(
      "選択したノードで QUIC（HTTP/3）接続をテストします",
    ),
    "quicTestTarget": MessageLookupByLibrary.simpleMessage("QUIC テスト対象"),
    "quicVersion": MessageLookupByLibrary.simpleMessage("QUIC バージョン"),
    "quickActions": MessageLookupByLibrary.simpleMessage("クイック操作"),
    "quickEdit": MessageLookupByLibrary.simpleMessage("クイック編集"),
    "rainbowScheme": MessageLookupByLibrary.simpleMessage("レインボー"),
    "reality": MessageLookupByLibrary.simpleMessage("Reality"),
    "realityPublicKey": MessageLookupByLibrary.simpleMessage("Public Key"),
    "realityShortId": MessageLookupByLibrary.simpleMessage("Short ID"),
    "reason": MessageLookupByLibrary.simpleMessage("理由"),
    "receivedPackets": MessageLookupByLibrary.simpleMessage("受信パケット"),
    "recentRequests": MessageLookupByLibrary.simpleMessage("最近のリクエスト"),
    "recommendedIcons": MessageLookupByLibrary.simpleMessage("おすすめ"),
    "recordType": MessageLookupByLibrary.simpleMessage("レコードタイプ"),
    "redirPort": MessageLookupByLibrary.simpleMessage("Redirポート"),
    "redo": MessageLookupByLibrary.simpleMessage("やり直す"),
    "regex": MessageLookupByLibrary.simpleMessage("正規表現"),
    "releaseMemory": MessageLookupByLibrary.simpleMessage("メモリを解放"),
    "releaseMemoryFailed": MessageLookupByLibrary.simpleMessage(
      "メモリの解放に失敗しました",
    ),
    "remote": MessageLookupByLibrary.simpleMessage("リモート"),
    "remoteDestination": MessageLookupByLibrary.simpleMessage("リモート宛先"),
    "remoteDnsResolve": MessageLookupByLibrary.simpleMessage("リモート DNS 解決"),
    "remove": MessageLookupByLibrary.simpleMessage("削除"),
    "rename": MessageLookupByLibrary.simpleMessage("名前を変更"),
    "replace": MessageLookupByLibrary.simpleMessage("置換"),
    "replaceAll": MessageLookupByLibrary.simpleMessage("すべて置換"),
    "request": MessageLookupByLibrary.simpleMessage("リクエスト"),
    "requests": MessageLookupByLibrary.simpleMessage("リクエスト"),
    "requestsAndUpdates": MessageLookupByLibrary.simpleMessage("リクエストと更新"),
    "required": MessageLookupByLibrary.simpleMessage("必須"),
    "reset": MessageLookupByLibrary.simpleMessage("リセット"),
    "resetPageChangesTip": MessageLookupByLibrary.simpleMessage(
      "このページには変更があります。リセットしてもよろしいですか？",
    ),
    "resetTip": MessageLookupByLibrary.simpleMessage("リセットしてもよろしいですか？"),
    "resolvedAddress": MessageLookupByLibrary.simpleMessage("解決済みアドレス"),
    "resourceUpdateInterval": MessageLookupByLibrary.simpleMessage("自動更新間隔"),
    "resourceUpdateIntervalTip": MessageLookupByLibrary.simpleMessage(
      "自動更新間隔は0より大きくしてください",
    ),
    "resources": MessageLookupByLibrary.simpleMessage("リソース"),
    "respectRules": MessageLookupByLibrary.simpleMessage("ルールに従う"),
    "respectRulesDesc": MessageLookupByLibrary.simpleMessage(
      "ルールに従うを有効にすると DNS 接続がルールに従います。Proxy Server Nameserver の設定が必要です。",
    ),
    "responseCode": MessageLookupByLibrary.simpleMessage("応答コード"),
    "restart": MessageLookupByLibrary.simpleMessage("再起動"),
    "restartCoreTip": MessageLookupByLibrary.simpleMessage("コアを再起動してもよろしいですか？"),
    "restore": MessageLookupByLibrary.simpleMessage("復元"),
    "restoreAllData": MessageLookupByLibrary.simpleMessage("すべてのデータを復元"),
    "restoreOnlyConfig": MessageLookupByLibrary.simpleMessage("プロファイルのみ復元"),
    "restoreStrategy": MessageLookupByLibrary.simpleMessage("復元方式"),
    "restoreStrategyCompatible": MessageLookupByLibrary.simpleMessage("互換"),
    "restoreStrategyOverride": MessageLookupByLibrary.simpleMessage("上書き"),
    "restoreSuccess": MessageLookupByLibrary.simpleMessage("復元が完了しました"),
    "retry": MessageLookupByLibrary.simpleMessage("再試行"),
    "routeAddress": MessageLookupByLibrary.simpleMessage("ルートアドレス"),
    "routeExcludeAddress": MessageLookupByLibrary.simpleMessage("ルート除外アドレス"),
    "routingMark": MessageLookupByLibrary.simpleMessage("ルーティングマーク"),
    "rtt": MessageLookupByLibrary.simpleMessage("RTT"),
    "ru": MessageLookupByLibrary.simpleMessage("ロシア語"),
    "rule": MessageLookupByLibrary.simpleMessage("ルール"),
    "ruleActionAndDesc": MessageLookupByLibrary.simpleMessage("論理ルール AND"),
    "ruleActionDomainDesc": MessageLookupByLibrary.simpleMessage("完全なドメインにマッチ"),
    "ruleActionDomainKeywordDesc": MessageLookupByLibrary.simpleMessage(
      "ドメインキーワードにマッチ",
    ),
    "ruleActionDomainRegexDesc": MessageLookupByLibrary.simpleMessage(
      "ドメインの正規表現でマッチ",
    ),
    "ruleActionDomainSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "ドメインサフィックスにマッチ",
    ),
    "ruleActionDomainWildcardDesc": MessageLookupByLibrary.simpleMessage(
      "ワイルドカードでマッチ（* と ? のみ対応）",
    ),
    "ruleActionDscpDesc": MessageLookupByLibrary.simpleMessage(
      "DSCPマークにマッチ（tproxy udpインバウンドのみ）",
    ),
    "ruleActionDstPortDesc": MessageLookupByLibrary.simpleMessage(
      "宛先ポート範囲にマッチ",
    ),
    "ruleActionGeoipDesc": MessageLookupByLibrary.simpleMessage("IPの国コードにマッチ"),
    "ruleActionGeositeDesc": MessageLookupByLibrary.simpleMessage(
      "Geosite 内のドメインにマッチ",
    ),
    "ruleActionInNameDesc": MessageLookupByLibrary.simpleMessage("インバウンド名にマッチ"),
    "ruleActionInPortDesc": MessageLookupByLibrary.simpleMessage(
      "インバウンドポートにマッチ",
    ),
    "ruleActionInTypeDesc": MessageLookupByLibrary.simpleMessage(
      "インバウンドタイプにマッチ",
    ),
    "ruleActionInUserDesc": MessageLookupByLibrary.simpleMessage(
      "インバウンドユーザー名にマッチ（/ で複数指定可）",
    ),
    "ruleActionIpAsnDesc": MessageLookupByLibrary.simpleMessage(
      "IPが属するASNにマッチ",
    ),
    "ruleActionIpCidr6Desc": MessageLookupByLibrary.simpleMessage(
      "IPアドレス範囲にマッチ（IP-CIDR6 は別名です）",
    ),
    "ruleActionIpCidrDesc": MessageLookupByLibrary.simpleMessage(
      "IPアドレス範囲にマッチ",
    ),
    "ruleActionIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "IPサフィックス範囲にマッチ",
    ),
    "ruleActionMatchDesc": MessageLookupByLibrary.simpleMessage(
      "すべてのリクエストにマッチ（条件不要）",
    ),
    "ruleActionNetworkDesc": MessageLookupByLibrary.simpleMessage(
      "TCPまたはUDPにマッチ",
    ),
    "ruleActionNotDesc": MessageLookupByLibrary.simpleMessage("論理ルール NOT"),
    "ruleActionOrDesc": MessageLookupByLibrary.simpleMessage("論理ルール OR"),
    "ruleActionProcessNameDesc": MessageLookupByLibrary.simpleMessage(
      "プロセス名でマッチ（Androidではパッケージ名にマッチ）",
    ),
    "ruleActionProcessNameRegexDesc": MessageLookupByLibrary.simpleMessage(
      "プロセス名の正規表現でマッチ（Androidではパッケージ名にマッチ）",
    ),
    "ruleActionProcessNameWildcardDesc": MessageLookupByLibrary.simpleMessage(
      "プロセス名のワイルドカードでマッチ（* と ? のみ対応）",
    ),
    "ruleActionProcessPathDesc": MessageLookupByLibrary.simpleMessage(
      "プロセスのフルパスでマッチ",
    ),
    "ruleActionProcessPathRegexDesc": MessageLookupByLibrary.simpleMessage(
      "プロセスパスの正規表現でマッチ",
    ),
    "ruleActionProcessPathWildcardDesc": MessageLookupByLibrary.simpleMessage(
      "プロセスパスのワイルドカードでマッチ（* と ? のみ対応）",
    ),
    "ruleActionRematchNameDesc": MessageLookupByLibrary.simpleMessage(
      "再マッチ名にマッチ（複数は / で区切る）",
    ),
    "ruleActionRuleSetDesc": MessageLookupByLibrary.simpleMessage(
      "ルールセットを参照します。rule-providersの設定が必要です",
    ),
    "ruleActionSrcGeoipDesc": MessageLookupByLibrary.simpleMessage(
      "送信元IPの国コードにマッチ",
    ),
    "ruleActionSrcIpAsnDesc": MessageLookupByLibrary.simpleMessage(
      "送信元IPが属するASNにマッチ",
    ),
    "ruleActionSrcIpCidrDesc": MessageLookupByLibrary.simpleMessage(
      "送信元IPアドレス範囲にマッチ",
    ),
    "ruleActionSrcIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "送信元IPサフィックス範囲にマッチ",
    ),
    "ruleActionSrcPortDesc": MessageLookupByLibrary.simpleMessage(
      "送信元ポート範囲にマッチ",
    ),
    "ruleActionSubRuleDesc": MessageLookupByLibrary.simpleMessage(
      "サブルールへマッチします。括弧の使い方に注意してください",
    ),
    "ruleActionUidDesc": MessageLookupByLibrary.simpleMessage(
      "LinuxのユーザーIDにマッチ",
    ),
    "ruleEmpty": MessageLookupByLibrary.simpleMessage("ルールが空です"),
    "ruleListInvalid": MessageLookupByLibrary.simpleMessage(
      "ルールは 1 項目に 1 つのルールを書いた YAML リストにしてください。例：- DOMAIN,example.com,DIRECT",
    ),
    "ruleName": MessageLookupByLibrary.simpleMessage("ルール名"),
    "rulePresetBittorrentDirect": MessageLookupByLibrary.simpleMessage(
      "BitTorrent を直接接続",
    ),
    "rulePresetBlockDot": MessageLookupByLibrary.simpleMessage(
      "DNS over TLS をブロック",
    ),
    "rulePresetBlockLoopback": MessageLookupByLibrary.simpleMessage(
      "プロキシのループバックを防止",
    ),
    "rulePresetBlockQuic": MessageLookupByLibrary.simpleMessage("QUIC をブロック"),
    "rulePresetBlockStun": MessageLookupByLibrary.simpleMessage("STUN をブロック"),
    "rulePresetLanDirect": MessageLookupByLibrary.simpleMessage("LAN 直接接続"),
    "rulePresetSystemServicesDirect": MessageLookupByLibrary.simpleMessage(
      "Apple と Microsoft に直接接続",
    ),
    "ruleProviders": MessageLookupByLibrary.simpleMessage("ルールプロバイダー"),
    "ruleSet": MessageLookupByLibrary.simpleMessage("ルールセット"),
    "ruleSetEmptyTip": MessageLookupByLibrary.simpleMessage(
      "ルールセットに使用できるエントリがありません",
    ),
    "ruleSetInvalidTip": MessageLookupByLibrary.simpleMessage(
      "この mrs ファイルを読み込めません",
    ),
    "ruleSetMixedTip": MessageLookupByLibrary.simpleMessage(
      "ルールセットにドメインと IP 範囲が混在しているため、種類を判別できません",
    ),
    "ruleTarget": MessageLookupByLibrary.simpleMessage("ルールターゲット"),
    "ruleTextInvalid": MessageLookupByLibrary.simpleMessage(
      "ルールは対応する種類で始めてください。例：DOMAIN,example.com,DIRECT",
    ),
    "rules": MessageLookupByLibrary.simpleMessage("ルール"),
    "rulesCount": m68,
    "runTime": MessageLookupByLibrary.simpleMessage("起動時間"),
    "safeMode": MessageLookupByLibrary.simpleMessage("セーフモード"),
    "safeModeAppTitle": m69,
    "save": MessageLookupByLibrary.simpleMessage("保存"),
    "saveAndReload": MessageLookupByLibrary.simpleMessage("保存して再読み込み"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("変更を保存しますか？"),
    "scanQrcode": MessageLookupByLibrary.simpleMessage("QRコードをスキャン"),
    "script": MessageLookupByLibrary.simpleMessage("スクリプト"),
    "scriptModeDesc": MessageLookupByLibrary.simpleMessage(
      "スクリプトモード：拡張スクリプトでプロファイル全体を書き換えます",
    ),
    "scrollToSelected": MessageLookupByLibrary.simpleMessage("選択項目へスクロール"),
    "search": MessageLookupByLibrary.simpleMessage("検索"),
    "searchLocalProxy": MessageLookupByLibrary.simpleMessage(
      "名前 / プロトコル / サーバー で検索",
    ),
    "seconds": MessageLookupByLibrary.simpleMessage("秒"),
    "secondsCount": m70,
    "secretKey": MessageLookupByLibrary.simpleMessage("キー"),
    "sectionsInEffect": m71,
    "secureMode": MessageLookupByLibrary.simpleMessage("セキュアモード"),
    "security": MessageLookupByLibrary.simpleMessage("セキュリティ"),
    "selectAll": MessageLookupByLibrary.simpleMessage("すべて選択"),
    "selectNode": MessageLookupByLibrary.simpleMessage("ノードを選択"),
    "selectProtocol": MessageLookupByLibrary.simpleMessage("プロトコルを選択"),
    "selectProxies": MessageLookupByLibrary.simpleMessage("プロキシを選択"),
    "selectProxyProviders": MessageLookupByLibrary.simpleMessage(
      "プロキシプロバイダーを選択",
    ),
    "selectRuleSet": MessageLookupByLibrary.simpleMessage("ルールセットを選択してください"),
    "selectSplitStrategy": MessageLookupByLibrary.simpleMessage(
      "振り分け戦略を選択してください",
    ),
    "selectSubRule": MessageLookupByLibrary.simpleMessage("サブルールを選択してください"),
    "selectTargetGroups": MessageLookupByLibrary.simpleMessage("対象プロキシグループを選択"),
    "selected": MessageLookupByLibrary.simpleMessage("選択済み"),
    "selectedCountTitle": m72,
    "sentPackets": MessageLookupByLibrary.simpleMessage("送信パケット"),
    "server": MessageLookupByLibrary.simpleMessage("サーバー"),
    "servername": MessageLookupByLibrary.simpleMessage("サーバー名"),
    "serviceAvailable": MessageLookupByLibrary.simpleMessage("利用可能"),
    "serviceBlocked": MessageLookupByLibrary.simpleMessage("ブロック済み"),
    "serviceCheck": MessageLookupByLibrary.simpleMessage("検査"),
    "serviceCheckAll": MessageLookupByLibrary.simpleMessage("すべて検査"),
    "serviceCheckedAt": m73,
    "serviceComingSoon": MessageLookupByLibrary.simpleMessage("近日提供予定"),
    "serviceDisallowedIsp": MessageLookupByLibrary.simpleMessage(
      "許可されていない ISP",
    ),
    "serviceFailed": MessageLookupByLibrary.simpleMessage("検出に失敗しました"),
    "serviceManage": MessageLookupByLibrary.simpleMessage("サービスを管理"),
    "serviceOriginalsOnly": MessageLookupByLibrary.simpleMessage("オリジナル作品のみ"),
    "servicePending": MessageLookupByLibrary.simpleMessage("未検査"),
    "serviceRestricted": MessageLookupByLibrary.simpleMessage("アクセス制限"),
    "serviceStatus": MessageLookupByLibrary.simpleMessage("サービスの状態"),
    "serviceUnavailable": MessageLookupByLibrary.simpleMessage("利用不可"),
    "serviceUnsupportedRegion": MessageLookupByLibrary.simpleMessage("対象外の地域"),
    "settingEntries": MessageLookupByLibrary.simpleMessage("設定項目"),
    "settings": MessageLookupByLibrary.simpleMessage("設定"),
    "settingsCount": m74,
    "shareLinkUnreadable": m75,
    "shareLinksInvalid": MessageLookupByLibrary.simpleMessage(
      "リンクからプロキシを読み取れませんでした",
    ),
    "show": MessageLookupByLibrary.simpleMessage("表示"),
    "showLess": MessageLookupByLibrary.simpleMessage("折りたたむ"),
    "showMore": MessageLookupByLibrary.simpleMessage("展開"),
    "showNotificationStopAction": MessageLookupByLibrary.simpleMessage(
      "通知に停止ボタンを表示",
    ),
    "showPassword": MessageLookupByLibrary.simpleMessage("パスワードを表示"),
    "shrink": MessageLookupByLibrary.simpleMessage("コンパクト"),
    "sidebarBlur": MessageLookupByLibrary.simpleMessage("サイドバーのぼかし"),
    "sidebarBlurDesc": MessageLookupByLibrary.simpleMessage(
      "ウィンドウ背後のデスクトップをぼかしてサイドバーに透過します",
    ),
    "silentLaunch": MessageLookupByLibrary.simpleMessage("サイレント起動"),
    "silentLaunchDesc": MessageLookupByLibrary.simpleMessage(
      "サイレント起動ではウィンドウを表示しません。",
    ),
    "singleAdd": MessageLookupByLibrary.simpleMessage("個別追加"),
    "singleImport": MessageLookupByLibrary.simpleMessage("個別インポート"),
    "singleShareLinkOnly": MessageLookupByLibrary.simpleMessage(
      "ここにはリンクを 1 つだけ入力してください。複数の場合は一覧のクイック編集を使ってください",
    ),
    "singleValueTip": m76,
    "size": MessageLookupByLibrary.simpleMessage("サイズ"),
    "skipCertVerify": MessageLookupByLibrary.simpleMessage("証明書の検証をスキップ"),
    "skipDomain": MessageLookupByLibrary.simpleMessage("スキップするドメイン"),
    "skipDomainDesc": MessageLookupByLibrary.simpleMessage(
      "スキップするドメインにあるドメインを検出しても使用しません。",
    ),
    "skipDstAddress": MessageLookupByLibrary.simpleMessage("スキップする宛先アドレス"),
    "skipSrcAddress": MessageLookupByLibrary.simpleMessage("スキップする送信元アドレス"),
    "slide": MessageLookupByLibrary.simpleMessage("スライド"),
    "sni": MessageLookupByLibrary.simpleMessage("SNI"),
    "sniffProtocols": MessageLookupByLibrary.simpleMessage("プロトコル"),
    "sniffer": MessageLookupByLibrary.simpleMessage("スニッファー"),
    "snifferStatusDesc": MessageLookupByLibrary.simpleMessage(
      "スニッファーは TLS・HTTP・QUIC の通信からドメインを読み取り、ルールで照合できるようにします。",
    ),
    "socks5": MessageLookupByLibrary.simpleMessage("SOCKS5"),
    "socksPort": MessageLookupByLibrary.simpleMessage("SOCKSポート"),
    "sort": MessageLookupByLibrary.simpleMessage("並べ替え"),
    "source": MessageLookupByLibrary.simpleMessage("ソース"),
    "sourceIp": MessageLookupByLibrary.simpleMessage("送信元IP"),
    "specialProxy": MessageLookupByLibrary.simpleMessage("特殊プロキシ"),
    "specialRules": MessageLookupByLibrary.simpleMessage("特殊ルール"),
    "speedStatistics": MessageLookupByLibrary.simpleMessage("速度統計"),
    "speedTest": MessageLookupByLibrary.simpleMessage("速度テスト"),
    "speedTestCustomUrl": MessageLookupByLibrary.simpleMessage(
      "カスタムダウンロード URL",
    ),
    "speedTestCustomUrlHint": MessageLookupByLibrary.simpleMessage(
      "https://example.com/file.bin",
    ),
    "speedTestDesc": MessageLookupByLibrary.simpleMessage(
      "選択したノードでダウンロード速度をテストします",
    ),
    "speedTestPackageSize": MessageLookupByLibrary.simpleMessage(
      "速度テストのデータサイズ",
    ),
    "splitStrategy": MessageLookupByLibrary.simpleMessage("振り分け戦略"),
    "splitStrategyNotEmpty": MessageLookupByLibrary.simpleMessage(
      "振り分け戦略は空にできません",
    ),
    "ss": MessageLookupByLibrary.simpleMessage("Shadowsocks"),
    "ssh": MessageLookupByLibrary.simpleMessage("SSH"),
    "ssidsEmpty": MessageLookupByLibrary.simpleMessage("SSIDが空です"),
    "stackMode": MessageLookupByLibrary.simpleMessage("スタックモード"),
    "stackTrace": MessageLookupByLibrary.simpleMessage("スタックトレース"),
    "standard": MessageLookupByLibrary.simpleMessage("標準"),
    "standardModeDesc": MessageLookupByLibrary.simpleMessage(
      "標準モード：プロファイルにルールを追加します",
    ),
    "start": MessageLookupByLibrary.simpleMessage("開始"),
    "startFromScratch": MessageLookupByLibrary.simpleMessage("最初から作成"),
    "startTest": MessageLookupByLibrary.simpleMessage("テスト開始"),
    "startVpn": MessageLookupByLibrary.simpleMessage("VPNを起動しています…"),
    "startupAndBackground": MessageLookupByLibrary.simpleMessage("起動とバックグラウンド"),
    "stateDir": MessageLookupByLibrary.simpleMessage("状態ディレクトリ"),
    "status": MessageLookupByLibrary.simpleMessage("状態"),
    "statusDesc": MessageLookupByLibrary.simpleMessage(
      "DNS を無効にすると、システム DNS を使用します。",
    ),
    "stop": MessageLookupByLibrary.simpleMessage("停止"),
    "stopVpn": MessageLookupByLibrary.simpleMessage("VPNを停止しています…"),
    "strategy": MessageLookupByLibrary.simpleMessage("戦略"),
    "strictRoute": MessageLookupByLibrary.simpleMessage("厳格なルーティング"),
    "strictRouteDesc": MessageLookupByLibrary.simpleMessage(
      "厳格なルーティングは DNS などの通信が TUN を迂回するのを防ぎます。有効にすると他のデバイスからこの端末にアクセスできなくなります。",
    ),
    "style": MessageLookupByLibrary.simpleMessage("スタイル"),
    "subRule": MessageLookupByLibrary.simpleMessage("サブルール"),
    "subRuleEmpty": MessageLookupByLibrary.simpleMessage("サブルールが空です"),
    "subRuleNotEmpty": MessageLookupByLibrary.simpleMessage("サブルールは空にできません"),
    "submit": MessageLookupByLibrary.simpleMessage("送信"),
    "subscriptionInfo": MessageLookupByLibrary.simpleMessage("サブスクリプション情報"),
    "sudoPasswordTitle": MessageLookupByLibrary.simpleMessage("sudo のパスワードを入力"),
    "supportX25519Mlkem768": MessageLookupByLibrary.simpleMessage(
      "Support X25519MLKEM768",
    ),
    "supportedProtocols": MessageLookupByLibrary.simpleMessage("対応プロトコル"),
    "suspended": MessageLookupByLibrary.simpleMessage("一時停止中…"),
    "switchProfile": MessageLookupByLibrary.simpleMessage("プロファイルを切り替え"),
    "sync": MessageLookupByLibrary.simpleMessage("同期"),
    "system": MessageLookupByLibrary.simpleMessage("システム"),
    "systemApp": MessageLookupByLibrary.simpleMessage("システムアプリ"),
    "systemProxy": MessageLookupByLibrary.simpleMessage("システムプロキシ"),
    "tab": MessageLookupByLibrary.simpleMessage("タブ"),
    "tabAnimation": MessageLookupByLibrary.simpleMessage("タブアニメーション"),
    "tabAnimationDesc": MessageLookupByLibrary.simpleMessage("モバイル表示でのみ有効"),
    "tapToAuthorize": MessageLookupByLibrary.simpleMessage("タップして許可"),
    "tcpConcurrent": MessageLookupByLibrary.simpleMessage("TCP同時接続"),
    "testFailed": MessageLookupByLibrary.simpleMessage("テスト失敗"),
    "testInterval": MessageLookupByLibrary.simpleMessage("テスト間隔"),
    "testStage": MessageLookupByLibrary.simpleMessage("ステージ"),
    "testTarget": MessageLookupByLibrary.simpleMessage("ターゲット"),
    "testUrl": MessageLookupByLibrary.simpleMessage("テストURL"),
    "testWhenUsed": MessageLookupByLibrary.simpleMessage("使用時にテスト"),
    "testing": MessageLookupByLibrary.simpleMessage("テスト中..."),
    "textScale": MessageLookupByLibrary.simpleMessage("テキストの拡大縮小"),
    "textScalePreview": MessageLookupByLibrary.simpleMessage(
      "アプリ内の文字はこの大きさで表示されます",
    ),
    "theme": MessageLookupByLibrary.simpleMessage("テーマ"),
    "themeColor": MessageLookupByLibrary.simpleMessage("テーマカラー"),
    "themeDesc": MessageLookupByLibrary.simpleMessage("ダークモードの設定と色の調整"),
    "themeMode": MessageLookupByLibrary.simpleMessage("テーマモード"),
    "tight": MessageLookupByLibrary.simpleMessage("コンパクト"),
    "time": MessageLookupByLibrary.simpleMessage("時刻"),
    "timeout": MessageLookupByLibrary.simpleMessage("タイムアウト"),
    "tip": MessageLookupByLibrary.simpleMessage("ヒント"),
    "tldDnsZone": MessageLookupByLibrary.simpleMessage("TLD DNS ゾーン"),
    "tls": MessageLookupByLibrary.simpleMessage("TLS"),
    "toggle": MessageLookupByLibrary.simpleMessage("切り替え"),
    "tolerance": MessageLookupByLibrary.simpleMessage("許容値"),
    "tonalSpotScheme": MessageLookupByLibrary.simpleMessage("トーナルスポット"),
    "tools": MessageLookupByLibrary.simpleMessage("ツール"),
    "torch": MessageLookupByLibrary.simpleMessage("ライト"),
    "total": MessageLookupByLibrary.simpleMessage("合計"),
    "totalTraffic": MessageLookupByLibrary.simpleMessage("合計トラフィック"),
    "tproxyPort": MessageLookupByLibrary.simpleMessage("TProxyポート"),
    "trafficUsage": MessageLookupByLibrary.simpleMessage("トラフィック統計"),
    "transport": MessageLookupByLibrary.simpleMessage("トランスポート"),
    "transportSettings": MessageLookupByLibrary.simpleMessage("転送設定"),
    "trojan": MessageLookupByLibrary.simpleMessage("Trojan"),
    "tun": MessageLookupByLibrary.simpleMessage("TUN"),
    "tunAuthorizationFailed": MessageLookupByLibrary.simpleMessage(
      "TUN の権限を取得できなかったため、オフにしました。",
    ),
    "tunDesc": MessageLookupByLibrary.simpleMessage("TUN は管理者モードでのみ有効です。"),
    "turnOff": MessageLookupByLibrary.simpleMessage("オフにする"),
    "turnOn": MessageLookupByLibrary.simpleMessage("オンにする"),
    "udp": MessageLookupByLibrary.simpleMessage("UDP"),
    "udpRelayMode": MessageLookupByLibrary.simpleMessage("UDP リレーモード"),
    "undo": MessageLookupByLibrary.simpleMessage("元に戻す"),
    "unifiedDelay": MessageLookupByLibrary.simpleMessage("統一遅延"),
    "unknown": MessageLookupByLibrary.simpleMessage("不明"),
    "unknownNetworkError": MessageLookupByLibrary.simpleMessage("不明なネットワークエラー"),
    "unlockReasonBootstrapFailed": MessageLookupByLibrary.simpleMessage(
      "一時セッションの初期化に失敗しました",
    ),
    "unlockReasonContentLimited": MessageLookupByLibrary.simpleMessage(
      "一部のコンテンツのみ利用できます",
    ),
    "unlockReasonGeoBlocked": MessageLookupByLibrary.simpleMessage(
      "この地域では利用できません",
    ),
    "unlockReasonNetworkError": MessageLookupByLibrary.simpleMessage(
      "ネットワークリクエストに失敗しました",
    ),
    "unlockReasonRateLimited": MessageLookupByLibrary.simpleMessage(
      "サービスのレート制限に達しました",
    ),
    "unlockReasonTimeout": MessageLookupByLibrary.simpleMessage(
      "リクエストがタイムアウトしました",
    ),
    "unlockReasonUnexpectedResponse": MessageLookupByLibrary.simpleMessage(
      "サービスの応答を認識できません",
    ),
    "unlockReasonVpnBlocked": MessageLookupByLibrary.simpleMessage(
      "プロキシまたは VPN が拒否されました",
    ),
    "unlockTest": MessageLookupByLibrary.simpleMessage("アンロック検出"),
    "unlockTestAll": MessageLookupByLibrary.simpleMessage("すべて"),
    "unlockTestClearAll": MessageLookupByLibrary.simpleMessage("すべて解除"),
    "unlockTestCurrentResults": MessageLookupByLibrary.simpleMessage("現在の結果"),
    "unlockTestDesc": MessageLookupByLibrary.simpleMessage(
      "選択したノードで AI・メディアサービスの利用可否を検出",
    ),
    "unlockTestDisabledTip": MessageLookupByLibrary.simpleMessage(
      "アンロック検出ページで有効化してください",
    ),
    "unlockTestDone": MessageLookupByLibrary.simpleMessage("完了"),
    "unlockTestEnable": MessageLookupByLibrary.simpleMessage("アンロック検出を有効化"),
    "unlockTestError": MessageLookupByLibrary.simpleMessage("検出エラー"),
    "unlockTestFollowRules": MessageLookupByLibrary.simpleMessage(
      "現在のルーティングに従う",
    ),
    "unlockTestGroupEurope": MessageLookupByLibrary.simpleMessage("英国・欧州"),
    "unlockTestGroupGlobalMedia": MessageLookupByLibrary.simpleMessage(
      "グローバルメディア",
    ),
    "unlockTestGroupHongKongTaiwan": MessageLookupByLibrary.simpleMessage(
      "香港・台湾",
    ),
    "unlockTestGroupJapan": MessageLookupByLibrary.simpleMessage("日本"),
    "unlockTestGroupKorea": MessageLookupByLibrary.simpleMessage("韓国"),
    "unlockTestHistory": MessageLookupByLibrary.simpleMessage("最近の検出"),
    "unlockTestHistoryResult": MessageLookupByLibrary.simpleMessage("履歴結果"),
    "unlockTestNoResults": MessageLookupByLibrary.simpleMessage("検出結果はまだありません"),
    "unlockTestPartial": MessageLookupByLibrary.simpleMessage("一部利用可能"),
    "unlockTestRegion": MessageLookupByLibrary.simpleMessage("地域"),
    "unlockTestResetDefault": MessageLookupByLibrary.simpleMessage("初期設定に戻す"),
    "unlockTestSearch": MessageLookupByLibrary.simpleMessage("サービスを検索"),
    "unlockTestSelectAll": MessageLookupByLibrary.simpleMessage("すべて選択"),
    "unlockTestSelectTargets": MessageLookupByLibrary.simpleMessage("サービスを選択"),
    "unlockTestSpecifiedNode": MessageLookupByLibrary.simpleMessage("指定ノード"),
    "unlockTestStop": MessageLookupByLibrary.simpleMessage("検出を停止"),
    "unlockTestUntested": MessageLookupByLibrary.simpleMessage("未検出"),
    "unlocked": MessageLookupByLibrary.simpleMessage("解除済み"),
    "unmaximize": MessageLookupByLibrary.simpleMessage("元に戻す"),
    "unnamed": MessageLookupByLibrary.simpleMessage("名称未設定"),
    "unpinWindow": MessageLookupByLibrary.simpleMessage("固定を解除"),
    "up": MessageLookupByLibrary.simpleMessage("アップ"),
    "update": MessageLookupByLibrary.simpleMessage("更新"),
    "upload": MessageLookupByLibrary.simpleMessage("アップロード"),
    "uploadBandwidth": MessageLookupByLibrary.simpleMessage("アップロード帯域幅"),
    "uploadCarrier": MessageLookupByLibrary.simpleMessage("アップロードキャリア"),
    "url": MessageLookupByLibrary.simpleMessage("URL"),
    "urlTip": m77,
    "useHosts": MessageLookupByLibrary.simpleMessage("Hostsを使用"),
    "useSystemHosts": MessageLookupByLibrary.simpleMessage("システムのHostsを使用"),
    "usedTraffic": MessageLookupByLibrary.simpleMessage("使用済みトラフィック"),
    "userAgent": MessageLookupByLibrary.simpleMessage("User-Agent"),
    "username": MessageLookupByLibrary.simpleMessage("ユーザー名"),
    "uuid": MessageLookupByLibrary.simpleMessage("UUID"),
    "value": MessageLookupByLibrary.simpleMessage("値"),
    "vibrantScheme": MessageLookupByLibrary.simpleMessage("ビブラント"),
    "view": MessageLookupByLibrary.simpleMessage("表示"),
    "virtualIpv4": MessageLookupByLibrary.simpleMessage("仮想 IPv4"),
    "vless": MessageLookupByLibrary.simpleMessage("VLESS"),
    "vpnConfigChangeDetected": MessageLookupByLibrary.simpleMessage(
      "VPN関連の設定変更を検出しました",
    ),
    "vpnEnableDesc": MessageLookupByLibrary.simpleMessage(
      "VPN は VpnService でシステムの全トラフィックを自動的にルーティングします。",
    ),
    "vpnTip": MessageLookupByLibrary.simpleMessage("変更はVPNの再起動後に有効になります"),
    "warmBackoffInitial": MessageLookupByLibrary.simpleMessage(
      "ウォームバックオフ初期値（秒）",
    ),
    "warmBackoffMax": MessageLookupByLibrary.simpleMessage("ウォームバックオフ最大値（秒）"),
    "webDAVConfiguration": MessageLookupByLibrary.simpleMessage("WebDAV設定"),
    "whitelistMode": MessageLookupByLibrary.simpleMessage("ホワイトリストモード"),
    "wifiWatchExcluded": MessageLookupByLibrary.simpleMessage("除外対象"),
    "wifiWatchExcludedInactive": MessageLookupByLibrary.simpleMessage(
      "除外対象（非アクティブ）",
    ),
    "wifiWatchExcludedWillSuspend": m78,
    "wifiWatchListening": MessageLookupByLibrary.simpleMessage("Watching..."),
    "wifiWatchNoWifi": MessageLookupByLibrary.simpleMessage("No WiFi"),
    "wifiWatchResolving": MessageLookupByLibrary.simpleMessage(
      "Resolving SSID...",
    ),
    "wifiWatchSuspendingNow": MessageLookupByLibrary.simpleMessage(
      "Suspending...",
    ),
    "wifiWatchTitle": MessageLookupByLibrary.simpleMessage("On Demand"),
    "wifiWatchTrusted": MessageLookupByLibrary.simpleMessage("Trusted network"),
    "wifiWatchWillSuspend": m79,
    "writeToSystem": MessageLookupByLibrary.simpleMessage("システムに書き込む"),
    "writeToSystemDesc": MessageLookupByLibrary.simpleMessage(
      "システムに書き込むを有効にするとシステムクロックも設定します。Android では無視されます。",
    ),
    "wsHost": MessageLookupByLibrary.simpleMessage("Host"),
    "wsPath": MessageLookupByLibrary.simpleMessage("パス"),
    "xhttpAdvanced": MessageLookupByLibrary.simpleMessage("XHTTP 詳細"),
    "xhttpMode": MessageLookupByLibrary.simpleMessage("XHTTP Mode"),
    "yearsAgo": m80,
    "yearsAgoShort": m81,
    "yes": MessageLookupByLibrary.simpleMessage("はい"),
    "zhCN": MessageLookupByLibrary.simpleMessage("簡体字中国語"),
  };
}
