import XCTest
@testable import ssregex

final class ssregexTests: XCTestCase {
    func testStringQuantifierParse() throws {
        let lex = try Lex.lex(#"(abc)*"#)
        let ast = Expression.parse(lex)
        
        XCTAssert(ast.description == #"(abc)*"#, ast.description)
    }
    
    func testUnionParse() throws {
        let lex = try Lex.lex(#"abc|xyz|ijk"#)
        let ast = Expression
            .parse(lex)
        
        XCTAssert(ast.description == #"(abc|(xyz|ijk))"#, ast.description)
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
        
        let astRewrite = ast.rewrite(.removeExtraneousConcat)
        
        // TODO: Validate nodes are exactly the same
        XCTAssert(astRewrite.description == #"((abc)*)*"#, ast.description)
    }
    
    func testTreeRewriteCollapseQuantifier() throws {
        let lex = try Lex.lex(#"((abc)*)*"#)
        let ast = Expression.parse(lex)
        let astRewrite = ast
            .rewrite(.removeExtraneousConcat)
            .rewrite(.collapseQuantifiers)
        
        XCTAssert(astRewrite.description == #"(abc)*"#, astRewrite.description)
    }
    
    func testStringPartialExpression() throws {
        let reExpr = 
            Expression
                .parse(try Lex.lex("asdf"))
                .rewrite(.removeExtraneousConcat)
        
        let partial = reExpr.partial
        
        XCTAssert(partial.description == "(asdf|(asd|(as|a)))", "original: \(reExpr.description) partial: \(partial)")
    }
    
    func testStringQuantifierPartialExpression() throws {
        let reExpr =
            Expression
                .parse(try Lex.lex("(asdf)*"))
                .rewrite(.removeExtraneousConcat)
        
        let partial = reExpr.partial
        XCTAssert(partial.description == "(asdf)*((asdf|(asd|(as|a))))?", "original: \(reExpr.description) partial: \(partial)")
    }
    
    func testUnionQuantifierPartialExpression() throws {
        let reExpr =
            Expression
                .parse(try Lex.lex("(abc|xyz)*"))
                .rewrite(.removeExtraneousConcat)
    
        let partial = reExpr.partial
        XCTAssert(partial.description == "((abc|xyz))*(((abc|(ab|a))|(xyz|(xy|x))))?", "original: \(reExpr.description) partial: \(partial)")
    }
    
    func testRegexStringIterator() throws {
        let tokens: [Lex.Token] = [ .string(value: "abc"), .specialChar(.digit), .string(value: "xyz") ]
        let str = Expression.StringSequence(tokens: tokens)
        
        let values: [String] = str.map { $0 }
        
        XCTAssert(["abc", #"\d"#, "xyz"] == values, "Values: \(values)")
    }
}
