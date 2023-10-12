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
        
        XCTAssert(["a", "b", "c", #"\d"#, "x", "y", "z"] == values, "Values: \(values)")
    }
    
    func testRegexPhoneNumber() throws {
        let reExpr2 =
            Expression
                .parse(try Lex.lex(#"\d\d\d-\d\d\d-\d\d\d\d"#))
                .rewrite(.removeExtraneousConcat)
        
        let partial = reExpr2.partial
        XCTAssert(partial.description == #"(\d(\d(\d(-(\d(\d(\d(-(\d(\d(\d\d|\d)|\d)|\d)|-)|\d)|\d)|\d)|-)|\d)|\d)|\d)"#, "regular: \(reExpr2) partial: \(partial)")
    }
    
    func testUnionPartial() throws {
        let re =
            Expression.parse(try Lex.lex(#"(abc)*|(xyz)"#))
            .rewrite(.removeExtraneousConcat)
        
        let partial = re.partial
        
        XCTAssert(partial.description == #"((abc)*((abc|(ab|a)))?|(xyz|(xy|x)))"#, "reg: \(re) partial: \(partial)")
    }
    
    func testConcatQuantifierPartial() throws {
        let re =
            Expression.parse(try Lex.lex(#"((abc)(xyz))*"#))
            .rewrite(.removeExtraneousConcat)
        
        let partial = re.partial
        print(partial)
        
        XCTAssert(partial.description == #"(abcxyz)*(abc(xyz|(xy|x))|(abc|(ab|a)))"#, "reg: \(re) partial: \(partial)")
    }
}
