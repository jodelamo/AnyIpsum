//
//  String+capitalizeFirstLetter.swift
//  AnyIpsum
//
//  Created by Joacim Löwgren on 18/07/16.
//  Copyright © 2016 Joacim Löwgren. All rights reserved.
//

import Foundation

extension String {
    func capitalizeFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
}
