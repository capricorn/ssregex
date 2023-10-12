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
@available(macOS 13.0, *)
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
        case reducePlusQuantifier
        
        static func reducePlusQuantifier(_ expr: Expression) -> Expression {
            if case .quantifier(let quantifier, let subexpr) = expr, quantifier == .oneOrMore {
                return .concat([subexpr, .quantifier(operator: .zeroOrMore, subexpr)])
            }
            
            return expr
        }
        
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
        case .reducePlusQuantifier:
            Expression.Rewrite.reducePlusQuantifier
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

@available(macOS 13.0, *)
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

@available(macOS 13.0, *)
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
    
    struct ParseError: Error {}
}
