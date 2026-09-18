//
//  AgentHTTP.swift
//  openshape3d
//
//  The request half of the DEBUG-only agent bridge: an incremental HTTP/1.1
//  parser over an accumulating byte buffer.
//
//  `AgentServer` originally read only as far as the `\r\n\r\n` terminator and
//  threw everything after it away, which is why the channel could answer
//  `GET /v1/health` and nothing else — there was no way to carry a body, so no
//  way to POST a command. This is the piece that was promised in that file's
//  header and never written.
//
//  It is a pure function over `Data` on purpose. Sockets are the part of a
//  server that cannot be unit-tested; framing is the part that actually gets
//  the edge cases wrong (a body split across two TCP reads, a `Content-Length`
//  that lies, a header block that never terminates). Keeping them separate is
//  the same split `CommandDispatch.swift` makes between `routableIDs` (pure,
//  tested) and `runCommand` (thin, untestable) — and for the same reason.
//
//  Everything is explicitly `nonisolated` because the project builds with
//  `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; without it these types would be
//  implicitly main-actor and could not be touched from the listener queue.
//


import Foundation

// MARK: - A parsed request

nonisolated struct AgentRequest: Sendable, Equatable {
    /// Upper-cased: `GET`, `POST`.
    var method: String
    /// Path only, query stripped: `/v1/command`.
    var path: String
    /// Percent-decoded query items. Repeated keys keep the last value.
    var query: [String: String] = [:]
    /// Header names lower-cased, values trimmed.
    var headers: [String: String] = [:]
    /// Exactly `Content-Length` bytes; empty when the header is absent.
    var body: Data = Data()

    /// Convenience for the router: decode the body as a JSON object.
    var jsonBody: [String: Any]? {
        guard !body.isEmpty else { return nil }
        return (try? JSONSerialization.jsonObject(with: body)) as? [String: Any]
    }

    /// Query integer with a bound, for `?w=` / `?h=`.
    func intQuery(_ name: String, default fallback: Int, min: Int, max: Int) -> Int {
        guard let raw = query[name], let value = Int(raw) else { return fallback }
        return Swift.min(Swift.max(value, min), max)
    }
}

// MARK: - Parsing

nonisolated enum AgentHTTP {

    /// Bodies above this are refused with 413 rather than buffered. The largest
    /// thing the protocol carries inbound is a small JSON object; a cap keeps a
    /// stuck or hostile client from growing the buffer without bound.
    static let maxBodyBytes = 1 << 20  // 1 MiB

    /// Same idea for the head. A client that never sends `\r\n\r\n` would
    /// otherwise be indistinguishable from one that is merely slow.
    static let maxHeadBytes = 64 * 1024

    nonisolated enum ParseResult: Sendable, Equatable {
        /// Need more bytes; call again when the next chunk arrives.
        case incomplete
        case complete(AgentRequest)
        /// Unparseable — answer 400 and close. The string is for the log only.
        case malformed(String)
        /// `Content-Length` exceeds `maxBodyBytes` — answer 413 and close.
        case tooLarge
    }

    /// Parse whatever has arrived so far.
    ///
    /// Deliberately re-parses the whole buffer on every chunk instead of
    /// keeping a resumable cursor. Requests here are a few hundred bytes and
    /// arrive one at a time; a stateful parser would buy nothing and is exactly
    /// the kind of thing that breaks on a split boundary.
    static func parse(_ buffer: Data) -> ParseResult {
        guard let headEnd = terminator(in: buffer) else {
            if buffer.count > maxHeadBytes { return .malformed("header block too large") }
            return .incomplete
        }

        let head = String(decoding: buffer[buffer.startIndex..<headEnd], as: UTF8.self)
        var lines = head.components(separatedBy: "\r\n")
        guard !lines.isEmpty else { return .malformed("empty head") }

        // Request line: METHOD TARGET [VERSION]
        let requestLine = lines.removeFirst()
        let fields = requestLine.split(separator: " ", omittingEmptySubsequences: true)
        guard fields.count >= 2 else { return .malformed("bad request line: \(requestLine)") }
        let method = String(fields[0]).uppercased()
        let target = String(fields[1])

        var request = AgentRequest(method: method, path: target)
        (request.path, request.query) = splitTarget(target)

        // Headers. A line without a colon means the framing is already wrong;
        // guessing past it risks mis-reading Content-Length, so refuse instead.
        for line in lines where !line.isEmpty {
            guard let colon = line.firstIndex(of: ":") else {
                return .malformed("bad header line: \(line)")
            }
            let name = line[line.startIndex..<colon]
                .trimmingCharacters(in: .whitespaces).lowercased()
            let value = line[line.index(after: colon)...]
                .trimmingCharacters(in: .whitespaces)
            request.headers[name] = value
        }

        // Body.
        let bodyStart = buffer.index(headEnd, offsetBy: 4)  // past "\r\n\r\n"
        if let rawLength = request.headers["content-length"] {
            guard let length = Int(rawLength), length >= 0 else {
                return .malformed("bad Content-Length: \(rawLength)")
            }
            guard length <= maxBodyBytes else { return .tooLarge }
            let available = buffer.distance(from: bodyStart, to: buffer.endIndex)
            guard available >= length else { return .incomplete }
            let bodyEnd = buffer.index(bodyStart, offsetBy: length)
            request.body = Data(buffer[bodyStart..<bodyEnd])
        }

        return .complete(request)
    }

    /// Index of the `\r\n\r\n` that ends the head, if it has arrived.
    static func terminator(in data: Data) -> Data.Index? {
        data.range(of: Data("\r\n\r\n".utf8))?.lowerBound
    }

    /// `/v1/screenshot?w=800&h=600` → (`/v1/screenshot`, `["w": "800", …]`).
    static func splitTarget(_ target: String) -> (path: String, query: [String: String]) {
        guard let mark = target.firstIndex(of: "?") else { return (target, [:]) }
        let path = String(target[target.startIndex..<mark])
        var query: [String: String] = [:]
        for pair in target[target.index(after: mark)...].split(separator: "&") {
            let halves = pair.split(separator: "=", maxSplits: 1)
            guard let name = halves.first?.removingPercentEncoding else { continue }
            let value = halves.count > 1 ? (halves[1].removingPercentEncoding ?? "") : ""
            query[name] = value
        }
        return (path, query)
    }
}

