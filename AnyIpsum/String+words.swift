//
//  String+paragraph.swift
//  AnyIpsum
//
//  Created by Joacim Löwgren on 13/07/16.
//  Copyright © 2016 Joacim Löwgren. All rights reserved.
//

import Foundation

extension String {
    var words: [String] {
        get {
            return componentsSeparatedByCharactersInSet(.punctuationCharacterSet())
                .joinWithSeparator("")
                .componentsSeparatedByString(" ")
                .filter { !$0.isEmpty }
        }
    }
    
    func condenseWhitespace() -> String {
        let components = componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        return components
            .filter { !$0.isEmpty }
            .joinWithSeparator(" ")
    }
    
    func capitalizingFirstLetter() -> String {
        let first = String(characters.prefix(1)).capitalizedString
        let other = String(characters.dropFirst())
        return first + other
    }
}