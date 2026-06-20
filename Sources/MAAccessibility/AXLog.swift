import os

/// Shared loggers for MacAgentKit. Library code never uses `print`.
///
/// All subsystems share `com.macagentkit`; each module uses its own category.
enum AXLog {
    static let accessibility = Logger(subsystem: "com.macagentkit", category: "accessibility")
    static let observer = Logger(subsystem: "com.macagentkit", category: "ax-observer")
}
