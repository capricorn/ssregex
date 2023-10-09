/*
 What are the tokens of interest in parsing?
 
 - A lex stage would be appropriate to simplify the parser
 
 Lexical tokens:
 - parens
 - string
 - quantifier {*,?,+, {k}}
 - brackets (char ranges)
 - union (|)
 - escape token (e.g. \d)
 
 Once mapped to lexical tokens, what's the parsing approach?
 Implicitly there is a top-level expression
 Consume the first expression (recursive) then the next, etc
 When consuming an expression, it only knows if the body within the parens.
 */

infix operator |>

extension String {
    static func |>(lhs: String, rhs: String) -> String {
        return lhs + rhs
    }
}

extension Array where Element == String {
    var cumsum: [Element] {
        var sum: [String] = []
        
        for str in self {
            sum.append((sum.last ?? "") + str)
        }
        
        return sum
    }
}

// TODO: **Implement pretty print**
indirect enum Expression: CustomStringConvertible {
    case string(String)
    case quantifier(operator: Lex.Token.Quantifier, Expression)
    case union(left: Expression, right: Expression)
    case concat([Expression])
    
    private static func parseTree(_ tree: Parser.Paren) -> Expression {
        var expressions: [Expression] = []
        
        // TODO: Implement conversion of Lex.Token -> Expression (computed var)
        // Then, write test.
        switch tree {
        case .token(let token):
            // The only tokens reachable here are primitives (leaves)
            switch token {
            case .string(let value):
                return .string(value)
            case .specialChar(let special):
                // TODO: Worth returning special? Can reasonably detect with leading '\'.
                return .string(special.rawValue)
            default:
                assertionFailure("Cannot handle non-primitive token case: \(tree)")
                break
            }
            // TODO: Appropriate token conversion
            //expressions.append([.concat(token)])
            break
        case .paren(let array):
            // TODO: Iterate entire array (i.e. concat case)
            var array = array
            
            while array.isEmpty == false {
                if array.count >= 3, case .token(.union) = array[1] {
                    // Expr | Expr
                    expressions.append(.union(left: parseTree(array[0]), right: parseTree(array[2])))
                    array = Array(array[3...])
                } else if array.count >= 2, case .token(let token) = array[1], case .quantifier(let quantifier) = token {
                    // (Expr)Quantifier e.g. (abc)*
                    expressions.append(.quantifier(operator: quantifier, parseTree(array[0])))
                    array = Array(array[2...])
                } else {
                    expressions.append(parseTree(array[0]))
                    array = Array(array[1...])
                }
            }
            
            /*
            for node in array {
                switch node {
                case .token(let token):
                    // TODO: Appropriate token conversion
                    break
                case .paren(_):
                    expressions.append(parseTree(node))
                }
            }
            */
        }

        return .concat(expressions)
    }
    
    static func parse(_ tokens: [Lex.Token]) -> Expression {
        let tree = Parser.Paren.parenthesize(tokens) //Parser.parenthesize(tokens).parens
        print("Lex tree: \(tree)")
        return parseTree(tree)
    }
    
    var description: String {
        switch self {
        case .string(let string):
            return string
        case .quantifier(let quantifier, let expression):
            return "(\(expression))\(quantifier.rawValue)"
        case .union(let left, let right):
            return "(\(left)|\(right))"
        case .concat(let array):
            return array.map({$0.description}).joined(separator: "")
        }
    }
}


enum Lex {
    struct TokenError: Error {}
    
    enum State {
        case string(startIndex: Int)
        case none
    }
    
    enum Token {
        enum Quantifier: String {
            case zeroOrMore = "*"
            case zeroOrOne = "?"  // ?
            case oneOrMore = "+" // +
            // TODO: Needs to store k count
            case exact = "{}"
        }
        
        enum Paren {
            case left
            case right
        }
        
        enum Special: String {
            case digit = #"\d"#
            case space = #"\s"#
        }
        
        case paren(type: Paren, index: Int)
        case string(value: String)
        case quantifier(Quantifier)
        case union
        /*
        case bracket(index: Int)
        // '-' token
        case range
        */
        case specialChar(Special)
        
        var isString: Bool {
            if case .string(_) = self {
                return true
            }
            
            return false
        }
        
        var isSpecial: Bool {
            if case .specialChar(_) = self {
                return true
            }
            return false
        }
    }
    
