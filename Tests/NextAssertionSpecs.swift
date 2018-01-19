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

        describe("assert next using `next()`") {
            context("no events sent") {
                beforeEach {
                    scheduler.start()
                }
                it("fail assert") {
                    expect { assert(sut).next() }
                        .toFail(with: "expected to next")
                }
                it("pass negated assert") {
                    expect { assert(sut).not.next() }
                        .notToFail()
                }
            }
            context("event sent") {
                beforeEach {
                    source.onNext("alpha")
                    scheduler.start()
                }
                it("pass assert") {
                    expect { assert(sut).next() }
                        .notToFail()
                }
                it("fail negated assert") {
                    expect { assert(sut).not.next() }
                        .toFail(with: "expected not to next")
                }
            }
        }

        describe("assert next at specific time using `next(at:)`") {
            context("no events sent") {
                beforeEach {
                    scheduler.start()
                }
                it("fail assert") {
                    expect { assert(sut).next(at: 10) }
                        .toFail(with: "expected to next @ <10>, did not get any events")
                }
                it("pass negated assert") {
                    expect { assert(sut).not.next(at: 10) }
                    .notToFail()
                }
            }
            context("event sent @ 10") {
                beforeEach {
                    scheduler.scheduleAt(10) { source.onNext("alpha") }
                    scheduler.start()
                }
                it("pass assert") {
                    expect { assert(sut).next(at: 10) }
                        .notToFail()
                }
                it("fail negated assert") {
                    expect { assert(sut).not.next(at: 10) }
                        .toFail(with: "expected not to next @ <10>, did get an event")
                }
            }
            context("event sent @ 20") {
                beforeEach {
                    scheduler.scheduleAt(20) { source.onNext("alpha") }
                    scheduler.start()
                }
                it("fail assert") {
                    expect { assert(sut).next(at: 10) }
                        .toFail(with: "expected to next @ <10>, did not get an event")
                }
                it("pass negated assert") {
                    expect { assert(sut).not.next(at: 10) }
                        .notToFail()
                }
            }
        }

        describe("assert next n times using `next(times:)`") {
            context("no events sent") {
                beforeEach {
                    scheduler.start()
                }
                it("fail assert") {
                    expect { assert(sut).next(times: 1) }
                        .toFail(with: "expected to next <1> times, did get <0> events")
                }
                it("pass negated assert") {
                    expect { assert(sut).not.next(times: 1) }
                        .notToFail()
                }
            }
            context("1 event sent") {
                beforeEach {
                    source.onNext("alpha")
                    scheduler.start()
                }
                it("pass assert") {
                    expect { assert(sut).next(times: 1) }
                        .notToFail()
                }
                it("fail negated assert") {
                    expect { assert(sut).not.next(times: 1) }
                        .toFail(with: "expected not to next <1> times, did get <1> events")
                }
            }
            context("2 events sent") {
                beforeEach {
                    source.onNext("alpha")
                    source.onNext("bravo")
                    scheduler.start()
                }
                it("fail assert") {
                    expect { assert(sut).next(times: 1) }
                        .toFail(with: "expected to next <1> times, did get <2> events")
                }
                it("pass negated assert") {
                    expect { assert(sut).not.next(times: 1) }
                        .notToFail()
                }
            }
        }
    }
}
