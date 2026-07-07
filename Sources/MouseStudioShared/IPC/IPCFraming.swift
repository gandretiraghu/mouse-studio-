import Foundation

/// The envelope for every message on the wire. A single socket carries requests
/// (GUI→service), responses (service→GUI), and pushed events (service→GUI).
public enum IPCMessage: Codable, Equatable, Sendable {
    case request(IPCRequest)
    case response(IPCResponse)
    case event(IPCEvent)
}

/// Errors from decoding framed messages.
public enum IPCFramingError: Error, Equatable {
    case frameTooLarge(Int)
    case decodeFailed
}

/// Length-prefixed JSON framing: a 4-byte big-endian UInt32 length followed by
/// that many bytes of JSON. This makes messages self-delimiting on a byte stream.
public enum IPCFraming {
    /// Guard against absurd allocations from a corrupt/hostile stream (TDD §13).
    public static let maxFrameBytes = 4 * 1024 * 1024   // 4 MB

    public static func encode(_ message: IPCMessage) throws -> Data {
        let payload = try JSONEncoder().encode(message)
        var length = UInt32(payload.count).bigEndian
        var out = Data(bytes: &length, count: 4)
        out.append(payload)
        return out
    }
}

/// Accumulates bytes from a stream and yields complete `IPCMessage`s as they
/// arrive. Handles partial frames and multiple frames per chunk.
public final class FrameDecoder {
    private var buffer = Data()

    public init() {}

    /// Feed newly-read bytes; returns any complete messages decoded so far.
    public func feed(_ data: Data) throws -> [IPCMessage] {
        buffer.append(data)
        var messages: [IPCMessage] = []

        while buffer.count >= 4 {
            let length = buffer.prefix(4).reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
            let frameLength = Int(length)
            if frameLength > IPCFraming.maxFrameBytes {
                throw IPCFramingError.frameTooLarge(frameLength)
            }
            guard buffer.count >= 4 + frameLength else { break }  // wait for more bytes

            let start = buffer.index(buffer.startIndex, offsetBy: 4)
            let end = buffer.index(start, offsetBy: frameLength)
            let payload = buffer[start..<end]

            do {
                messages.append(try JSONDecoder().decode(IPCMessage.self, from: Data(payload)))
            } catch {
                throw IPCFramingError.decodeFailed
            }
            buffer.removeSubrange(buffer.startIndex..<end)
        }
        return messages
    }

    public func reset() { buffer.removeAll() }
}
