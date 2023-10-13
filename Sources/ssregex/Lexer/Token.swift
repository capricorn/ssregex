//
//  File.swift
//  
//
//  Created by Collin Palmer on 10/13/23.
//

import Foundation

@available(macOS 13.0, *)
extension Lex {
    public enum Token: Equatable {
        public enum Quantifier: Equatable {
            case zeroOrMore
            case zeroOrOne
            case oneOrMore
            case exact(k: Int)
            
            var regex: String {
                switch self {
                case .zeroOrMore:
                    "*"
                case .zeroOrOne:
                    "?"
                case .oneOrMore:
                    "+"
                case .exact(k: let k):
                    "{\(k)}"
                }
            }
        }
        
        public enum Paren {
            case left
            case right
        }
        
        /*
        public enum CurlyBrace {
            case left
            case right
        }
         */
        
        public enum Special: String {
            case digit = #"\d"#
            case space = #"\s"#
        }
        
        //case brace(CurlyBrace)
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
