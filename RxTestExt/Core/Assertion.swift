import XCTest
import RxSwift
import RxTest

public struct Assertion<T> {
    struct Location {
        let file: StaticString
        let line: UInt
    }

    let base: TestableObserver<T>
    let location: Location
    let negated: Bool
    init(_ base: TestableObserver<T>, file: StaticString, line: UInt, negated: Bool = false) {
        self.base = base
        self.location = Location(file: file, line: line)
        self.negated = negated
    }

    func verify(pass: Bool, message: String) {
        if pass == negated {
            XCTFail("expected \(negated ? "not" : "") to \(message)", file: location.file, line: location.line)
        }
    }

    var events: [Recorded<Event<T>>] {
        return base.events
    }

    /// A negated version of current assertion
    public var not: Assertion<T> {
        return Assertion(base, file: location.file, line: location.line, negated: true)
    }
}

public func assert<T>(_ source: TestableObserver<T>, file: StaticString = #file, line: UInt = #line) -> Assertion<T> {
    return Assertion(source, file: file, line: line)
}

// MARK: Next Matchers
extension Assertion {
    /// A matcher that succeeds when testable observer received one (or more) next events
    public func next() {
        verify(pass: events.first?.value.element != nil,
               message: "next")
    }

    /// A matcher that succeeds when testable observer receives a next event at a specific time.
    ///
    /// - Parameter time: Expected `next` time.
    public func next(at time: TestTime) {
        verify(pass: !events.filter { $0.time == time && $0.value.element != nil }.isEmpty,
               message: "next at <\(time)>")
    }

    /// A matcher that succeeds when testable observer recieves a specific number of next events.
    ///
    /// - Parameter expectedCount: Expected number of next events.
    public func next(times expectedCount: Int) {
        let actualCount = events.filter { $0.value.element != nil }.count
        verify(pass: actualCount == expectedCount,
               message: "next <\(expectedCount)> times, got <\(actualCount)> event(s)")
    }
}

extension Assertion {
    /// A matcher that succeeds when testable obserevr never recieves an event.
    ///
    /// This is to macth a similar behavior of `Observabel.never()`
    public func never() {
        verify(pass: events.isEmpty,
               message: "never emits, got <\(events.count)> event(s)")
    }

    /// A matcher that succeeds when testable obserevr only recieves a `completed` event.
    ///
    /// This is to macth a similar behavior of `Observabel.empty()`
    public func empty() {
        verify(pass: events.first?.value.isCompleted ?? false,
               message: "complete with no other events")
    }
}
// MARK: Next Value Matchers
extension Assertion {
    /// A matcher that succeeds when value emitted at a specific index matches a given value.
    ///
    /// - Parameters:
    ///   - index: Event index.
    ///   - matcher: A closure to evaluate if actual value matches.
    public func next(at index: Int, match matcher: (T?) -> (Bool, String)) {
        let nextEvents = events.filter { $0.value.element != nil }
        guard nextEvents.count > index, index >= 0 else {
            verify(pass: false,
                   message: "get enough next events")
            return
        }
        let actualValue = nextEvents[index].value.element
        let (pass, msg) = matcher(actualValue)
        verify(pass: pass,
               message: msg)
    }

    /// A matcher that succeeds when last emitted next matches a given value.
    ///
    ///   - matcher: A closure to evaluate if actual value matches.
    public func lastNext(match matcher: (T?) -> (Bool, String)) {
        let nextEvents = events.filter { $0.value.element != nil }
        next(at: nextEvents.count - 1, match: matcher)
    }

    /// A matcher that succeeds when first emitted next matches a given value.
    ///
    ///   - matcher: A closure to evaluate if actual value matches.
    public func firstNext(match matcher: (T?) -> (Bool, String)) {
        next(at: 0, match: matcher)
    }
}
// MARK: Next Equality Matchers
extension Assertion where T: Equatable {
    /// A matcher that succeeds when value emitted at a specific index equal a given value.
    ///
    /// - Parameters:
    ///   - index: Event index.
    ///   - expectedValue: Expected value.
    public func next(at index: Int, equal expectedValue: T) {
        let nextEvents = events.filter { $0.value.element != nil }
        guard nextEvents.count > index, index >= 0 else {
            verify(pass: false,
                   message: "get enough next events")
            return
        }
        let actualValue = nextEvents[index].value.element
        verify(pass: actualValue == expectedValue,
               message: "equal <\(expectedValue)>, got <\(actualValue.stringify)>")
    }

