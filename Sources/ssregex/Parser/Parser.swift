//
//  Parser.swift
//  
//
//  Created by Collin Palmer on 10/13/23.
//

import Foundation

@available(macOS 13.0, *)
enum Parser {
    // TODO: Return this from parenthesize
    indirect enum Paren {
        case token(Lex.Token)
        case paren([Paren])
        
        
        private static func parenthesizeRec(_ tokens: [Lex.Token]) -> (parens: Paren, remainder: [Lex.Token]) {
            var container: [Paren] = []
            var tokens = tokens
            var remainder: [Lex.Token] = []
            
            tokenLoop:
            while (tokens.isEmpty == false) {
                let token = tokens[0]
                
                if case let .paren(type, _) = token {
                    switch type {
                    case .left:
                        let tree = parenthesizeRec(Array(tokens[tokens.index(0, offsetBy: 1)...]))
                        container.append(tree.parens)
                        tokens = tree.remainder
                    case .right:
                        // Terminating case typically (closing paren)
                        tokens = Array(tokens[tokens.index(0, offsetBy: 1)...])
                        remainder = tokens
                        break tokenLoop
                    }
                } else {
                    // base case
                    container.append(.token(token))
                    tokens = Array(tokens[tokens.index(0, offsetBy: 1)...])
                }
            }
            
            return (parens: .paren(container), remainder: remainder)
        }
        
        static func parenthesize(_ tokens: [Lex.Token]) -> Paren {
            // TODO: Take definition below, modify as necessary.
            //return .token(.string(value: ""))
            return parenthesizeRec(tokens).parens
        }
    }
    
    struct ParseError: Error {}
}
