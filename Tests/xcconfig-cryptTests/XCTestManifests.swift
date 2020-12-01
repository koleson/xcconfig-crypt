import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(xcconfig_cryptTests.allTests),
    ]
}
#endif