    /// A matcher that succeeds when last emitted next is equal to given value.
    ///
    /// - Parameter expectedValue: Expected value.
    public func lastNext(equal expectedValue: T) {
        let nextEvents = events.filter { $0.value.element != nil }
        next(at: nextEvents.count - 1, equal: expectedValue)
    }

    /// A matcher that succeeds when first emitted next is equal to given value.
    ///
    /// - Parameter expectedValue: Expected value.
    public func firstNext(equal expectedValue: T) {
        next(at: 0, equal: expectedValue)
    }

    /// A matcher that succeeds when testable obserevr only recieves a `next` event and immediately completes.
    ///
    /// This is to macth a similar behavior of `Observabel.just()`
    public func just(_ value: T) {
        let msg = "get <\(value)> then completes"
        guard events.count == 2 else {
            verify(pass: false, message: msg + ", emitted <\(events.count)> event(s)")
            return
        }
        let next = events[0]
        let complete = events[1]
        guard complete.value.isCompleted else {
            verify(pass: false, message: msg + ", didnot complete")
            return
        }
        guard next.time == complete.time else {
            verify(pass: false, message: msg + ", didnot complete immediately")
            return
        }
        verify(pass: next.value.element == value,
               message: msg + ", got <\(next.value.element.stringify)>")
    }
}

public func == <T: Equatable>(lhs: Assertion<T>, rhs: T) {
    lhs.firstNext(equal: rhs)
}

// MARK: Error Matchers
extension Assertion {
    /// A matcher that succeeds when testable observer terminated with an error event
    public func error() {
        verify(pass: events.last?.value.error != nil,
               message: "error")
    }

    /// A matcher that succeeds when testable observer terminated with an error event at a specific test time.
    ///
    /// - Parameter time: Expected error test time.
    public func error(at time: TestTime) {
        guard let errorEvent = events.last, errorEvent.value.error != nil else {
            verify(pass: false, message: "error")
            return
        }
        verify(pass: errorEvent.time == time,
               message: "error at <\(time)>, errored at <\(errorEvent.time)> instead.")
    }

    /// A matcher that succeeds when testable observer terminated with an error after a specific number of next events.
    ///
    /// - Parameter count: Number of next events before complete.
    public func error(after count: Int) {
        guard let errorEvent = events.last, errorEvent.value.error != nil else {
            verify(pass: false, message: "error")
            return
        }
        let actualCount = events.count - 1
        verify(pass: actualCount == count,
               message: "error after <\(count)>, errored after <\(actualCount)> instead")
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

// MARK: Completion Matchers
extension Assertion {
    /// A matcher that succeeds when testable observer terminated with a complete event
    public func complete() {
        verify(pass: events.last?.value.isCompleted ?? false,
               message: "complete")
    }

    /// A matcher that succeeds if testable observer terminated with a complete event at a specific test time.
    ///
    /// - Parameter time: Test time to match completion event
    public func complete(at time: TestTime) {
        guard let completeEvent = events.last, completeEvent.value.isCompleted else {
            verify(pass: false,
                   message: "complete")
            return
        }
        verify(pass: completeEvent.time == time,
               message: "complete at <\(time)>, completed at <\(completeEvent.time)> instead")
    }

    /// A matcher that succeeds if testable observer terminated with a complete event after a specific number of next events.
    ///
    /// - Parameter count: Number of next events before complete.
    public func complete(after count: Int) {
        guard let completeEvent = events.last, completeEvent.value.isCompleted else {
            verify(pass: false,
                   message: "complete")
            return
        }
        let actualCount = events.count - 1
        verify(pass: actualCount == count,
               message: "complete after <\(count)>, completed after <\(actualCount)> instead")
    }
}
