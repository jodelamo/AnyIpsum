//
//  AppDelegate.swift
//  AnyIpsum
//
//  Created by Joacim Löwgren on 09/07/16.
//  Copyright © 2016 Joacim Löwgren. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var menuBar: NSMenu!
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
    
    // MARK: - Initialization
    
    func applicationDidFinishLaunching(notification: NSNotification) {
        // Create menu icon and handle inverted appearance
        let menuIcon = NSImage(named: "MenuIcon")
        menuIcon!.template = true
        
        statusItem.image = menuIcon
        statusItem.menu = menuBar
        
        // Read list of ipsum variants and add as menu items
        if let path = NSBundle.mainBundle().pathForResource("Ipsum", ofType: "plist") {
            if let ipsums = NSDictionary(contentsOfFile: path) {
                var index = 0
                
                for (name, text) in ipsums {
                    let menuItem = AIMenuItem(
                        title: name as! String,
                        actionClosure: {
                            self.writeToPasteboard(text as! String)
                        },
                        keyEquivalent: "\(ipsums.count - index)"
                    )
                    
                    menuBar.insertItem(menuItem, atIndex: 0)
                    
                    index += 1
                }
            }
        }
    }
    
    // MARK: - Functions
    
    func writeToPasteboard(text: String) {
        let pasteboard = NSPasteboard.generalPasteboard()
        pasteboard.clearContents()
        pasteboard.setString(text, forType: NSPasteboardTypeString)
    }

    @IBAction func quit(sender: NSMenuItem) {
        NSApplication.sharedApplication().terminate(self);
    }
}