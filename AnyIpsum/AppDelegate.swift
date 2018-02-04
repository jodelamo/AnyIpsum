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
        
        // Read list of ipsum variants and add as menu items
        if let path = Bundle.main.path(forResource: "Ipsum", ofType: "plist") {
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
                    
                    menuBar.insertItem(menuItem, at: 0)
                    
                    index += 1
                }
            }
        }
    }

    // MARK: - Functions
    
    func createParagraph(_ text: String) -> String {
        let MaxSentences: UInt32 = 7
        let MinSentences: UInt32 = 5
        var paragraph = ""
        
        let sentenceCount = Int(arc4random_uniform(MaxSentences) + MinSentences)
        
        for _ in 0...sentenceCount {
            paragraph += self.createSentence(text)
        }
        
        return paragraph
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    func createSentence(_ text: String) -> String {
        let MaxWords: UInt32 = 8
        let MinWords: UInt32 = 5
        let words = text.words
        let wordCount = Int(arc4random_uniform(MaxWords) + MinWords)
        var sentence = ""
        
        for _ in 0...wordCount {
            let randomWordIndex = Int(arc4random_uniform(UInt32(words.count)))
            sentence += "\(words[randomWordIndex]) "
        }
        
        return sentence
            .condenseWhitespace().lowercased()
            .capitalizeFirstLetter() + ". "
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
