//
//  LexTests.swift
//  
//
//  Created by Collin Palmer on 10/13/23.
//

import XCTest
@testable import ssregex

final class LexTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testLexCurlyBrace() throws {
        let str = "{100}"
        let lex = try Lex.lex(str)
        
        XCTAssert(lex == [.quantifier(.exact(k: 100))], "\(lex)")
    }
}
