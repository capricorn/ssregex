//
//  ParseTests.swift
//  
//
//  Created by Collin Palmer on 10/13/23.
//

import XCTest
@testable import ssregex

final class ParseTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testStringQuantifierParse() throws {
        let lex = try Lex.lex(#"(abc)*"#)
        let ast = Parser.parse(lex)
        
        XCTAssert(ast.description == #"(abc)*"#, ast.description)
    }
    
    func testUnionParse() throws {
        let lex = try Lex.lex(#"abc|xyz|ijk"#)
        let ast = Parser
            .parse(lex)
        
        XCTAssert(ast.description == #"(abc|(xyz|ijk))"#, ast.description)
    }
    
    func testUnionQuantifierParse() throws {
        let lex = try Lex.lex(#"(abc|xyz)*"#)
        let ast = Parser.parse(lex)
        
        XCTAssert(ast.description == #"((abc|xyz))*"#, ast.description)
    }
    
    func testStackedQuantifierParse() throws {
        let lex = try Lex.lex(#"((abc)*)*"#)
        let ast = Parser.parse(lex)
        
        XCTAssert(ast.description == #"((abc)*)*"#, ast.description)
    }
}
