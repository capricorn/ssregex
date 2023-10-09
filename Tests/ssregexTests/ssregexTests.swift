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
}
