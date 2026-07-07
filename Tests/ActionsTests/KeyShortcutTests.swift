import XCTest
@testable import MouseStudioActions

final class KeyShortcutTests: XCTestCase {

    func testParsesSimpleShortcut() {
        let s = KeyShortcut(parsing: "cmd+c")
        XCTAssertEqual(s?.modifiers, [.command])
        XCTAssertEqual(s?.key, "c")
        XCTAssertEqual(s?.keyCode, 8)
    }

    func testParsesMultipleModifiers() {
        let s = KeyShortcut(parsing: "cmd+shift+z")
        XCTAssertEqual(s?.modifiers, [.command, .shift])
        XCTAssertEqual(s?.key, "z")
    }

    func testModifierSynonyms() {
        XCTAssertEqual(KeyShortcut(parsing: "control+right")?.modifiers, [.control])
        XCTAssertEqual(KeyShortcut(parsing: "ctrl+right")?.modifiers, [.control])
        XCTAssertEqual(KeyShortcut(parsing: "option+a")?.modifiers, [.option])
        XCTAssertEqual(KeyShortcut(parsing: "alt+a")?.modifiers, [.option])
    }

    func testParsesBracketAndArrowKeys() {
        XCTAssertEqual(KeyShortcut(parsing: "cmd+[")?.keyCode, 33)
        XCTAssertEqual(KeyShortcut(parsing: "cmd+]")?.keyCode, 30)
        XCTAssertEqual(KeyShortcut(parsing: "ctrl+left")?.keyCode, 123)
        XCTAssertEqual(KeyShortcut(parsing: "ctrl+up")?.keyCode, 126)
    }

    func testRejectsUnknownModifier() {
        XCTAssertNil(KeyShortcut(parsing: "hyper+c"))
    }

    func testRejectsUnknownKey() {
        XCTAssertNil(KeyShortcut(parsing: "cmd+£"))
    }

    func testKeyWithoutModifier() {
        let s = KeyShortcut(parsing: "f11")
        XCTAssertEqual(s?.modifiers, [])
        XCTAssertEqual(s?.keyCode, 103)
    }
}
