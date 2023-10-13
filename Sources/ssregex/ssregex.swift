extension Array where Element == String {
    var cumsum: [Element] {
        var sum: [String] = []
        
        for str in self {
            sum.append((sum.last ?? "") + str)
        }
        
        return sum
    }
}
