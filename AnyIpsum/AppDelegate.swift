import Cocoa
import MASShortcut

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var menuBar: NSMenu!

    var preferencesController: NSWindowController?
    
    let statusItem = NSStatusBar
        .system
        .statusItem(withLength: NSStatusItem.variableLength)

    // MARK: - Initialization

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create menu icon and handle inverted appearance
        let menuIcon = NSImage(named: "MenuIcon")
        menuIcon!.isTemplate = true
        statusItem.image = menuIcon
        statusItem.menu = menuBar
        
        // Initialize lorem ipsum variations
        guard let path = Bundle.main.path(forResource: "Ipsum", ofType: "plist") else {
            return
        }

        guard let ipsumTexts = NSDictionary(contentsOfFile: path) else {
            return
        }

        // Read list of variations and add as menu items
        var index = 0

        for (name, words) in ipsumTexts {
            let menuItem = MenuItem(
                title: name as! String,
                actionClosure: {
                    // When selecting a menu item; create a paragraph and copy it to the pasteboard
                    let paragraph = Paragraph(words as! String)
                    self.writeToPasteboard(paragraph.text)
                },
                keyEquivalent: index < 10 ? "\(ipsumTexts.count - index)" : ""
            )

            menuBar.insertItem(menuItem, at: 0)

            index += 1
        }
        
        // Register keyboard shortcut
        MASShortcutBinder.shared()?.bindShortcut(withDefaultsKey: ShortcutManager.defaultsKey, toAction: openMenu)
    }
    
    func openMenu() {
        statusItem.popUpMenu(menuBar)
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        MASShortcutMonitor.shared().unregisterAllShortcuts()
    }

    func writeToPasteboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: NSPasteboard.PasteboardType.string)
    }

    // MARK: - Actions

    @IBAction func quit(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
    @IBAction func showPreferences(_ sender: Any) {
        if preferencesController == nil {
            let storyboard = NSStoryboard(name: "Preferences", bundle: nil)
            preferencesController = storyboard.instantiateInitialController() as? NSWindowController
        }
        
        preferencesController?.showWindow(sender)
    }
}
