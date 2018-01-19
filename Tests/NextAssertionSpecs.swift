import Quick
import RxSwift
import RxTest
@testable import RxTestExt

class NextAssertionSpecs: QuickSpec {
    override func spec() {
        var scheduler: TestScheduler!
        var source: PublishSubject<String>!
        var sut: TestableObserver<String>!

        beforeEach {
            scheduler = TestScheduler(initialClock: 0)
            source = PublishSubject()
            sut = scheduler.record(source: source)
        }
        afterEach {
            sut = nil
            source = nil
            scheduler = nil
        }

        describe("Next Event") {
            it("assert positive, next event sent") {
                source.onNext("alpha")
                scheduler.start()
                expect { assert(sut).next() }
                    .notToFail()
            }
            it("assert negative, next event not sent") {
                source.onCompleted()
                scheduler.start()
                expect { assert(sut).next() }
                    .toFail(with: "expected to next")
            }
        }

        describe("Next Event @ Time") {
            it("assert positive, next event sent at time") {
                scheduler.scheduleAt(10) { source.onNext("alpha") }
                scheduler.start()
                expect { assert(sut).next(at: 10) }
                    .notToFail()
            }
            it("assert negative, next event sent at different time") {
                scheduler.scheduleAt(20) { source.onCompleted() }
                scheduler.start()
                expect { assert(sut).next(at: 10) }
                    .toFail(with: "expected to next at <10>")
            }
        }

        describe("Next Event (n) Times") {
            it("assert positive, next event sent 2 times") {
                source.onNext("alpha")
                source.onNext("bravo")
                scheduler.start()
                expect { assert(sut).next(times: 2) }
                    .notToFail()
            }

            it("assert negative, next event sent 1 time") {
                source.onNext("alpha")
                scheduler.start()
                expect { assert(sut).next(times: 2) }
                    .toFail(with: "expected to next <2> times, got <1> event(s)")
            }
        }
    }
}
