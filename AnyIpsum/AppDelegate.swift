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
    
    let statusItem = NSStatusBar
        .system
        .statusItem(withLength: NSStatusItem.variableLength)
    
    // MARK: - Initialization
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create menu icon and handle inverted appearance
        let menuIcon = NSImage(named: NSImage.Name(rawValue: "MenuIcon"))
        menuIcon!.isTemplate = true
        statusItem.image = menuIcon
        statusItem.menu = menuBar
        
        // Path to list of ipsum variations
        guard let path = Bundle.main.path(forResource: "Ipsum", ofType: "plist") else {
            return
        }
        
        // Dictionary of ipsum variations
        guard let ipsumTexts = NSDictionary(contentsOfFile: path) else {
            return
        }
        
        // Read list of ipsum variants and add as menu items
        var index = 0
        
        // Build paragraph
        for (name, words) in ipsumTexts {
            let menuItem = AIMenuItem(
                title: name as! String,
                actionClosure: {
                    let p = AIParagraph(words as! String)
                    self.writeToPasteboard(p.paragraph)
                },
                keyEquivalent: "\(ipsumTexts.count - index)"
            )
            
            menuBar.insertItem(menuItem, at: 0)
            
            index += 1
        }
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
}
