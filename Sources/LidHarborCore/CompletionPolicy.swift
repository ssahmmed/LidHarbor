public enum CompletionPolicy {
    /// A quiet process is not a completed task. Call only after an adapter has
    /// observed a terminal lifecycle event for the selected session.
    public static func canReleaseSleep(activeTaskCount: Int, workersRemaining: Int, lifecycleConfirmed: Bool) -> Bool {
        lifecycleConfirmed && activeTaskCount == 0 && workersRemaining == 0
    }
}
