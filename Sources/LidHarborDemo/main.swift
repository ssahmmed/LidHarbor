import Foundation
import LidHarborCore

#if os(macOS)
let args = CommandLine.arguments
let supervisor = MacProcessSupervisor()
do {
    let all = try supervisor.allProcesses()
    let matches = all.filter { $0.executable.lowercased().contains("hermes") || $0.executable.lowercased().contains("codex") }
    for process in matches {
        print("Agent candidate: \(process)")
        for child in supervisor.descendants(of: process.pid, from: all) { print("  Worker: \(child)") }
    }
    if args.contains("--assert-30") {
        let assertion = IdleSleepAssertion()
        try assertion.acquire()
        print("Idle system sleep inhibited for 30 seconds. Lid closing is NOT supported by this assertion.")
        Thread.sleep(forTimeInterval: 30)
        assertion.release()
    } else {
        print("Read-only discovery complete. Pass --assert-30 to test a 30-second idle-sleep assertion.")
    }
} catch { fputs("Error: \(error)\n", stderr); exit(1) }
#else
print("Run this demo on macOS for libproc discovery and IOPM assertions.")
#endif
