//
//  File.swift
//  
//
//  Created by Collin Palmer on 10/13/23.
//

import Foundation

@available(macOS 13.0, *)
extension Expression {
    public struct StringSequence: Collection, CustomStringConvertible {
        public subscript(position: Int) -> String {
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
        
        public struct StringIterator: IteratorProtocol {
            public typealias Element = StringSequence.Element
            
            let tokens: [String]
            private var index = 0
            
            init(tokens: [String]) {
                // TODO: Explode these tokens
                self.tokens = tokens
            }
            
            public mutating func next() -> Expression.StringSequence.Element? {
                guard index < tokens.count else {
                    return nil
                }
                
                
                let result = tokens[index]
                index += 1
                
                return result
            }
            
        }
        
        public typealias Element = String
        public typealias Iterator = StringIterator
        public typealias Index = Int
        
        public var startIndex: Index {
            return 0
        }
        
        // TODO: Needs to be a character count, not token count.
        public var endIndex: Index {
            return characters.count
        }
        
        public var description: String {
            self.joined(separator: "")
        }
        
        public func index(after i: Index) -> Index {
            return i+1
        }
        
        public func makeIterator() -> StringIterator {
            return StringIterator(tokens: characters)
        }
    }
}
