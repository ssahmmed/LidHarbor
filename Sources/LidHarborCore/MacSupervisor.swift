#if os(macOS)
import Foundation
import Darwin
import Darwin.libproc
import IOKit.pwr_mgt

public struct MacProcess: Identifiable, CustomStringConvertible {
    public let pid: pid_t
    public let parentPID: pid_t
    public let executable: String
    public var id: pid_t { pid }
    public var description: String { "pid=\(pid) ppid=\(parentPID) executable=\(executable)" }
}

public enum SupervisorError: Error {
    case processEnumerationFailed
    case assertionFailed(IOReturn)
}

/// Read-only process-tree discovery. Do not trust PID alone as a persistent identity:
/// production code must also record process start time and owner UID to prevent PID reuse.
public struct MacProcessSupervisor {
    public init() {}

    public func allProcesses() throws -> [MacProcess] {
        let byteCount = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard byteCount > 0 else { throw SupervisorError.processEnumerationFailed }
        var pids = [pid_t](repeating: 0, count: Int(byteCount) / MemoryLayout<pid_t>.size + 64)
        let filled = pids.withUnsafeMutableBytes { bytes in
            proc_listpids(UInt32(PROC_ALL_PIDS), 0, bytes.baseAddress, Int32(bytes.count))
        }
        guard filled > 0 else { throw SupervisorError.processEnumerationFailed }
        return pids.prefix(Int(filled) / MemoryLayout<pid_t>.size).compactMap { pid in
            guard pid > 0 else { return nil }
            var info = proc_bsdinfo()
            let size = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, Int32(MemoryLayout<proc_bsdinfo>.size))
            guard size == MemoryLayout<proc_bsdinfo>.size else { return nil }
            var path = [CChar](repeating: 0, count: Int(PROC_PIDPATHINFO_MAXSIZE))
            let pathSize = proc_pidpath(pid, &path, UInt32(path.count))
            guard pathSize > 0 else { return nil }
            return MacProcess(pid: pid, parentPID: pid_t(info.pbi_ppid), executable: String(cString: path))
        }
    }

    public func descendants(of root: pid_t, from processes: [MacProcess]) -> [MacProcess] {
        var visited: Set<pid_t> = [root]
        var frontier: [pid_t] = [root]
        var found: [MacProcess] = []
        while !frontier.isEmpty {
            let parent = frontier.removeFirst()
            for child in processes where child.parentPID == parent && !visited.contains(child.pid) {
                visited.insert(child.pid)
                found.append(child)
                frontier.append(child.pid)
            }
        }
        return found
    }
}

/// Supported IOPM idle-sleep assertion. It DOES NOT defeat lid-close sleep.
/// It intentionally avoids undocumented pmset settings and root privileges.
public final class IdleSleepAssertion {
    private var assertion: IOPMAssertionID = 0
    public var active: Bool { assertion != 0 }
    public init() {}
    public func acquire(reason: String = "Selected local AI agent is working") throws {
        guard !active else { return }
        var id: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn), reason as CFString, &id
        )
        guard result == kIOReturnSuccess else { throw SupervisorError.assertionFailed(result) }
        assertion = id
    }
    public func release() {
        guard active else { return }
        IOPMAssertionRelease(assertion)
        assertion = 0
    }
    deinit { release() }
}
#endif
