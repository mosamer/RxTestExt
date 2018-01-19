import RxTest

extension Assertion {
    /// A matcher that succeeds when testable observer received one (or more) next events
    public func next() {
        verify(pass: events.first?.value.element != nil,
               message: .concise("next"))
    }

    /// A matcher that succeeds when testable observer receives a next event at a specific time.
    ///
    /// - Parameter time: Expected `next` time.
    public func next(at time: TestTime) {

        verify(pass: !events.filter { $0.time == time && $0.value.element != nil }.isEmpty,
               message: .full("next @ <\(time)>", events.isEmpty ? "get any events" : "get an event"))
    }

    /// A matcher that succeeds when testable observer recieves a specific number of next events.
    ///
    /// - Parameter expectedCount: Expected number of next events.
    public func next(times expectedCount: Int) {
        let actualCount = events.filter { $0.value.element != nil }.count
        verify(pass: actualCount == expectedCount,
               message: .exact("next <\(expectedCount)> times, did get <\(actualCount)> events"))
    }
}
