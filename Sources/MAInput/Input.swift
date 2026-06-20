import CoreGraphics
import Foundation
import MAAccessibility
import os

private let log = Logger(subsystem: "com.macagentkit", category: "input")

/// Synthesize keyboard input via `CGEvent`.
///
/// Posting events requires the Accessibility permission (and, for some global
/// capture scenarios, Input Monitoring). Events are posted to the HID event tap.
///
/// > Note: This is a secondary module. For driving a specific control, prefer
/// > ``AXElement/press()`` — it's more reliable than synthesizing a click.
public enum Keyboard {

    /// Types a string by synthesizing Unicode key events, character by character.
    public static func type(_ text: String) {
        let source = CGEventSource(stateID: .hidSystemState)
        for character in text {
            let utf16 = Array(String(character).utf16)
            guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
                let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
            else {
                log.error("Failed to create keyboard event")
                continue
            }
            utf16.withUnsafeBufferPointer { buffer in
                if let base = buffer.baseAddress {
                    keyDown.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: base)
                    keyUp.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: base)
                }
            }
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
        }
    }

    /// Presses and releases a virtual key with optional modifier flags.
    public static func key(_ code: CGKeyCode, modifiers: CGEventFlags = []) {
        let source = CGEventSource(stateID: .hidSystemState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: false)
        else {
            log.error("Failed to create keyboard event for code \(code)")
            return
        }
        keyDown.flags = modifiers
        keyUp.flags = modifiers
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    /// A handful of common virtual key codes (US layout).
    public enum Key {
        public static let returnKey: CGKeyCode = 36
        public static let tab: CGKeyCode = 48
        public static let space: CGKeyCode = 49
        public static let delete: CGKeyCode = 51
        public static let escape: CGKeyCode = 53
        public static let leftArrow: CGKeyCode = 123
        public static let rightArrow: CGKeyCode = 124
        public static let downArrow: CGKeyCode = 125
        public static let upArrow: CGKeyCode = 126
    }
}

/// Synthesize mouse movement and clicks via `CGEvent`.
///
/// Coordinates are global display points with a top-left origin — the same space
/// as ``AXElement/frame``, so ``click(_:)`` can target an element directly.
public enum Mouse {

    /// Moves the cursor to a global point.
    public static func move(to point: CGPoint) {
        guard
            let event = CGEvent(
                mouseEventSource: CGEventSource(stateID: .hidSystemState),
                mouseType: .mouseMoved,
                mouseCursorPosition: point,
                mouseButton: .left
            )
        else {
            log.error("Failed to create mouse-move event")
            return
        }
        event.post(tap: .cghidEventTap)
    }

    /// Left-clicks at a global point.
    public static func click(at point: CGPoint) {
        let source = CGEventSource(stateID: .hidSystemState)
        guard
            let down = CGEvent(
                mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left),
            let up = CGEvent(
                mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left)
        else {
            log.error("Failed to create mouse-click event")
            return
        }
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }

    /// Left-clicks the centre of an element's frame.
    ///
    /// - Throws: ``AXFailure/noValue`` if the element has no frame.
    public static func click(_ element: AXElement) throws {
        guard let frame = element.frame else { throw AXFailure.noValue }
        click(at: CGPoint(x: frame.midX, y: frame.midY))
    }
}
