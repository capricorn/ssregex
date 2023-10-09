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
}
