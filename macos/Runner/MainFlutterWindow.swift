import Cocoa
import FlutterMacOS
import window
import LaunchAtLogin

class MainFlutterWindow: NSWindow {
    private var iconMode: String = "auto"
    private var appearanceObservation: NSKeyValueObservation?

    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)

        FlutterMethodChannel(
            name: "launch_at_startup", binaryMessenger: flutterViewController.engine.binaryMessenger
        )
        .setMethodCallHandler { (_ call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "launchAtStartupIsEnabled":
                result(LaunchAtLogin.isEnabled)
            case "launchAtStartupSetEnabled":
                if let arguments = call.arguments as? [String: Any] {
                    LaunchAtLogin.isEnabled = arguments["setEnabledValue"] as! Bool
                }
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        FlutterMethodChannel(
            name: "com.hi2shark.flclash_nw/app",
            binaryMessenger: flutterViewController.engine.binaryMessenger
        )
        .setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "setLauncherIcon":
                if let arguments = call.arguments as? [String: Any],
                   let mode = arguments["mode"] as? String {
                    self?.iconMode = mode
                    self?.applyDockIcon()
                }
                result(true)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        appearanceObservation = NSApp.observe(\.effectiveAppearance, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.applyDockIcon()
            }
        }
        applyDockIcon()

        RegisterGeneratedPlugins(registry: flutterViewController)
        super.awakeFromNib()
    }

    private func applyDockIcon() {
        let useDark: Bool
        switch iconMode {
        case "dark":
            useDark = true
        case "light":
            useDark = false
        default:
            useDark = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        }
        NSApp.applicationIconImage = useDark ? NSImage(named: "AppIconDark") : nil
    }

    override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
        super.order(place, relativeTo: otherWin)
        hiddenWindowAtLaunch()
    }
}
