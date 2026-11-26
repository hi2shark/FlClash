import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
    private var iconMode: String = "auto"
    private var appearanceObservation: NSKeyValueObservation?
    private var hiddenAtLaunch = false

    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)

        FlutterMethodChannel(
            name: "com.hi2shark.hi2nw/app",
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
        // Only the first order hides the window, which Dart shows once it is configured.
        if !hiddenAtLaunch {
            hiddenAtLaunch = true
            setIsVisible(false)
        }
    }
}
