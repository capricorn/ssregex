//
//  RewriteTests.swift
//  
//
//  Created by Collin Palmer on 10/13/23.
//

import XCTest
@testable import ssregex

final class RewriteTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testTreeRewriteExtraneousConcat() throws {
        let lex = try Lex.lex(#"((abc)*)*"#)
        let ast = Parser.parse(lex)
        
        let astRewrite = ast.rewrite(.removeExtraneousConcat)
        
        // TODO: Validate nodes are exactly the same
        XCTAssert(astRewrite.description == #"((abc)*)*"#, ast.description)
    }
    
    func testTreeRewriteCollapseQuantifier() throws {
        let lex = try Lex.lex(#"((abc)*)*"#)
        let ast = Parser.parse(lex)
        let astRewrite = ast
            .rewrite(.removeExtraneousConcat)
            .rewrite(.collapseQuantifiers)
        
        XCTAssert(astRewrite.description == #"(abc)*"#, astRewrite.description)
    }
    
    func testRewritePlusQuantifier() throws {
        let re =
            Parser
                .parse(try Lex.lex(#"(abc)+"#))
                .rewrite(.reducePlusQuantifier)
        
        XCTAssert(re.description == #"abc(abc)*"#, "reg: \(re)")
    }
}
