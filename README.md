# ssregex 

**ssregex** provides functionality for partially matching a regex. For any given regex,
a partial match mode will also match on any substring of a regular regex match. For instance,
the partial match of `abc` will match on any of the substrings `a`, `ab`, or `abc`.

## Use

```swift
let partial = try Parser.parse("abc").partial

let regex = try NSRegularExpression(partial)
```
