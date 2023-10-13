//
//  File.swift
//  
//
//  Created by Collin Palmer on 10/13/23.
//

import Foundation

@available(macOS 13.0, *)
extension Lex {
    enum Token {
        enum Quantifier: String {
            case zeroOrMore = "*"
            case zeroOrOne = "?"  // ?
            case oneOrMore = "+" // +
            // TODO: Needs to store k count
            case exact = "{}"
        }
        
        enum Paren {
            case left
            case right
        }
        
        enum Special: String {
            case digit = #"\d"#
            case space = #"\s"#
        }
        
        case paren(type: Paren, index: Int)
        case string(value: String)
        case quantifier(Quantifier)
        case union
        /*
        case bracket(index: Int)
        // '-' token
        case range
        */
        case specialChar(Special)
        
        var isString: Bool {
            if case .string(_) = self {
                return true
            }
            
            return false
        }
        
        var isSpecial: Bool {
            if case .specialChar(_) = self {
                return true
            }
            return false
        }
    }
}
