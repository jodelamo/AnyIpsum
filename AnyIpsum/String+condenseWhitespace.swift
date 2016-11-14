//
//  String+condenseWhitespace.swift
//  AnyIpsum
//
//  Created by Joacim Löwgren on 18/07/16.
//  Copyright © 2016 Joacim Löwgren. All rights reserved.
//

import Foundation

extension String {
    func condenseWhitespace() -> String {
        let components = self.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        return components
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
