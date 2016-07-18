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
        .systemStatusBar()
        .statusItemWithLength(NSVariableStatusItemLength)
    
    // MARK: - Initialization
    
    func applicationDidFinishLaunching(notification: NSNotification) {
        // Create menu icon and handle inverted appearance
        let menuIcon = NSImage(named: "MenuIcon")
        menuIcon!.template = true
        
        statusItem.image = menuIcon
        statusItem.menu = menuBar
        
        // Read list of ipsum variants and add as menu items
        if let path = NSBundle.mainBundle().pathForResource("Ipsum", ofType: "plist") {
            if let ipsumTexts = NSDictionary(contentsOfFile: path) {
                var index = 0
                
                for (name, text) in ipsumTexts {
                    let menuItem = AIMenuItem(
                        title: name as! String,
                        actionClosure: {
                            let paragraph = self.createParagraph(text as! String)
                            self.writeToPasteboard(paragraph)
                        },
                        keyEquivalent: "\(ipsumTexts.count - index)"
                    )
                    
                    menuBar.insertItem(menuItem, atIndex: 0)
                    
                    index += 1
                }
            }
        }
    }

    // MARK: - Functions
    
    func createParagraph(text: String) -> String {
        var paragraph = "";
        
        let sentenceCount = Int(arc4random_uniform(10) + 5)
        
        for _ in 0...sentenceCount {
            paragraph += self.createSentence(text)
        }
        
        return paragraph
            .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
    
    func createSentence(text: String) -> String {
        let words = text.words
        let wordCount = Int(arc4random_uniform(10) + 5)
        var sentence = ""
        
        for _ in 0...wordCount {
            let randomWordIndex = Int(arc4random_uniform(UInt32(words.count)))
            sentence += "\(words[randomWordIndex]) "
        }
        
        return sentence
            .condenseWhitespace()
            .lowercaseString
            .capitalizeFirstLetter() + ". "
    }
    
    func writeToPasteboard(text: String) {
        let pasteboard = NSPasteboard.generalPasteboard()
        pasteboard.clearContents()
        pasteboard.setString(text, forType: NSPasteboardTypeString)
    }
    
    // MARK: - Actions

    @IBAction func quit(sender: NSMenuItem) {
        NSApplication.sharedApplication().terminate(self)
    }
}