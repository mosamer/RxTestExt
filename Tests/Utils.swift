import XCTest
@testable import RxTestExt

/// Assert if test case failed with a given failure message
///
/// - Parameters:
///   - message: Failure message to check.
///   - closure: Closure to test.
func failWithErrorMessage(_ message: String, file: StaticString = #file, line: UInt = #line, closure: @escaping () -> Void) {
    var assertionMessage: String?
    Environment.instance.assertionHandler = {msg, _ in
        assertionMessage = msg
    }
    closure()

    guard let asserted = assertionMessage else {
        XCTFail("did not fail", file: file, line: line)
        return
    }

    if asserted != message {
        XCTFail("Got failure message: \"\(asserted)\", but expected \"\(message)\"",
            file: file, line: line)
    }
}
