import Cocoa
import MASShortcut

class PreferencesViewController: NSViewController, NSApplicationDelegate {

    @IBOutlet weak var shortcutView: MASShortcutView!
    
    let appDelegate = NSApp.delegate as! AppDelegate
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        shortcutView.associatedUserDefaultsKey = ShortcutManager.defaultsKey;
        
        shortcutView.shortcutValueChange = { (sender) in
            MASShortcutMonitor.shared().register(self.shortcutView.shortcutValue, withAction: self.appDelegate.openMenu)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func useDefault(_ sender: Any) {
        shortcutView.shortcutValue = ShortcutManager.defaultShortcut
    }
    
    @IBAction func visitGitHubRepository(_ sender: Any) {
        let url = URL(string: "https://github.com/jlowgren/AnyIpsum")!
        NSWorkspace.shared.open(url)
    }
}
