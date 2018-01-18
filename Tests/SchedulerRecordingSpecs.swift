import Quick
import RxSwift
import RxCocoa
import RxTest
@testable import RxTestExt

class SchedulerRecordingSpecs: QuickSpec {

    override func spec() {
        var scheduler: TestScheduler!

        beforeEach {
            scheduler = TestScheduler(initialClock: 0)
        }

        afterEach {
            scheduler = nil
        }

        it("record all events")  {
            let subject = PublishSubject<String>()
            let events = [next(10, "alpha"), completed(10)]
            let source = scheduler.record(source: subject.asObservable())
            scheduler.bind(events, to: subject.asObserver())
            scheduler.start()
            XCTAssertEqual(source.events, events)
        }
        it("record all events from PublishRelay") {
            let events = [next(10, "alpha")]
            let publishRelay = PublishRelay<String>()
            let source = scheduler.record(source: publishRelay.asObservable())
            scheduler.bind(events, to: publishRelay)
            scheduler.start()
            XCTAssertEqual(source.events, events)
        }

        it("record all events from BehaviorRelay") {
            let events = [next(10, "alpha")]
            let behaviorRelay = BehaviorRelay<String>(value: "start")
            let source = scheduler.record(source: behaviorRelay.asObservable())
            scheduler.bind(events, to: behaviorRelay)
            scheduler.start()
            XCTAssertEqual(source.events, [next(0, "start")] + events)
        }
    }
}
