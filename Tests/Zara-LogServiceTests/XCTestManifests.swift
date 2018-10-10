import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(Zara_LogServiceTests.allTests),
    ]
}
#endif