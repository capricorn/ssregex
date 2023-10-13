import XCTest
@testable import ssregex

final class ssregexTests: XCTestCase {
    func testRegexStringIterator() throws {
        let tokens: [Lex.Token] = [ .string(value: "abc"), .specialChar(.digit), .string(value: "xyz") ]
        let str = Expression.StringSequence(tokens: tokens)
        
        let values: [String] = str.map { $0 }
        
        XCTAssert(["a", "b", "c", #"\d"#, "x", "y", "z"] == values, "Values: \(values)")
    }
}
