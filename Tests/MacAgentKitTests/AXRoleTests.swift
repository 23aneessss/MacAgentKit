import Testing
import ApplicationServices
@testable import MAAccessibility

@Suite("AXRole")
struct AXRoleTests {
    @Test("Static constants carry the correct raw AX strings")
    func staticConstants() {
        #expect(AXRole.button.rawValue == kAXButtonRole)
        #expect(AXRole.window.rawValue == kAXWindowRole)
        #expect(AXRole.application.rawValue == kAXApplicationRole)
        #expect(AXRole.webArea.rawValue == "AXWebArea")
    }

    @Test("String-literal and raw initialisers are equivalent")
    func initialisers() {
        let fromLiteral: AXRole = "AXButton"
        #expect(fromLiteral == AXRole(rawValue: "AXButton"))
        #expect(fromLiteral == AXRole("AXButton"))
        #expect(fromLiteral == .button)
    }

    @Test("Roles are Hashable and distinct")
    func hashing() {
        let set: Set<AXRole> = [.button, .window, .button]
        #expect(set.count == 2)
    }
}
