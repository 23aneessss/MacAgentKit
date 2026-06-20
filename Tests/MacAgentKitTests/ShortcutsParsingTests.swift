import Testing

@testable import MAShortcuts

@Suite("Shortcuts list parsing")
struct ShortcutsParsingTests {
    @Test("Splits, trims, and drops blank lines")
    func parsing() {
        let output = "Focus Mode\n  Toggle Wi-Fi  \n\nSend Message\n\n"
        let names = Shortcuts.parseList(output)
        #expect(names == ["Focus Mode", "Toggle Wi-Fi", "Send Message"])
    }

    @Test("Empty output yields no names")
    func empty() {
        #expect(Shortcuts.parseList("").isEmpty)
        #expect(Shortcuts.parseList("\n\n   \n").isEmpty)
    }

    @Test("Single name without trailing newline")
    func single() {
        #expect(Shortcuts.parseList("Only One") == ["Only One"])
    }
}
