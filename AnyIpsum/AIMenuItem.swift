//
//  AIMenuItem.swift
//  AnyIpsum
//
//  Created by Joacim Löwgren on 09/07/16.
//  Copyright © 2016 Joacim Löwgren. All rights reserved.
//

import Cocoa

class AIMenuItem: NSMenuItem {
    var actionClosure: () -> ()
    
    init(title: String, actionClosure: @escaping () -> (), keyEquivalent: String) {
        self.actionClosure = actionClosure
        super.init(title: title, action: #selector(AIMenuItem.action(_:)), keyEquivalent: keyEquivalent)
        self.target = self
    }
    
    required init(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func action(_ sender: NSMenuItem) {
        self.actionClosure()
    }
}
