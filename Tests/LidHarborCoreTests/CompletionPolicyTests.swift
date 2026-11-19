import XCTest
@testable import LidHarborCore

final class CompletionPolicyTests: XCTestCase {
    func testIdleCPUDoesNotMeanCompletion() {
        XCTAssertFalse(CompletionPolicy.canReleaseSleep(activeTaskCount: 1, workersRemaining: 0, lifecycleConfirmed: false))
    }
    func testCompletedTasksWithNoWorkersCanReleaseSleep() {
        XCTAssertTrue(CompletionPolicy.canReleaseSleep(activeTaskCount: 0, workersRemaining: 0, lifecycleConfirmed: true))
    }
    func testOrphanWorkerKeepsProtection() {
        XCTAssertFalse(CompletionPolicy.canReleaseSleep(activeTaskCount: 0, workersRemaining: 1, lifecycleConfirmed: true))
    }
    func testMissingLifecycleSignalIsNotCompletion() {
        XCTAssertFalse(CompletionPolicy.canReleaseSleep(activeTaskCount: 0, workersRemaining: 0, lifecycleConfirmed: false))
    }
}
