import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // The compact layouts have a floor of their own; below this the
    // window is narrower than anything the app is designed to draw.
    self.minSize = NSSize(width: 480, height: 600)

    // Reopen where the window was left. On a first run there is nothing
    // saved, and the storyboard's 800x600 would greet the user with the
    // collapsed icon rail — so open wide enough to clear the app's own
    // `large` breakpoint (1200) and show the labelled sidebar.
    let autosaveName = "LingoDeskMainWindow"
    if !self.setFrameUsingName(autosaveName) {
      self.setContentSize(NSSize(width: 1440, height: 900))
      self.center()
    }
    self.setFrameAutosaveName(autosaveName)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
