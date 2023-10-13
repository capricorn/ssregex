//
//  Expression.swift
//  
//
//  Created by Collin Palmer on 10/13/23.
//

import Foundation

@available(macOS 13.0, *)
public indirect enum Expression: CustomStringConvertible {
    case string(StringSequence)
    case quantifier(operator: Lex.Token.Quantifier, Expression)
    case union(left: Expression, right: Expression)
    case concat([Expression])
    
    public var partial: Expression {
        switch self {
        case .string(let string):
            // e.g. "abc".partial -> ("abc"|"ab"|"a")
            let partial =
                string
                    //.split(separator: "")
                    .map({ $0 })
                    .cumsum
                    .reversed() // Necessary to ensure the longest possible substring is matched.
                    .joined(separator: "|")

            // Lex transformed string, pass as new expression.
            let partialLex = try! Lex.lex(partial)
            return Parser.parse(partialLex)
        case .quantifier(let quantifier, let subexpr):
            switch quantifier {
            case .zeroOrOne:
                return .quantifier(operator: .zeroOrOne, subexpr.partial)
            default: break
            }
            // TODO: Assumption is * quantifier; handle other cases
            return .concat([self, subexpr.partial])
        case .concat(let array):
            assert(array.count > 0)
            if array.count == 1 {
                return array[0].partial
            } else if array.count == 2 {
                return .union(left: .concat([array[0], array[1].partial]), right: array[0].partial)
            } else {
                // Case where array.count > 2
                return .union(left: .concat([array[0], .concat(Array(array[1...])).partial]), right: array[0].partial)
                
            }
        case .union(let left, let right):
            return .union(left: left.partial, right: right.partial)
        default: break
        }
        
        return self
    }
    
    public var description: String {
        switch self {
        case .string(let string):
            return string.description
        case .quantifier(let quantifier, let expression):
            return "(\(expression))\(quantifier.regex)"
        case .union(let left, let right):
            return "(\(left)|\(right))"
        case .concat(let array):
            return array.map({$0.description}).joined(separator: "")
        }
    }
}