    static func lex(_ input: String) throws -> [Token] {
        // Implement a simple state machine for lexing (necessary for string capture)
        // For initial implementation, _do not_ support escapes
        var tokens: [Token] = []
        var state: State = .none
        
        let alphanumeric = { (char: String) in
            let regex = try? Regex(#"[a-zA-Z\d]"#)
            return (try? regex?.wholeMatch(in: char)?.isEmpty == false) ?? false
        }
        
        // TODO: Need to be able to manipulate the index for things such as `\d`, etc.
        //for (index, char) in input.enumerated() {
        var index = 0
        while (index < input.count) {
            let char = input[input.index(input.startIndex, offsetBy: index)..<input.index(input.startIndex, offsetBy: index+1)]
            
            if case let .string(startIndex) = state, alphanumeric(String(char)) == false {
                let str = input[input.index(input.startIndex, offsetBy: startIndex)..<input.index(input.startIndex, offsetBy: index)]
                tokens.append(.string(value: String(str)))
                state = .none
            }
                
            switch char {
            case "(":
                tokens.append(.paren(type: .left, index: index))
            case ")":
                tokens.append(.paren(type: .right, index: index))
            case "+":
                tokens.append(.quantifier(.oneOrMore))
            case "*":
                tokens.append(.quantifier(.zeroOrMore))
            case "?":
                tokens.append(.quantifier(.zeroOrOne))
            case "a"..."z", "A"..."Z", "0"..."9":
                if case .string(_) = state {
                    break
                }
                state = .string(startIndex: index)
            case "\\":
                // TODO: Throw error given validation issues
                let special = String(input[input.index(input.startIndex, offsetBy: index)..<input.index(input.startIndex, offsetBy: index+2)])
                tokens.append(.specialChar(.init(rawValue: special)!))
                // Skip the lookahead char
                index += 1
            case "|":
                tokens.append(.union)
            default: break
            }
            
            index += 1
        }
        
        return tokens
    }
}


protocol RExpression {}
protocol PartialRegex {}

protocol Partial {
    //var partial: PartialRegex {get}
    var partial: String { get }
}

enum Parser {
    // TODO: Return this from parenthesize
    indirect enum Paren {
        case token(Lex.Token)
        case paren([Paren])
        
        
        private static func parenthesizeRec(_ tokens: [Lex.Token]) -> (parens: Paren, remainder: [Lex.Token]) {
            var container: [Paren] = []
            var tokens = tokens
            var remainder: [Lex.Token] = []
            
            tokenLoop:
            while (tokens.isEmpty == false) {
                let token = tokens[0]
                
                if case let .paren(type, _) = token {
                    switch type {
                    case .left:
                        let tree = parenthesizeRec(Array(tokens[tokens.index(0, offsetBy: 1)...]))
                        container.append(tree.parens)
                        tokens = tree.remainder
                    case .right:
                        // Terminating case typically (closing paren)
                        tokens = Array(tokens[tokens.index(0, offsetBy: 1)...])
                        remainder = tokens
                        break tokenLoop
                    }
                } else {
                    // base case
                    container.append(.token(token))
                    tokens = Array(tokens[tokens.index(0, offsetBy: 1)...])
                }
            }
            
            return (parens: .paren(container), remainder: remainder)
        }
        
        static func parenthesize(_ tokens: [Lex.Token]) -> Paren {
            // TODO: Take definition below, modify as necessary.
            //return .token(.string(value: ""))
            return parenthesizeRec(tokens).parens
        }
    }
    
    static func parenthesize(_ tokens: [Lex.Token]) -> (parens: [Any], remainder: [Lex.Token]) {
        var container: [Any] = []
        var tokens = tokens
        var remainder: [Lex.Token] = []
        
        tokenLoop:
        while (tokens.isEmpty == false) {
            let token = tokens[0]
            
            if case let .paren(type, _) = token {
                switch type {
                case .left:
                    let tree = parenthesize(Array(tokens[tokens.index(0, offsetBy: 1)...]))
                    container.append(tree.parens)
                    tokens = tree.remainder
                case .right:
                    // Terminating case typically (closing paren)
                    tokens = Array(tokens[tokens.index(0, offsetBy: 1)...])
                    remainder = tokens
                    break tokenLoop
                }
            } else {
                // base case
                container.append(token)
                tokens = Array(tokens[tokens.index(0, offsetBy: 1)...])
            }
        }
        
        // If the element is not an opening paren, iterate until a close is seen.
        // Eventually will see a non-opening paren; iterate until close or no more tokens
        // TODO: Combine with top statement?
        /*
        for token in tokens {
            if case let .paren(type, _) = token {
                switch type {
                case .right:
                    return container
                default:
                    // TODO?
                    break
                }
            } else {
                container.append(token)
            }
        }
         */
        
        return (parens: container, remainder: remainder)
    }
    
    
    // What should the leaves be?
    // Also curious: best way to represent string sequence? (given escapes, etc)
    // (Maybe just an array of tokens for now)
    // Any string type can be stored as an array of chars and various methods can convert it accordingly
    // (Such as the partial transform)
    struct ParseError: Error {}
    
