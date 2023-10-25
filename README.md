# ssregex 

**ssregex** provides functionality for partially matching a regex. For any given regex,
a partial match mode will also match on any substring of a regular regex match. For instance,
the partial match of `abc` will match on any of the substrings `a`, `ab`, or `abc`.

See [this pdf](https://github.com/capricorn/ssregex-tex/blob/master/writeup.pdf) for an explanation of how the partial match rewriter works.

For partial rewrite examples, see [these tests](https://github.com/capricorn/ssregex/blob/master/Tests/ssregexTests/PartialTests.swift).

## Use

```swift
let partial = try Parser.parse("abc").partial   // /abc/ -> /(abc|ab|a)/

let regex = try NSRegularExpression(partial)
```

## Current support

The following structures can be transformed to a partial match (where `E` is an expression):

- Ascii characters
- `EE`
- `E|E`
- `E*`
- `E?`
- `E{k}`
