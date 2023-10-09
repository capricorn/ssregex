import XCTest
@testable import ssregex

final class ssregexTests: XCTestCase {
    func testExample() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
    }
    
    func testParse() throws {
        let lex = try Lex.lex(#"(abc)*"#)
        print("lex: \(lex)")
        let ast = Expression.parse(lex)
        
        print(ast)
    }
}
