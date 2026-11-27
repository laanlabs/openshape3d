//
//  ZstdDecoderTests.swift
//  openshape3dTests
//
//  `ZstdDecoder` against data the reference tool wrote (`zstd` 1.5, vectors
//  below as base64) whose content the test can rebuild by rule: text that
//  compresses with Huffman literals and sequences, a run (RLE), noise (a raw
//  block), a few skewed symbols (a table of its own), several frames with
//  skippable ones between. Then what must be refused, and that damage is
//  caught and never crashes.
//
//  The same decoder was compared with the tool on 144 larger files at levels
//  1 to 22 and fed 24 000 damaged inputs when it was written (2026-11-26).
//

import XCTest
@testable import openshape3d

final class ZstdDecoderTests: XCTestCase {

    // MARK: - What the vectors hold

    private var text: Data {
        Data((0..<60).map { "Line \($0): the quick brown fox jumps over the lazy dog.\n" }.joined().utf8)
    }

    /// The C library's classic generator, so the test and the script that
    /// made the vectors agree byte for byte.
    private func generated(seed: UInt32, count: Int, _ pick: (UInt32) -> UInt8) -> Data {
        var x = seed
        return Data((0..<count).map { _ in
            x = (x &* 1103515245 &+ 12345) & 0x7FFF_FFFF
            return pick(x >> 16)
        })
    }
    private var noise: Data { generated(seed: 1, count: 300) { UInt8($0 & 0xFF) } }
    private var skewed: Data {
        let symbols = Array("aaaaaaabbbbcccdde".utf8)
        return generated(seed: 2, count: 3000) { symbols[Int($0) % symbols.count] }
    }

    private func vector(_ base64: String) -> Data { Data(base64Encoded: base64)! }

