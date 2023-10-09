import XCTest
@testable import ssregex

final class ssregexTests: XCTestCase {
    func testStringQuantifierParse() throws {
        let lex = try Lex.lex(#"(abc)*"#)
        let ast = Expression.parse(lex)
        
        XCTAssert(ast.description == #"(abc)*"#, ast.description)
    }
    
    func testUnionParse() throws {
        let lex = try Lex.lex(#"abc|xyz"#)
        let ast = Expression.parse(lex)
        
        XCTAssert(ast.description == #"(abc|xyz)"#, ast.description)
    }
    
    func testUnionQuantifierParse() throws {
        let lex = try Lex.lex(#"(abc|xyz)*"#)
        let ast = Expression.parse(lex)
        
        XCTAssert(ast.description == #"((abc|xyz))*"#, ast.description)
    }
    
    func testStackedQuantifierParse() throws {
        let lex = try Lex.lex(#"((abc)*)*"#)
        let ast = Expression.parse(lex)
        
        XCTAssert(ast.description == #"((abc)*)*"#, ast.description)
    }
    
    func testTreeRewriteExtraneousConcat() throws {
        let lex = try Lex.lex(#"((abc)*)*"#)
        let ast = Expression.parse(lex)
        
        print("AST original: \(ast)")
        
        let astRewrite = Expression.rewrite(ast) { expr in
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
        
        // TODO: Validate nodes are exactly the same
        //print("AST rewrite: \(astRewrite)")
        XCTAssert(ast.description == #"((abc)*)*"#, ast.description)
    }
    
    func testTreeRewriteCollapseQuantifier() throws {
        /*
        let astRewrite = Expression.rewrite(ast) { expr in
            // Ugly but a start
            // If this is a quantifier and the child is a quantifier (of the same type) keep the child only.
            switch expr {
            case .quantifier(let quantifier, let subexpr):
                print("expr: \(expr), subexpr: \(subexpr)")
                switch subexpr {
                case .quantifier(let subquantifier, let subsubexpr):
                    print("Quantifier subexpr")
                    if quantifier == subquantifier {
                        return subsubexpr
                    }
                default:
                    print("subexpr type: \(subexpr)")
                    break
                }
            default:
                break
            }
            
            return expr
        }
        */
    }
}