    struct RSpecial: CustomStringConvertible {
        let token: Lex.Token
        
        var description: String {
            if case .specialChar(let special) = token {
                return special.rawValue
            }
            
            return ""
        }
    }
    
    // TODO: Implement partial conversion (Separate type -- PartialRegex or something like tha)
    struct RString: RExpression, Partial, CustomStringConvertible {
        let tokens: [Lex.Token]
        
        // For now, treat each RString as _only_ containing
        var partial: String {
            let str: [String] = tokens.map {
                switch $0 {
                case .string(value: let str):
                    return str.split(separator: "").map { String($0) }
                case .specialChar(let special):
                    return [special.rawValue]
                default:
                    return []
                }
            }
            .flatMap { str in str }
            
            // Two transforms need to happen here:
            // First, a cumsum of the tokens
            // Then, joining the tokens with '|'
            // Finally, encase in parens
            
            let partial = str
                .cumsum
                .reversed() // Necessary to ensure the longest possible substring is matched.
                .joined(separator: "|")
            
            return "(\(partial))"
        }
        
        
        var description: String {
            tokens.map {
                switch $0 {
                case .string(value: let str):
                    return str
                case .specialChar(let special):
                    return special.rawValue
                default:
                    return ""
                }
            }
            .joined(separator: "")
        }
        
        
        static func parse(_ strToken: Lex.Token) throws -> StringSequence {
            if case let .string(value) = strToken {
                return StringSequence(value: value)
            } else {
                throw ParseError()
            }
        }
    }
    
    struct StringSequence: RExpression {
        let value: String
    }
    
    // Contains an expression
    struct Quantifier: RExpression {
        let type: Lex.Token.Quantifier
        let expression: RExpression
    }
    
    struct Union: RExpression {
        
    }
    
    // One option is to pass in the parenthesized list of lex tokens and then produce rules based on it
    
    /*
    static func parse2(_ tokens: [Lex.Token]) throws {
        // TODO: Implement Lex equatable protocol
        switch (tokens) {
        // In this case only concerned with the parent type itself..
        // _not_ the args, etc
        // **First: split this into a separate project.. better to use tests.**
        // Choose the right operations and the code writes itself
        case _ where tokens.starts(with: <#T##Sequence#>, by: <#T##(Lex.Token, Sequence.Element) throws -> Bool#>)
        default:
            break
        }
    }
     */
    
    // TODO: Return what?
    static func parse(_ tokens: [Lex.Token]) throws -> [Any] {
        let tree = parenthesize(tokens).parens
        var ast: [Any] = []
        
        for expr in tree {
            // Need to check specific case of (special quantifier)
            if let token = expr as? Lex.Token {
                if token.isString {
                    ast.append(try RString.parse(token))
                } else if token.isSpecial {
                    ast.append(RSpecial(token: token))
                }
            } else if let subexpr = expr as? Array<Any> {
                // TODO -- iterate array
            } else {
                throw ParseError()
            }
        }
        
        return ast
    }
}

/*
// Method to consume strings between parens
// What would this logically map to? ([Quantifier RExpression])
try? Lex.lex(#"(abc)+(\d|\s)"#)

// TODO: How should the below statement parse if a quantifier is applied to an element..?
// (Totally separate expression?)
//Parser.RString(tokens: (try? Lex.lex(#"abc\d"#)) ?? []).partial
// Basic lex is available; now, work on converting to equivalent AST structures.


// next: handle quantifier applied to a string
let lex = (try? Lex.lex(#"abc\d"#)) ?? []
// String lex to AST
let strings = lex
    .compactMap { if case let .string(value: val) = $0 { val } else { nil } }
    .map { Parser.StringSequence(value: $0) }

let lex2 = (try? Lex.lex(#"(abc)(\d)"#)) ?? []
// What it should be: [[abc], [\d]]
// TODO: pretty print
Parser.parenthesize(lex2).parens

try Parser.parse(lex)



let x = [1,2,3]

// Only works if x >= 2
let (a,b) = (x.first, x.second)
print(a, b)

print("test")
// What you actually want is starts with
switch x {
case _ where x.starts(with: [1,2]): // Of course requires equality
    print("head is 1,2")
    break
default: break
}

 */
extension Array {
    var second: Element? {
        guard self.count > 1 else {
            return nil
        }
        
        return self[1]
    }
}