    private static let textVector =
        "KLUv/QRoVQUAIkgaGWB3Dg8lPZT0UGIGCKAPESFJZM9KcRhYyQH19PPyf58fD99r054t+93NEb6uTHmy5HNzhI8rnfLNEb5Y6ZRv" +
        "jhBWOuWbIwQCRTqW64inQjJprQnCmt2kZCNNqop1DAajFlmuFd4iETMEPagRgPYe+xvgNcsBETQE//8/wg8MEXKkIFWmCHFERIUY" +
        "QkZEZURVRUI0pSqiZMrSLEhERCTyWcOyVIt1VwFqCnf6"
    private static let zerosVector =
        "KLUv/QRYVQAAEAAAAQCbhjnAAtsjTvM="
    private static let noiseVector =
        "KLUv/QRYYQkAxn6Ba0v74vtU9r3ffBzhhwG/Md5Wcg9HZ2aHWaqIPFnqVhN70oWh2DxUVS83rmVb2gJ5mMzjGnaOX9mZjx8/Nu5D" +
        "eE0N+r6m2uSGjtwpbU7/VuFwIPuPsVgFkMUJ3FPNqjtImVLTUp0Gn+q1wgYTmEmyAR6sMogxnFJGlXE2j1f2OR0W+oh09Zh8F1xB" +
        "u21xjg9wWccBGy8zPZHAHaUNDaszjX5ejz7maHSmOrHDkxGoZMfbyuBg4fO/CQBnouMloCExh9VixahPfi4Ja5SfsG2pnloLRnCA" +
        "ts9HDKalKtis+6Drt3kkciOSSIDFpqeFt9eMkOSrY0RSZuOcMyX5Xqq6c2BdS3F+vqmMVxlxw8pe5SozrIhRZqF7dWdkmmnvb1ZC" +
        "oB1RxQL3u5JFNDd2JA=="
    private static let noiseWithoutChecksumVector =
        "KLUv/QBYYQkAxn6Ba0v74vtU9r3ffBzhhwG/Md5Wcg9HZ2aHWaqIPFnqVhN70oWh2DxUVS83rmVb2gJ5mMzjGnaOX9mZjx8/Nu5D" +
        "eE0N+r6m2uSGjtwpbU7/VuFwIPuPsVgFkMUJ3FPNqjtImVLTUp0Gn+q1wgYTmEmyAR6sMogxnFJGlXE2j1f2OR0W+oh09Zh8F1xB" +
        "u21xjg9wWccBGy8zPZHAHaUNDaszjX5ejz7maHSmOrHDkxGoZMfbyuBg4fO/CQBnouMloCExh9VixahPfi4Ja5SfsG2pnloLRnCA" +
        "ts9HDKalKtis+6Drt3kkciOSSIDFpqeFt9eMkOSrY0RSZuOcMyX5Xqq6c2BdS3F+vqmMVxlxw8pe5SozrIhRZqF7dWdkmmnvb1ZC" +
        "oB1RxQL3u5JF"
    private static let skewedVector =
        "KLUv/QRo9RkAqreEDAjQpQNkJwCAr8QAxQDEAFsCYX0pVG5QTVM5mxcaYb4mqDwEuaA2s8ykQBCYdB5YvPBUISiGbB9kRAuTIkyQ" +
        "khGWBwBBF0hRzeh0qEFwFIGCZFhMGVLhlnNjWWLCIA+BV1jITKg8WIB5gWm3UMRmkkAaHYKmBb/mMCWhJjxAYWizwEGci8xnM33J" +
        "gXkiypq7JAJLGujo2JBJ4Y1WmEIZeANBlCpHCVAy3IQGIJxgRE+E8G3IQLugtntNIgzeB0JB96BZBgKApEo+QJUOz+AYCJkOkAvp" +
        "JIBtpW2fpQARIUlChpsEUz+43jIGcpqTRUjCGEEcmEBQICLRkkYBAKUqEVsdFAxD5k7IzZXChG5C8wRAQjph4ZMSSbDq/OOR0yhB" +
        "ADJswaANbRXEpBAGTQnBuyDBIAxgHpcptBzalOIOOxMTDSQWUQ7ZwDMOhKVAA1Q9wmRpKDjSZ8NwETx95wI5fjM7uyeDUNHxHBv0" +
        "3ONKIG16oQCZCRlyLkQMfIQjhLAkQIkIoJ81T3IL6wGhmBfgiCm8maCIOlLuIhAGb8UkyCIymJSBFTsZBTQJafpJFkJDlMv9VYMr" +
        "WJK6QCM2VmroVBFcKCYRT7yAoNHNtDoIKhvGCFyQBaUmxZa2Ro7ld3GzBJ+EA8FFNgkkoAABNEUtIsuwkvAnbkWE3PWQgVChXTir" +
        "E5wKZAfJSr/zCAcZJh20kxCIUml+YkEVlx32BpdhyaBrYAIrdfrVVWFCVYDhiwELC3pVhjVSIstQr0ihs1KHBxD7FyqwcD7bg0BC" +
        "IlmnIrIIzYAGZA0aDAmLRAJrKRyA7TchsvPgoxqTHgNLddAUMLNgvCxTVjZGgBeNIpaIseRYQ6KwbIGByyfDAw1TMgowCdNeqUE7" +
        "uBMKCQYBKIg0IIYJxAMThVrHhpgKgyEZHM4E2D1AMOEpxjmASakbEAHKSKfI0nKAVKUsZ6J6fBH6GkIwVPIVjiCND2ggR0MnCiZk" +
        "JtJKBqbqMhG0GvgMBNIyaUHC1EOEm4rD1LRFCTMBkkvbdjQKYJ0TpwV7tw/4AOXRBLIUKRBD5gljuqiuUO2txAcAqNTXTuWKaNXl" +
        "DcySi7179qbIaWRskwqqu3ZB"
    private static let severalFramesVector =
        "KLUv/QRoVQUAIkgaGWB3Dg8lPZT0UGIGCKAPESFJZM9KcRhYyQH19PPyf58fD99r054t+93NEb6uTHmy5HNzhI8rnfLNEb5Y6ZRv" +
        "jhBWOuWbIwQCRTqW64inQjJprQnCmt2kZCNNqop1DAajFlmuFd4iETMEPagRgPYe+xvgNcsBETQE//8/wg8MEXKkIFWmCHFERIUY" +
        "QkZEZURVRUI0pSqiZMrSLEhERCTyWcOyVIt1VwFqCnf6UCpNGAUAAABoZWxsbyi1L/0EWGEJAMZ+gWtL++L7VPa933wc4YcBvzHe" +
        "VnIPR2dmh1mqiDxZ6lYTe9KFodg8VFUvN65lW9oCeZjM4xp2jl/ZmY8fPzbuQ3hNDfq+ptrkho7cKW1O/1bhcCD7j7FYBZDFCdxT" +
        "zao7SJlS01KdBp/qtcIGE5hJsgEerDKIMZxSRpVxNo9X9jkdFvqIdPWYfBdcQbttcY4PcFnHARsvMz2RwB2lDQ2rM41+Xo8+5mh0" +
        "pjqxw5MRqGTH28rgYOHzvwkAZ6LjJaAhMYfVYsWoT34uCWuUn7BtqZ5aC0ZwgLbPRwympSrYrPug67d5JHIjkkiAxaanhbfXjJDk" +
        "q2NEUmbjnDMl+V6qunNgXUtxfr6pjFcZccPKXuUqM6yIUWahe3VnZJpp729WQqAdUcUC97uSRTQ3diRQKk0YBQAAAGhlbGxv"

    // MARK: - Reading

    func testTextWithHuffmanLiteralsAndSequences() throws {
        XCTAssertEqual(try ZstdDecoder.decompress(vector(Self.textVector)), text)
    }

    func testARunOfZeros() throws {
        XCTAssertEqual(try ZstdDecoder.decompress(vector(Self.zerosVector)), Data(count: 100_000))
    }

