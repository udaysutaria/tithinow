import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let windowChannel = FlutterMethodChannel(
      name: "com.example.tithinow/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    windowChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(false)
        return
      }
      if call.method == "restoreAndFocus" {
        NSApp.activate(ignoringOtherApps: true)
        if self.isMiniaturized {
          self.deminiaturize(nil)
        }
        self.makeKeyAndOrderFront(nil)
        self.orderFrontRegardless()
        if !self.isZoomed {
          self.zoom(nil)
        }
        result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    self.backgroundColor = NSColor(red: 0x12 / 255.0, green: 0x14 / 255.0, blue: 0x14 / 255.0, alpha: 1.0)
    self.minSize = NSSize(width: 720, height: 600)

    super.awakeFromNib()
  }
}
