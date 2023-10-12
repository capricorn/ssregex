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
    struct StringSequence: Collection, CustomStringConvertible {
        subscript(position: Int) -> String {
            return characters[position]
        }
        
        let tokens: [Lex.Token]
        let characters: [String]
        
        init(tokens: [Lex.Token]) {
            self.tokens = tokens
            self.characters =
                tokens.map { (token: Lex.Token) -> [String] in
                    switch token {
                    case .string(let value):
                        return value.split(separator: "").map(String.init)
                    case .specialChar(let special):
                        return [special.rawValue]
                    default:
                        return [""]
                    }
                }
                .flatMap { $0 }
        }
        
        /*
        mutating lazy var characters: [String] = {
            // Expan tokens to a stream of characters
            tokens.map { (token: Lex.Token) -> [String] in
                switch token {
                case .string(let value):
                    return value.split(separator: "").map(String.init)
                case .specialChar(let special):
                    return [special.rawValue]
                default:
                    return [""]
                }
            }
            .flatMap { $0 }
        }()
         */
        
        struct StringIterator: IteratorProtocol {
            typealias Element = StringSequence.Element
            
            let tokens: [String]
            private var index = 0
            
            init(tokens: [String]) {
                // TODO: Explode these tokens
                self.tokens = tokens
            }
            
            mutating func next() -> Expression.StringSequence.Element? {
                guard index < tokens.count else {
                    return nil
                }
                
                
                let result = tokens[index]
                index += 1
                
                return result
            }
            
        }
        
        typealias Element = String
        typealias Iterator = StringIterator
        typealias Index = Int
        
        var startIndex: Index {
            return 0
        }
        
        // TODO: Needs to be a character count, not token count.
        var endIndex: Index {
            return characters.count
        }
        
        var description: String {
            self.joined(separator: "")
        }
        
        func index(after i: Index) -> Index {
            return i+1
        }
        
        func makeIterator() -> StringIterator {
            return StringIterator(tokens: characters)
        }
    }
    
    case string(StringSequence)
    case quantifier(operator: Lex.Token.Quantifier, Expression)
    case union(left: Expression, right: Expression)
    case concat([Expression])
    
    enum Rewrite {
        case removeExtraneousConcat
        case collapseQuantifiers
        
        static func removeExtraneousConcat(_ expr: Expression) -> Expression {
            switch expr {
            case .concat(let array):
                if array.count == 1 {
                    return array[0]
                }
            default: 
                break
            }
            
            return expr
        }
        
        static func collapseQuantifiers(_ expr: Expression) -> Expression {
            switch expr {
            case .quantifier(let quantifier, let subexpr):
                switch subexpr {
                case .quantifier(let subquantifier, _):
                    if quantifier == subquantifier {
                        return subexpr
                    }
                default:
                    break
                }
            default:
                break
            }
            
            return expr
        }
    }
    
    // TODO
    // Expression should be in a reduced form that's amenable to testing.
    var partial: Expression {
        switch self {
        case .string(let string):
            // e.g. "abc".partial -> ("abc"|"ab"|"a")
            let partial =
                string
                    //.split(separator: "")
                    .map({ $0 })
                    .cumsum
                    .reversed() // Necessary to ensure the longest possible substring is matched.
                    .joined(separator: "|")

            // Lex transformed string, pass as new expression.
            let partialLex = try! Lex.lex(partial)
            return Expression.parse(partialLex)
        case .quantifier(let quantifier, let subexpr):
            switch quantifier {
            case .zeroOrOne:
                return .quantifier(operator: .zeroOrOne, subexpr.partial)
            default: break
            }
            // TODO: Assumption is * quantifier; handle other cases
            return .concat([self, subexpr.partial])
        case .concat(let array):
            assert(array.count > 0)
            if array.count == 1 {
                return array[0].partial
            } else if array.count == 2 {
                return .union(left: .concat([array[0], array[1].partial]), right: array[0].partial)
            } else {
                // Case where array.count > 2
                return .union(left: .concat([array[0], .concat(Array(array[1...])).partial]), right: array[0].partial)
                
            }
        case .union(let left, let right):
            return .union(left: left.partial, right: right.partial)
        default: break
        }
        
        return self
    }
    
    // Can do polymorphism to have enum cases of defined transforms, use dot notation to advantage.
    func rewrite(_ rewriter: (Expression) -> Expression) -> Expression {
        return Expression.rewrite(self, rewriter: rewriter)
    }
    
    func rewrite(_ rewriter: Rewrite) -> Expression {
        let transform: (Expression) -> Expression = switch rewriter {
        case .removeExtraneousConcat:
            Expression.Rewrite.removeExtraneousConcat
        case .collapseQuantifiers:
            Expression.Rewrite.collapseQuantifiers
        }
        
        return rewrite(transform)
    }
    
    static func rewrite(_ expr: Expression, rewriter: (Expression) -> Expression) -> Expression {
        // Idea is: rewrite will return the transformed version of the node
        // Problem is: if rewriter is a no-op, then what
        let transformedExpr = rewriter(expr)
        
        // Take the rewritten version, go from there
        switch transformedExpr {
        case .quantifier(let quantifier, let expression):
            return .quantifier(operator: quantifier, rewrite(expression, rewriter: rewriter))
        case .union(let left, let right):
            return .union(left: rewrite(left, rewriter: rewriter), right: rewrite(right, rewriter: rewriter))
        case .concat(let array):
            return .concat(array.map({rewrite($0, rewriter: rewriter)}))
        default:
            break
        }
        
        return transformedExpr
    }
    
    private static func parseTree(_ tree: Parser.Paren) -> Expression {
        var expressions: [Expression] = []
        
        // TODO: Implement conversion of Lex.Token -> Expression (computed var)
        // Then, write test.
        switch tree {
        case .token(let token):
            // The only tokens reachable here are primitives (leaves)
            switch token {
            case .string(let value):
                return .string(StringSequence(tokens: [.string(value: value) ]))
            case .specialChar(let special):
                return .string(StringSequence(tokens: [.specialChar(special) ]))
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
                if array.count >= 3 {
                    if case .token(.union) = array[1] {
                        // Expr | Expr
                        expressions.append(.union(left: parseTree(array[0]), right: parseTree(.paren(Array(array[2...])))))
                        break
                    } else if case .token(.quantifier(let quantifier)) = array[1], case .token(.union) = array[2] {
                        // Expr Quantifier | Expr
                        expressions.append(.union(left: .quantifier(operator: quantifier, parseTree(array[0])), right: parseTree(.paren(Array(array[3...]))) ))
                        break
                    }
                }
                    //array = Array(array[3...])
                if case .token(.union) = array[0] {
                    expressions.append(.union(left: expressions.last!, right: parseTree(.paren(Array(array[1...])))))
                    break
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
            return string.description
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
        
        let ascii = { (char: String) in
            let regex = try? Regex(#"[a-zA-Z\d\-!*#$%&]"#)
            return (try? regex?.wholeMatch(in: char)?.isEmpty == false) ?? false
        }
        
        // TODO: Need to be able to manipulate the index for things such as `\d`, etc.
        //for (index, char) in input.enumerated() {
        var index = 0
        while (index < input.count) {
            let char = input[input.index(input.startIndex, offsetBy: index)..<input.index(input.startIndex, offsetBy: index+1)]
            
            if case let .string(startIndex) = state {
                if ascii(String(char)) == false {
                    let str = input[input.index(input.startIndex, offsetBy: startIndex)..<input.index(input.startIndex, offsetBy: index)]
                    tokens.append(.string(value: String(str)))
                    state = .none
                } else if index == input.count-1 {
                    let str = input[input.index(input.startIndex, offsetBy: startIndex)...]
                    tokens.append(.string(value: String(str)))
                    state = .none
                    break
                }
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
            case _ where ascii(String(char)):
                if case .string(_) = state {
                    break
                }
                if index == input.count-1 {
                    tokens.append(.string(value: String(char)))
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