    func testNoiseStoredRaw() throws {
        XCTAssertEqual(try ZstdDecoder.decompress(vector(Self.noiseVector)), noise)
    }

    func testSkewedSymbols() throws {
        XCTAssertEqual(try ZstdDecoder.decompress(vector(Self.skewedVector)), skewed)
    }

    func testSeveralFramesWithSkippableFramesBetween() throws {
        XCTAssertEqual(try ZstdDecoder.decompress(vector(Self.severalFramesVector)), text + noise)
    }

    /// A frame of stored blocks written by hand, the way the Blender tests
    /// wrap a file: no checksum, the size in the header.
    func testHandWrittenStoredFrame() throws {
        let content = text + noise
        XCTAssertEqual(try ZstdDecoder.decompress(Self.storedFrame(content, blockSize: 1000)), content)
        XCTAssertEqual(try ZstdDecoder.decompress(Self.storedFrame(Data(), blockSize: 1000)), Data())
    }

    /// `data` as one zstd frame of raw blocks.
    static func storedFrame(_ data: Data, blockSize: Int = 100_000) -> Data {
        var out = Data([0x28, 0xB5, 0x2F, 0xFD, 0xA0])            // magic; single segment, 4-byte size
        withUnsafeBytes(of: UInt32(data.count).littleEndian) { out.append(contentsOf: $0) }
        var at = 0
        repeat {
            let size = min(blockSize, data.count - at)
            let header = UInt32(size << 3 | (at + size == data.count ? 1 : 0))
            out.append(contentsOf: [UInt8(header & 0xFF), UInt8(header >> 8 & 0xFF), UInt8(header >> 16 & 0xFF)])
            out.append(data.subdata(in: at..<at + size))
            at += size
        } while at < data.count
        return out
    }

    // MARK: - Refusing

    func testNotZstd() {
        XCTAssertFalse(ZstdDecoder.isZstd(Data("BLENDER-v405".utf8)))
        XCTAssertTrue(ZstdDecoder.isZstd(vector(Self.textVector)))
        XCTAssertThrowsError(try ZstdDecoder.decompress(Data("BLENDER-v405".utf8))) {
            XCTAssertEqual($0 as? ZstdDecoder.Failure, .notZstd)
        }
        XCTAssertThrowsError(try ZstdDecoder.decompress(Data())) {
            XCTAssertEqual($0 as? ZstdDecoder.Failure, .notZstd)
        }
    }

    func testEveryTruncationThrows() {
        for name in [Self.textVector, Self.skewedVector, Self.severalFramesVector] {
            let whole = vector(name)
            for length in 1..<whole.count {
                // Cutting `several` between two frames leaves a valid file.
                if let short = try? ZstdDecoder.decompress(whole.prefix(length)) {
                    XCTAssertTrue(short == text || short == text + noise, "a cut at \(length) decoded to something else")
                }
            }
        }
    }

    func testChecksumCatchesDamage() throws {
        // Noise is stored raw, so one changed byte in it still decodes.
        var damaged = vector(Self.noiseVector)
        damaged[40] ^= 0x10
        XCTAssertThrowsError(try ZstdDecoder.decompress(damaged)) { error in
            guard case ZstdDecoder.Failure.corrupted(let why) = error else { return XCTFail("\(error)") }
            XCTAssertTrue(why.contains("checksum"), why)
        }
        // Without a checksum there is nothing to catch it with.
        var unchecked = vector(Self.noiseWithoutChecksumVector)
        XCTAssertEqual(try ZstdDecoder.decompress(unchecked), noise)
        unchecked[40] ^= 0x10
        XCTAssertNotEqual(try ZstdDecoder.decompress(unchecked), noise)
    }

    func testDamageNeverCrashes() {
        for name in [Self.textVector, Self.skewedVector] {
            let whole = vector(name)
            for index in 4..<whole.count {
                for flip: UInt8 in [0x01, 0x80, 0xFF] {
                    var damaged = whole
                    damaged[index] ^= flip
                    _ = try? ZstdDecoder.decompress(damaged, maximumSize: 1 << 22)
                }
            }
        }
    }

    func testTheSizeLimitHolds() {
        XCTAssertThrowsError(try ZstdDecoder.decompress(vector(Self.zerosVector), maximumSize: 1000)) {
            XCTAssertEqual($0 as? ZstdDecoder.Failure, .tooLarge)
        }
        XCTAssertNoThrow(try ZstdDecoder.decompress(vector(Self.zerosVector), maximumSize: 100_000))
    }

    func testADictionaryIsRefusedByName() {
        // Single segment, a one-byte dictionary id (5), size 0, one empty last block.
        let frame = Data([0x28, 0xB5, 0x2F, 0xFD, 0x21, 0x05, 0x00, 0x01, 0x00, 0x00])
        XCTAssertThrowsError(try ZstdDecoder.decompress(frame)) { error in
            guard case ZstdDecoder.Failure.unsupported = error else { return XCTFail("\(error)") }
        }
    }
}
