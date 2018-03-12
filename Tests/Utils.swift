import XCTest
@testable import RxTestExt

struct AssertionResult {

    private let message: String?
    private let location: Location
    init(assertedMessage: String?, location: Location) {
        self.message = assertedMessage
        self.location = location
    }

    private func fail(_ pass: Bool = false, message: String) {
        if !pass {
            XCTFail(message, file: location.file, line: location.line)
        }
    }

    func toFail(with message: String? = nil) {
        guard let expectedMessage = message else {
            fail(self.message != nil, message: "did not fail")
            return
        }

        guard let actualMessage = self.message else {
            fail(message: "did not fail, but expected \"\(expectedMessage)\"")
            return
        }

        fail(actualMessage == expectedMessage,
             message: "got failure message: \"\(actualMessage)\", but expected \"\(expectedMessage)\")")
    }

    func notToFail() {
        if message != nil {
            fail(message: "expected not to fail")
        }
    }
}

func expect(file: StaticString = #file, line: UInt = #line, closure: @escaping () -> Void) -> AssertionResult {
    var assertionMessage: String?
    Environment.instance.assertionHandler = {msg, _ in
        assertionMessage = msg
    }
    closure()
    return AssertionResult(assertedMessage: assertionMessage,
                           location: Location(file: file, line: line))
}

//MARK: Test Error
struct TestError: Error, Equatable {
    private let message: String
    init(_ message: String = "any-error") {
        self.message = message
    }

    static func == (lhs: TestError, rhs: TestError) -> Bool {
        return lhs.message == rhs.message
    }
}
