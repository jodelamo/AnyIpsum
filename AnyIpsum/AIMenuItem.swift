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
    
    init(title: String, actionClosure: () -> (), keyEquivalent: String) {
        self.actionClosure = actionClosure
        super.init(title: title, action: #selector(AIMenuItem.action(_:)), keyEquivalent: keyEquivalent)
        self.target = self
    }
    
    func action(sender: NSMenuItem) {
        self.actionClosure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}