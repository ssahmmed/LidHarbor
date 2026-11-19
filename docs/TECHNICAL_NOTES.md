# Prototype technical notes

## Demo supervisor

`Sources/LidHarborCore/MacSupervisor.swift` declares native `libproc` process enumeration and parent PID mapping. `descendants(of:from:)` is a bounded breadth-first traversal with a visited set. The initial prototype is READ ONLY and deliberately avoids arbitrary signals to unknown processes.

Limitations: the code currently selects by executable substring in the demo. Production versions require exact executable/user verification, process start time to handle PID reuse, and stronger child attribution for reparented workers. `proc_listpids` snapshots can race process exits, and a process may be invisible due to permission restrictions.

## Assertion lifecycle

`IdleSleepAssertion` acquires `kIOPMAssertionTypePreventUserIdleSystemSleep` and explicitly releases it. It also releases on deinitialization during normal teardown. This is not a guarantee against force quit, power failure, or clamshell sleep. A closed-lid feature must be independently engineered and hardware-validated with a restoration lease before it is represented as supported.

## Completion lifecycle

`CompletionPolicy.canReleaseSleep` requires all three conditions: zero active tasks, zero remaining workers, and a confirmed lifecycle terminal signal. This function is currently standalone; it is not yet connected to running agents. Zero CPU use is not an input.

## Verification history

`swift test` on Linux Swift 6: 4 tests passed, 0 failures. macOS conditional paths were not compiled on Linux, so Apple's build and hardware tests remain outstanding.
