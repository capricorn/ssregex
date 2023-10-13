//
//  Lexer.swift
//  
//
//  Created by Collin Palmer on 10/13/23.
//

import Foundation

@available(macOS 13.0, *)
public enum Lex {
    struct TokenError: Error {}
    
    private enum State {
        case string(startIndex: Int)
        case none
    }
    
    static func lex(_ input: String) throws -> [Token] {
        // Implement a simple state machine for lexing (necessary for string capture)
        // For initial implementation, _do not_ support escapes
        var tokens: [Token] = []
        var state: State = .none
        
        let ascii = { (char: String) in
            let regex = try? Regex(#"[a-zA-Z\d\-!*#$%&]"#)
            return (try? regex?.wholeMatch(in: char)?.isEmpty == false) ?? false
        }
        
        // TODO: Need to be able to manipulate the index for things such as `\d`, etc.
        //for (index, char) in input.enumerated() {
        var index = 0
        while (index < input.count) {
            let char = input[input.index(input.startIndex, offsetBy: index)..<input.index(input.startIndex, offsetBy: index+1)]
            
            if case let .string(startIndex) = state {
                if ascii(String(char)) == false {
                    let str = input[input.index(input.startIndex, offsetBy: startIndex)..<input.index(input.startIndex, offsetBy: index)]
                    tokens.append(.string(value: String(str)))
                    state = .none
                } else if index == input.count-1 {
                    let str = input[input.index(input.startIndex, offsetBy: startIndex)...]
                    tokens.append(.string(value: String(str)))
                    state = .none
                    break
                }
            }
                
            switch char {
            case "(":
                tokens.append(.paren(type: .left, index: index))
            case ")":
                tokens.append(.paren(type: .right, index: index))
            case "+":
                tokens.append(.quantifier(.oneOrMore))
            case "*":
                tokens.append(.quantifier(.zeroOrMore))
            case "?":
                tokens.append(.quantifier(.zeroOrOne))
            case _ where ascii(String(char)):
                if case .string(_) = state {
                    break
                }
                if index == input.count-1 {
                    tokens.append(.string(value: String(char)))
                }
                state = .string(startIndex: index)
            case "\\":
                // TODO: Throw error given validation issues
                let special = String(input[input.index(input.startIndex, offsetBy: index)..<input.index(input.startIndex, offsetBy: index+2)])
                tokens.append(.specialChar(.init(rawValue: special)!))
                // Skip the lookahead char
                index += 1
            case "|":
                tokens.append(.union)
            default: break
            }
            
            index += 1
        }
        
        return tokens
    }
}
