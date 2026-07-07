import XCTest
import MouseStudioShared

/// Tests for the IPC wire framing/codec (the transport-independent, testable part
/// of the socket IPC) — TDD §10.2.
final class FramingTests: XCTestCase {

    private let messages: [IPCMessage] = [
        .request(.getStatus),
        .response(.status(.running)),
        .event(.liveButton(.button4)),
        .request(.setActiveProfile("gaming")),
        .response(.ack),
        .event(.engineStateChanged(.learning))
    ]

    func testSingleMessageRoundTrip() throws {
        let decoder = FrameDecoder()
        for message in messages {
            let data = try IPCFraming.encode(message)
            let decoded = try decoder.feed(data)
            XCTAssertEqual(decoded, [message])
        }
    }

    func testMultipleFramesInOneChunk() throws {
        var combined = Data()
        for message in messages { combined.append(try IPCFraming.encode(message)) }
        let decoder = FrameDecoder()
        XCTAssertEqual(try decoder.feed(combined), messages)
    }

    func testPartialFramesAcrossChunks() throws {
        var combined = Data()
        for message in messages { combined.append(try IPCFraming.encode(message)) }

        let decoder = FrameDecoder()
        var out: [IPCMessage] = []
        // Feed one byte at a time — the decoder must reassemble.
        for byte in combined {
            out.append(contentsOf: try decoder.feed(Data([byte])))
        }
        XCTAssertEqual(out, messages)
    }

    func testFrameTooLargeThrows() {
        // Craft a length prefix beyond the max with no payload.
        var data = Data()
        let huge = UInt32(IPCFraming.maxFrameBytes + 1).bigEndian
        withUnsafeBytes(of: huge) { data.append(contentsOf: $0) }
        let decoder = FrameDecoder()
        XCTAssertThrowsError(try decoder.feed(data)) { error in
            XCTAssertEqual(error as? IPCFramingError, .frameTooLarge(IPCFraming.maxFrameBytes + 1))
        }
    }

    func testTestRuleMessageRoundTrip() throws {
        let rule = Rule(id: "r", trigger: TriggerSpec(button: .button4, gesture: .double),
                        action: ActionSpec(type: "app.launch", params: ["bundleID": .string("com.apple.finder")]))
        let message = IPCMessage.request(.testRule(rule))
        let decoder = FrameDecoder()
        XCTAssertEqual(try decoder.feed(try IPCFraming.encode(message)), [message])
    }
}
