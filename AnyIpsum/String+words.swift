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
            return components(separatedBy: .punctuationCharacters)
                .joined(separator: "")
                .components(separatedBy: " ")
                .filter { !$0.isEmpty }
        }
    }
}
