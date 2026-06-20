import Testing

@testable import MAPermissions

@Suite("Permission")
struct PermissionTests {
    @Test("Display names are sensible")
    func displayNames() {
        #expect(Permission.accessibility.displayName == "Accessibility")
        #expect(Permission.screenRecording.displayName == "Screen Recording")
        #expect(Permission.inputMonitoring.displayName == "Input Monitoring")
        #expect(Permission.automation(bundleID: "com.apple.finder").displayName.contains("com.apple.finder"))
    }

    @Test("Automation permissions compare by bundle id")
    func automationEquality() {
        #expect(Permission.automation(bundleID: "a") == Permission.automation(bundleID: "a"))
        #expect(Permission.automation(bundleID: "a") != Permission.automation(bundleID: "b"))
    }

    @Test("Permissions are Hashable")
    func hashable() {
        let set: Set<Permission> = [.accessibility, .accessibility, .screenRecording]
        #expect(set.count == 2)
    }
}
