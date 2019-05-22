import Cocoa

class MenuItem: NSMenuItem {
    var actionClosure: () -> ()
    
    init(title: String, actionClosure: @escaping () -> (), keyEquivalent: String) {
        self.actionClosure = actionClosure
        super.init(title: title, action: #selector(MenuItem.action(_:)), keyEquivalent: keyEquivalent)
        self.target = self
    }
    
    required init(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func action(_ sender: NSMenuItem) {
        self.actionClosure()
    }
}
