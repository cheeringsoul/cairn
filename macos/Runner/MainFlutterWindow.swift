import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Start compact for the onboarding flow (vertical card, ~560px
    // column). Flutter invokes the "window/resizeForShell" method
    // over the method channel once onboarding finishes to expand
    // the window for the three-pane chat shell.
    self.setContentSize(NSSize(width: 560, height: 720))
    self.contentMinSize = NSSize(width: 520, height: 600)
    self.center()

    // Let the sidebar color flow under the traffic-light area so the
    // top titlebar line doesn't cut across the leftmost pane.
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.styleMask.insert(.fullSizeContentView)
    self.isMovableByWindowBackground = true

    let channel = FlutterMethodChannel(
      name: "cairn/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      switch call.method {
      case "resizeForShell":
        // Expand & re-center for the main chat shell.
        self.contentMinSize = NSSize(width: 960, height: 640)
        let target = NSSize(width: 1160, height: 760)
        self.setContentSize(target)
        self.center()
        result(nil)
      case "resizeForOnboarding":
        // Shrink back (e.g. user signs out). Rarely used.
        self.contentMinSize = NSSize(width: 520, height: 600)
        self.setContentSize(NSSize(width: 560, height: 720))
        self.center()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
