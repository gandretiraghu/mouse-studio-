import XCTest
@testable import MouseStudioCore
import MouseStudioShared

/// Deterministic tests for the gesture state machine using a virtual clock
/// (`ManualScheduler`) so timing behavior is exact and non-flaky (TDD §16.1).
final class StateMachineTests: XCTestCase {

    private func makeSM(
        double: Set<ButtonID> = [],
        timing: TimingConfig = .default
    ) -> (StateMachine, ManualScheduler, GestureCollector) {
        let scheduler = ManualScheduler()
        let sm = StateMachine(timing: timing, scheduler: scheduler)
        let collector = GestureCollector()
        sm.onGesture = { collector.append($0) }
        sm.setDoubleMappedButtons(double)
        return (sm, scheduler, collector)
    }

    // MARK: Single

    func testSingleClickNotDoubleMappedEmitsImmediately() {
        let (sm, _, c) = makeSM(double: [])
        sm.feed(.down(.left))
        sm.feed(.up(.left))
        XCTAssertEqual(c.kinds, [.single])
        XCTAssertEqual(c.gestures.first?.anchor, .left)
    }

    func testSingleClickDoubleMappedWaitsThenEmits() {
        let (sm, scheduler, c) = makeSM(double: [.left])
        sm.feed(.down(.left))
        sm.feed(.up(.left))
        XCTAssertEqual(c.kinds, [], "should wait for possible second click")
        scheduler.advance(byMs: 250)
        XCTAssertEqual(c.kinds, [.single])
    }

    // MARK: Double

    func testDoubleClick() {
        let (sm, scheduler, c) = makeSM(double: [.button4])
        sm.feed(.down(.button4))
        sm.feed(.up(.button4))       // schedules double window
        sm.feed(.down(.button4))     // second press within window cancels it
        sm.feed(.up(.button4))
        XCTAssertEqual(c.kinds, [.double])
        scheduler.advance(byMs: 500)
        XCTAssertEqual(c.kinds, [.double], "no stray single after double")
    }

    // MARK: Long press

    func testLongPress() {
        let (sm, scheduler, c) = makeSM(double: [])
        sm.feed(.down(.button5))
        scheduler.advance(byMs: 350)     // long threshold elapses while held
        XCTAssertEqual(c.kinds, [], "long is emitted on release, not on threshold")
        sm.feed(.up(.button5))
        XCTAssertEqual(c.kinds, [.long])
    }

    func testReleaseBeforeLongThresholdIsSingle() {
        let (sm, scheduler, c) = makeSM(double: [])
        sm.feed(.down(.button5))
        scheduler.advance(byMs: 100)     // released early
        sm.feed(.up(.button5))
        XCTAssertEqual(c.kinds, [.single])
    }

    // MARK: Chord scroll

    func testChordScrollUp() {
        let (sm, _, c) = makeSM(double: [])
        sm.feed(.down(.button4))         // anchor held
        sm.feed(.scroll(.up))
        sm.feed(.up(.button4))           // anchor release suppressed
        XCTAssertEqual(c.kinds, [.chordScrollUp])
        XCTAssertEqual(c.gestures.first?.anchor, .button4)
        XCTAssertEqual(c.gestures.first?.scroll, .up)
    }

    func testChordScrollSuppressesAnchorSingle() {
        let (sm, scheduler, c) = makeSM(double: [])
        sm.feed(.down(.button4))
        sm.feed(.scroll(.down))
        sm.feed(.up(.button4))
        scheduler.advance(byMs: 500)
        XCTAssertEqual(c.kinds, [.chordScrollDown], "anchor's own single must be suppressed")
    }

    // MARK: Chord click

    func testChordClick() {
        let (sm, _, c) = makeSM(double: [])
        sm.feed(.down(.button4))         // anchor
        sm.feed(.down(.left))            // chord partner
        sm.feed(.up(.left))
        sm.feed(.up(.button4))
        XCTAssertEqual(c.kinds, [.chordClick])
        XCTAssertEqual(c.gestures.first?.anchor, .button4)
        XCTAssertEqual(c.gestures.first?.chordButton, .left)
    }

    func testChordClickSuppressesBothButtonsSingles() {
        let (sm, scheduler, c) = makeSM(double: [])
        sm.feed(.down(.button4))
        sm.feed(.down(.left))
        sm.feed(.up(.left))
        sm.feed(.up(.button4))
        scheduler.advance(byMs: 500)
        XCTAssertEqual(c.kinds, [.chordClick], "neither the anchor nor the partner should emit a single")
    }
}

/// Simple thread-confined collector of emitted gestures for assertions.
final class GestureCollector {
    private(set) var gestures: [Gesture] = []
    func append(_ g: Gesture) { gestures.append(g) }
    var kinds: [GestureKind] { gestures.map { $0.kind } }
}
