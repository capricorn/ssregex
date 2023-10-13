//
//  Rewriter.swift
//
//
//  Created by Collin Palmer on 10/13/23.
//

import Foundation

@available(macOS 13.0, *)
extension Expression {
    enum Rewrite {
        case removeExtraneousConcat
        case collapseQuantifiers
        case reducePlusQuantifier
        
        static func reducePlusQuantifier(_ expr: Expression) -> Expression {
            if case .quantifier(let quantifier, let subexpr) = expr, quantifier == .oneOrMore {
                return .concat([subexpr, .quantifier(operator: .zeroOrMore, subexpr)])
            }
            
            return expr
        }
        
        static func removeExtraneousConcat(_ expr: Expression) -> Expression {
            switch expr {
            case .concat(let array):
                if array.count == 1 {
                    return array[0]
                }
            default:
                break
            }
            
            return expr
        }
        
        static func collapseQuantifiers(_ expr: Expression) -> Expression {
            switch expr {
            case .quantifier(let quantifier, let subexpr):
                switch subexpr {
                case .quantifier(let subquantifier, _):
                    if quantifier == subquantifier {
                        return subexpr
                    }
                default:
                    break
                }
            default:
                break
            }
            
            return expr
        }
    }
    
    func rewrite(_ rewriter: (Expression) -> Expression) -> Expression {
        return Expression.rewrite(self, rewriter: rewriter)
    }
    
    func rewrite(_ rewriter: Rewrite) -> Expression {
        let transform: (Expression) -> Expression = switch rewriter {
        case .removeExtraneousConcat:
            Expression.Rewrite.removeExtraneousConcat
        case .collapseQuantifiers:
            Expression.Rewrite.collapseQuantifiers
        case .reducePlusQuantifier:
            Expression.Rewrite.reducePlusQuantifier
        }
        
        return rewrite(transform)
    }
    
    static func rewrite(_ expr: Expression, rewriter: (Expression) -> Expression) -> Expression {
        // Idea is: rewrite will return the transformed version of the node
        // Problem is: if rewriter is a no-op, then what
        let transformedExpr = rewriter(expr)
        
        // Take the rewritten version, go from there
        switch transformedExpr {
        case .quantifier(let quantifier, let expression):
            return .quantifier(operator: quantifier, rewrite(expression, rewriter: rewriter))
        case .union(let left, let right):
            return .union(left: rewrite(left, rewriter: rewriter), right: rewrite(right, rewriter: rewriter))
        case .concat(let array):
            return .concat(array.map({rewrite($0, rewriter: rewriter)}))
        default:
            break
        }
        
        return transformedExpr
    }
}
