import Quick
import RxSwift
import RxTest
@testable import RxTestExt

class ErrorAssertionSpecs: QuickSpec {
    override func spec() {
        var scheduler: TestScheduler!
        var source: PublishSubject<String>!
        var sut: TestableObserver<String>!

        beforeEach {
            scheduler = TestScheduler(initialClock: 0)
            source = PublishSubject()
            sut = scheduler.record(source: source)
        }

        describe("assert error using `error()`") {
            context("no errors") {
                beforeEach {
                    source.onNext("alpha")
                    scheduler.start()
                }
                it("fail assert") {
                    expect { assert(sut).error() }
                        .toFail(with: "expected to error")
                }
                it("pass negated assert") {
                    expect { assert(sut).not.error() }
                        .notToFail()
                }
            }
            context("error emitted") {
                beforeEach {
                    source.onError(TestError())
                    scheduler.start()
                }
                it("pass assert") {
                    expect { assert(sut).error() }
                        .notToFail()
                }
                it("fail negated assert") {
                    expect { assert(sut).not.error() }
                        .toFail(with: "expected not to error")
                }
            }
        }

        describe("assert error at specific time using `error(at:)`") {
            context("no error events") {
                beforeEach {
                    source.onNext("alpha")
                    scheduler.start()
                }
                it("fail assert") {
                    expect { assert(sut).error(at: 10) }
                        .toFail(with: "expected to error @ <10>")
                }
                it("pass negated assert") {
                    expect { assert(sut).not.error(at: 10) }
                        .notToFail()
                }
            }
            context("error event @ 10") {
                beforeEach {
                    scheduler.scheduleAt(10) { source.onError(TestError()) }
                    scheduler.start()
                }
                it("pass assert") {
                    expect { assert(sut).error(at: 10) }
                        .notToFail()
                }
                it("fail negated assert") {
                    expect { assert(sut).not.error(at: 10) }
                        .toFail(with: "expected not to error @ <10>")
                }
            }
            context("error event @ 20") {
                beforeEach {
                    scheduler.scheduleAt(20) { source.onError(TestError()) }
                    scheduler.start()
                }
                it("fail assert") {
                    expect { assert(sut).error(at: 10) }
                        .toFail(with: "expected to error @ <10>, did error @ <20> instead")
                }
                it("pass negated assert") {
                    expect { assert(sut).not.error(at: 10) }
                        .notToFail()
                }
            }
        }

        describe("assert error after specific number of events using `error(after:)`") {
            context("no error events") {
                beforeEach {
                    source.onNext("alpha")
                    scheduler.start()
                }
                it("fail assert") {
                    expect { assert(sut).error(after: 1) }
                        .toFail(with: "expected to error after <1> events")
                }
                it("pass negated assert") {
                    expect { assert(sut).not.error(after: 1) }
                        .notToFail()
                }
            }
            context("error after 1 event") {
                beforeEach {
                    source.onNext("alpha")
                    source.onError(TestError())
                    scheduler.start()
                }
                it("pass assert") {
                    expect { assert(sut).error(after: 1) }
                        .notToFail()
                }
                it("fail negated assert") {
                    expect { assert(sut).not.error(after: 1) }
                        .toFail(with: "expected not to error after <1> events")
                }
            }
            context("error after 2 events") {
                beforeEach {
                    source.onNext("alpha")
                    source.onNext("bravo")
                    source.onError(TestError())
                    scheduler.start()
                }
                it("fail assert") {
                    expect { assert(sut).error(after: 1) }
                        .toFail(with: "expected to error after <1> events, did error after <2> instead")
                }
                it("pass negated assert") {
                    expect { assert(sut).not.error(after: 1) }
                        .notToFail()
                }
            }
        }
    }
}
