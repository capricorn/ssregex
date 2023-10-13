//
//  PartialTests.swift
//  
//
//  Created by Collin Palmer on 10/13/23.
//

import XCTest
@testable import ssregex

final class PartialTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testStringPartialExpression() throws {
        let reExpr = 
            Parser
                .parse(try Lex.lex("asdf"))
                .rewrite(.removeExtraneousConcat)
        
        let partial = reExpr.partial
        
        XCTAssert(partial.description == "(asdf|(asd|(as|a)))", "original: \(reExpr.description) partial: \(partial)")
    }
    
    func testStringQuantifierPartialExpression() throws {
        let reExpr =
            Parser
                .parse(try Lex.lex("(asdf)*"))
                .rewrite(.removeExtraneousConcat)
        
        let partial = reExpr.partial
        XCTAssert(partial.description == "(asdf)*(asdf|(asd|(as|a)))", "original: \(reExpr.description) partial: \(partial)")
    }
    
    func testUnionQuantifierPartialExpression() throws {
        let reExpr =
            Parser
                .parse(try Lex.lex("(abc|xyz)*"))
                .rewrite(.removeExtraneousConcat)
    
        let partial = reExpr.partial
        XCTAssert(partial.description == "((abc|xyz))*((abc|(ab|a))|(xyz|(xy|x)))", "original: \(reExpr.description) partial: \(partial)")
    }
 
    func testRegexPhoneNumber() throws {
        let reExpr2 =
            Parser
                .parse(try Lex.lex(#"\d\d\d-\d\d\d-\d\d\d\d"#))
                .rewrite(.removeExtraneousConcat)
        
        let partial = reExpr2.partial
        XCTAssert(partial.description == #"(\d(\d(\d(-(\d(\d(\d(-(\d(\d(\d\d|\d)|\d)|\d)|-)|\d)|\d)|\d)|-)|\d)|\d)|\d)"#, "regular: \(reExpr2) partial: \(partial)")
    }
    
    func testUnionPartial() throws {
        let re =
            Parser
                .parse(try Lex.lex(#"(abc)*|(xyz)"#))
                .rewrite(.removeExtraneousConcat)
        
        let partial = re.partial
        
        XCTAssert(partial.description == #"((abc)*(abc|(ab|a))|(xyz|(xy|x)))"#, "reg: \(re) partial: \(partial)")
    }
    
    func testConcatQuantifierPartial() throws {
        let re =
            Parser
                .parse(try Lex.lex(#"((abc)(xyz))*"#))
                .rewrite(.removeExtraneousConcat)
        
        let partial = re.partial
        print(partial)
        
        XCTAssert(partial.description == #"(abcxyz)*(abc(xyz|(xy|x))|(abc|(ab|a)))"#, "reg: \(re) partial: \(partial)")
    }
    
    func testStringZeroOneQuantifierPartial() throws {
        let re =
            Parser
                .parse(try Lex.lex(#"(abc)?"#))
                .rewrite(.removeExtraneousConcat)
        
        let partial = re.partial
        
        XCTAssert(partial.description == #"((abc|(ab|a)))?"#, "reg: \(re) partial: \(partial)")
    }
    
    func testExactQuantifierPartial() throws {
        let re =
            Parser
                .parse(try Lex.lex(#"(abc){2}"#))
                .rewrite(.removeExtraneousConcat)
        
        let partial = re.partial
        XCTAssert(partial.description == #"(abc(abc|(ab|a))|(abc|(ab|a)))"#, "reg: \(re) partial: \(partial)")
    }
}
