//
//  Parser.swift
//  
//
//  Created by Collin Palmer on 10/13/23.
//

import Foundation

@available(macOS 13.0, *)
public enum Parser {
    private static func parseTree(_ tree: Lex.Paren) -> Expression {
        var expressions: [Expression] = []
        
        // TODO: Implement conversion of Lex.Token -> Expression (computed var)
        // Then, write test.
        switch tree {
        case .token(let token):
            // The only tokens reachable here are primitives (leaves)
            switch token {
            case .string(let value):
                return .string(Expression.StringSequence(tokens: [.string(value: value) ]))
            case .specialChar(let special):
                return .string(Expression.StringSequence(tokens: [.specialChar(special) ]))
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
    
    public static func parse(_ regex: String) throws -> Expression {
        let lex = try Lex.lex(regex)
        let parenTree = Lex.Paren.parenthesize(lex)
        
        return parseTree(parenTree)
    }
    
    public static func parse(_ tokens: [Lex.Token]) -> Expression {
        let tree = Lex.Paren.parenthesize(tokens) //Parser.parenthesize(tokens).parens
        return parseTree(tree)
    }
    
    struct ParseError: Error {}
}
