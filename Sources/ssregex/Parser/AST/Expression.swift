//
//  Expression.swift
//  
//
//  Created by Collin Palmer on 10/13/23.
//

import Foundation

@available(macOS 13.0, *)
indirect enum Expression: CustomStringConvertible {
    case string(StringSequence)
    case quantifier(operator: Lex.Token.Quantifier, Expression)
    case union(left: Expression, right: Expression)
    case concat([Expression])
    
    // TODO
    // Expression should be in a reduced form that's amenable to testing.
    var partial: Expression {
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
            return Expression.parse(partialLex)
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
    

    
    private static func parseTree(_ tree: Lex.Paren) -> Expression {
        var expressions: [Expression] = []
        
        // TODO: Implement conversion of Lex.Token -> Expression (computed var)
        // Then, write test.
        switch tree {
        case .token(let token):
            // The only tokens reachable here are primitives (leaves)
            switch token {
            case .string(let value):
                return .string(StringSequence(tokens: [.string(value: value) ]))
            case .specialChar(let special):
                return .string(StringSequence(tokens: [.specialChar(special) ]))
            default:
                assertionFailure("Cannot handle non-primitive token case: \(tree)")
                break
            }
            // TODO: Appropriate token conversion
            //expressions.append([.concat(token)])
            break
        case .paren(let array):
            // TODO: Iterate entire array (i.e. concat case)
            var array = array
            
            while array.isEmpty == false {
                if array.count >= 3 {
                    if case .token(.union) = array[1] {
                        // Expr | Expr
                        expressions.append(.union(left: parseTree(array[0]), right: parseTree(.paren(Array(array[2...])))))
                        break
                    } else if case .token(.quantifier(let quantifier)) = array[1], case .token(.union) = array[2] {
                        // Expr Quantifier | Expr
                        expressions.append(.union(left: .quantifier(operator: quantifier, parseTree(array[0])), right: parseTree(.paren(Array(array[3...]))) ))
                        break
                    }
                }
                    //array = Array(array[3...])
                if case .token(.union) = array[0] {
                    expressions.append(.union(left: expressions.last!, right: parseTree(.paren(Array(array[1...])))))
                    break
                } else if array.count >= 2, case .token(let token) = array[1], case .quantifier(let quantifier) = token {
                    // (Expr)Quantifier e.g. (abc)*
                    expressions.append(.quantifier(operator: quantifier, parseTree(array[0])))
                    array = Array(array[2...])
                } else {
                    expressions.append(parseTree(array[0]))
                    array = Array(array[1...])
                }
            }
        }

        return .concat(expressions)
    }
    
    static func parse(_ tokens: [Lex.Token]) -> Expression {
        let tree = Lex.Paren.parenthesize(tokens) //Parser.parenthesize(tokens).parens
        print("Lex tree: \(tree)")
        return parseTree(tree)
    }
    
    var description: String {
        switch self {
        case .string(let string):
            return string.description
        case .quantifier(let quantifier, let expression):
            return "(\(expression))\(quantifier.rawValue)"
        case .union(let left, let right):
            return "(\(left)|\(right))"
        case .concat(let array):
            return array.map({$0.description}).joined(separator: "")
        }
    }
}
