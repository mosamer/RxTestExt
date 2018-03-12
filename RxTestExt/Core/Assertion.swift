import XCTest
import RxSwift
import RxTest

struct Location {
    let file: StaticString
    let line: UInt
}

class Environment {
    static let instance = Environment()

    static let defaultHandler: (String, Location) -> Void = {message, location in
        XCTFail(message, file: location.file, line: location.line)
    }

    var assertionHandler = Environment.defaultHandler

    func fail(with message: String, location: Location) {
        assertionHandler(message, location)
    }
}

public struct Assertion<T> {

    enum FailureMessage {

        case concise(String)
        case full(String, String)
        case exact(String)

        func stringify(as negated: Bool) -> String {
            var msg = "expected"
            msg.append(negated ? " not to " : " to ")
            switch self {
            case .concise(let message):
                msg.append(message)
            case .full(let message, let actual):
                msg.append(message)
                msg.append(negated ? ", did " : ", did not ")
                msg.append(actual)
            case .exact(let message):
                msg.append(message)
            }
            return msg
        }
    }
    let base: TestableObserver<T>
    let location: Location
    let negated: Bool
    init(_ base: TestableObserver<T>, file: StaticString, line: UInt, negated: Bool = false) {
        self.base = base
        self.location = Location(file: file, line: line)
        self.negated = negated
    }

    func verify(pass: Bool, message: FailureMessage) {
        if pass == negated {
            Environment.instance.fail(with: message.stringify(as: negated), location: location)
        }
    }

    func verify(pass: Bool, message: String) {
        if pass == negated {
            Environment.instance.fail(with: "expected \(negated ? "not " : "")to \(message)", location: location)
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
