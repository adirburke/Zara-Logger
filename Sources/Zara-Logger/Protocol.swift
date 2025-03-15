//  Created by Adir Burke on 15/3/2025.
//

public protocol LogServiceProtocol  : Sendable {
     func logMessage(_ s: Any..., terminator: String, console : Bool)
}

public extension LogServiceProtocol {
    func logMessage(_ s: Any..., terminator: String = "\n", console : Bool = true) {
        logMessage(s, terminator: terminator, console: console)
    }
}
