import RxTest

extension Assertion {
    /// A matcher that succeeds when testable observer terminated with an error event
    public func error() {
        verify(pass: events.last?.value.error != nil,
               message: .concise("error"))
    }

    /// A matcher that succeeds when testable observer terminated with an error event at a specific test time.
    ///
    /// - Parameter time: Expected error test time.
    public func error(at time: TestTime) {
        guard let errorEvent = events.last, errorEvent.value.error != nil else {
            verify(pass: false, message: .concise("error @ <\(time)>"))
            return
        }
        let errors = events.filter { $0.value.error != nil }
        let hasMatchingError = (errors.last?.time == time)
        verify(pass: errors.last?.time == time,
               message: .exact("error @ <\(time)>\(hasMatchingError ? "" : ", did error @ <\(errors.last!.time)> instead")" ))
    }

    /// A matcher that succeeds when testable observer terminated with an error after a specific number of next events.
    ///
    /// - Parameter count: Number of next events before complete.
    public func error(after count: Int) {
        guard let errorEvent = events.last, errorEvent.value.error != nil else {
            verify(pass: false, message: .concise("error after <\(count)> events"))
            return
        }
        let actualCount = events.count - 1
        let msg = (actualCount == count) ? "" : ", did error after <\(actualCount)> instead"
        verify(pass: actualCount == count,
               message: .exact("error after <\(count)> events\(msg)"))
    }

    /// A matcher that succeeds when testable observer terminated with a specific error type.
    ///
    /// - Parameter expectedType: Expected error type
    public func error<E: Swift.Error>(with expectedType: E.Type) {
        guard let errorEvent = events.last, let error = errorEvent.value.error else {
            verify(pass: false, message: "error")
            return
        }
        verify(pass: type(of: error) == expectedType,
               message: "error with <\(expectedType)>, errored with <\(type(of: error))> instead.")
    }
    /// A matcher that succeeds when testable observer terminated with a specific error
    ///
    /// - Parameter expectedError: Expected error
    public func error<E: Error>(with expectedError: E) where E: Equatable {
        guard let errorEvent = events.last, let error = errorEvent.value.error else {
            verify(pass: false, message: "error")
            return
        }
        guard let actualError = error as? E, actualError == expectedError else {
            verify(pass: false, message: "error with <\(expectedError)>, got <\(error)>")
            return
        }
    }
}
