//
//  ZstdDecoder.swift
//  openshape3d
//
//  Decompresses Zstandard data (RFC 8878), written here from the format
//  description: Blender has saved its "Compress" files as zstd since 3.0, and
//  the system's Compression framework does not read it.
//
//  Decode only, and only what a file on disk needs: any number of frames one
//  after another (Blender writes one per ~256 KB so it can seek), skippable
//  frames (the seek table Blender puts at the end is one), raw / RLE /
//  compressed blocks, Huffman literals in one or four streams, FSE sequence
//  tables in all four modes, repeat offsets, and a frame's content checksum
//  (XXH64) where it has one. Not supported, and refused by name:
//  dictionaries.
//
//  Every read is bounds-checked and a malformed input throws; nothing here
//  trusts a length it was given.
//
//  `Int` is 32 bits in the web app's engine (WebAssembly). Anything that can
//  pass 31 bits — a magic number, a checksum, a content size, an offset's
//  extra bits — is held in a sized type and only becomes an `Int` once it
//  is known to fit.
//

import Foundation

nonisolated enum ZstdDecoder {

    enum Failure: Error, Equatable {
        case notZstd
        case truncated
        case corrupted(String)
        case unsupported(String)
        /// The output would pass the caller's limit.
        case tooLarge
    }

    /// Does `data` start with a zstd frame or a skippable frame?
    static func isZstd(_ data: Data) -> Bool {
        guard data.count >= 4 else { return false }
        let b = data.prefix(4).map { $0 }
        let magic = UInt32(b[0]) | UInt32(b[1]) << 8 | UInt32(b[2]) << 16 | UInt32(b[3]) << 24
        return magic == frameMagic || magic & 0xFFFF_FFF0 == skippableMagic
    }

    /// Every frame in `data`, decompressed and joined.
    static func decompress(_ data: Data, maximumSize: Int = Int(Int32.max)) throws -> Data {
        let input = [UInt8](data)
        var out: [UInt8] = []
        try input.withUnsafeBufferPointer { src in
            var p = 0
            var frames = 0
            while p < src.count {
                guard p + 4 <= src.count else { throw Failure.truncated }
                let magic = UInt32(truncatingIfNeeded: le(src, p, 4))
                if magic == frameMagic {
                    p += 4
                    try frame(src, &p, &out, maximumSize)
                    frames += 1
                } else if magic & 0xFFFF_FFF0 == skippableMagic {
                    guard p + 8 <= src.count else { throw Failure.truncated }
                    let size = le(src, p + 4, 4)
                    guard size <= UInt64(src.count - p - 8) else { throw Failure.truncated }
                    p += 8 + Int(size)
                } else {
                    throw frames == 0 ? Failure.notZstd : Failure.corrupted("unknown data after a frame")
                }
            }
            guard frames > 0 else { throw Failure.notZstd }
        }
        return Data(out)
    }

    // MARK: - Frames and blocks

    private typealias Bytes = UnsafeBufferPointer<UInt8>

    private static let frameMagic: UInt32 = 0xFD2F_B528
    private static let skippableMagic: UInt32 = 0x184D_2A50
    private static let blockMaximum = 1 << 17

    /// What one block hands to the next inside a frame.
    private struct FrameState {
        var huffman: HuffmanTable?
        var literalLengths: FSETable?
        var offsets: FSETable?
        var matchLengths: FSETable?
        var repeats = (1, 4, 8)
    }

    /// `count` bytes at `at`, least significant first.
    private static func le(_ src: Bytes, _ at: Int, _ count: Int) -> UInt64 {
        var value: UInt64 = 0
        for k in 0..<count { value |= UInt64(src[at + k]) << UInt64(8 * k) }
        return value
    }

    /// Index of the highest set bit; `value` must not be zero.
    private static func highBit(_ value: Int) -> Int { Int.bitWidth - 1 - value.leadingZeroBitCount }

    private static func frame(_ src: Bytes, _ p: inout Int, _ out: inout [UInt8], _ maximum: Int) throws {
        guard p < src.count else { throw Failure.truncated }
        let descriptor = Int(src[p]); p += 1
        let sizeFlag = descriptor >> 6
        let singleSegment = descriptor & 0x20 != 0
        let hasChecksum = descriptor & 0x04 != 0
        guard descriptor & 0x08 == 0 else { throw Failure.corrupted("reserved header bit set") }
        if !singleSegment {
            guard p < src.count else { throw Failure.truncated }
            p += 1                                   // window descriptor: the output is kept whole anyway
        }
        let dictionaryBytes = [0, 1, 2, 4][descriptor & 3]
        guard p + dictionaryBytes <= src.count else { throw Failure.truncated }
        guard le(src, p, dictionaryBytes) == 0 else { throw Failure.unsupported("a dictionary is needed") }
        p += dictionaryBytes

        let sizeBytes = sizeFlag == 0 ? (singleSegment ? 1 : 0) : [0, 2, 4, 8][sizeFlag]
        guard p + sizeBytes <= src.count else { throw Failure.truncated }
        var contentSize: Int?
        if sizeBytes > 0 {
            let stated = le(src, p, sizeBytes) + (sizeBytes == 2 ? 256 : 0)
            guard stated <= UInt64(maximum - out.count) else { throw Failure.tooLarge }
            contentSize = Int(stated)
            out.reserveCapacity(out.count + Int(stated))
        }
        p += sizeBytes

        let frameStart = out.count
        var state = FrameState()
        while true {
            guard p + 3 <= src.count else { throw Failure.truncated }
            let header = Int(le(src, p, 3)); p += 3
            let isLast = header & 1 != 0
            let size = header >> 3
            switch (header >> 1) & 3 {
            case 0:
                guard p + size <= src.count else { throw Failure.truncated }
                guard size <= maximum - out.count else { throw Failure.tooLarge }
                out.append(contentsOf: UnsafeBufferPointer(rebasing: src[p..<p + size]))
                p += size
            case 1:
                guard p < src.count else { throw Failure.truncated }
                guard size <= maximum - out.count else { throw Failure.tooLarge }
                out.append(contentsOf: repeatElement(src[p], count: size))
                p += 1
            case 2:
                guard size <= blockMaximum else { throw Failure.corrupted("block larger than 128 KB") }
                guard p + size <= src.count else { throw Failure.truncated }
                try compressedBlock(src, p, p + size, &out, frameStart, &state, maximum)
                p += size
            default:
                throw Failure.corrupted("reserved block type")
            }
            if isLast { break }
        }
        if let contentSize, out.count - frameStart != contentSize {
            throw Failure.corrupted("frame is not the size its header gives")
        }
        if hasChecksum {
            guard p + 4 <= src.count else { throw Failure.truncated }
            let stored = UInt32(truncatingIfNeeded: le(src, p, 4))
            p += 4
            let computed = out.withUnsafeBufferPointer {
                xxHash64(UnsafeBufferPointer(rebasing: $0[frameStart...]))
            }
            guard UInt32(truncatingIfNeeded: computed) == stored else {
                throw Failure.corrupted("content does not match its checksum")
            }
        }
    }

    /// XXH64 with seed 0: a frame's checksum is its low 32 bits.
    private static func xxHash64(_ data: Bytes) -> UInt64 {
        let p1: UInt64 = 11400714785074694791, p2: UInt64 = 14029467366897019727
        let p3: UInt64 = 1609587929392839161, p4: UInt64 = 9650029242287828579
        let p5: UInt64 = 2870177450012600261
        func rotl(_ v: UInt64, _ r: UInt64) -> UInt64 { v << r | v >> (64 - r) }
        func word(_ at: Int, _ bytes: Int) -> UInt64 {
            var v: UInt64 = 0
            for k in 0..<bytes { v |= UInt64(data[at + k]) << UInt64(8 * k) }
            return v
        }
        func round(_ acc: UInt64, _ input: UInt64) -> UInt64 { rotl(acc &+ input &* p2, 31) &* p1 }

        var at = 0
        var hash: UInt64
        if data.count >= 32 {
            var v1 = p1 &+ p2, v2 = p2, v3: UInt64 = 0, v4 = 0 &- p1
            while at + 32 <= data.count {
                v1 = round(v1, word(at, 8)); v2 = round(v2, word(at + 8, 8))
                v3 = round(v3, word(at + 16, 8)); v4 = round(v4, word(at + 24, 8))
                at += 32
            }
            hash = rotl(v1, 1) &+ rotl(v2, 7) &+ rotl(v3, 12) &+ rotl(v4, 18)
            for v in [v1, v2, v3, v4] { hash = (hash ^ round(0, v)) &* p1 &+ p4 }
        } else {
            hash = p5
        }
        hash = hash &+ UInt64(data.count)
        while at + 8 <= data.count {
            hash = rotl(hash ^ round(0, word(at, 8)), 27) &* p1 &+ p4
            at += 8
        }
        if at + 4 <= data.count {
            hash = rotl(hash ^ word(at, 4) &* p1, 23) &* p2 &+ p3
            at += 4
        }
        while at < data.count {
            hash = rotl(hash ^ UInt64(data[at]) &* p5, 11) &* p1
            at += 1
        }
        hash ^= hash >> 33; hash = hash &* p2
        hash ^= hash >> 29; hash = hash &* p3
        hash ^= hash >> 32
        return hash
    }

    private static func compressedBlock(_ src: Bytes, _ start: Int, _ end: Int, _ out: inout [UInt8],
                                        _ frameStart: Int, _ state: inout FrameState, _ maximum: Int) throws {
        var p = start
        let literals = try literalsSection(src, &p, end, &state)
        try sequencesSection(src, p, end, literals, &out, frameStart, &state, maximum)
    }

    // MARK: - Literals

    private static func literalsSection(_ src: Bytes, _ p: inout Int, _ end: Int,
                                        _ state: inout FrameState) throws -> [UInt8] {
        guard p < end else { throw Failure.corrupted("empty block") }
        let first = Int(src[p])
        let type = first & 3, format = (first >> 2) & 3

        if type < 2 {                                // raw or RLE
            let headerBytes = format == 1 ? 2 : format == 3 ? 3 : 1
            guard p + headerBytes <= end else { throw Failure.corrupted("literals header cut short") }
            let size = headerBytes == 1 ? first >> 3 : Int(le(src, p, headerBytes) >> 4)
            p += headerBytes
            guard size <= blockMaximum else { throw Failure.corrupted("literals larger than a block") }
            if type == 0 {
                guard p + size <= end else { throw Failure.corrupted("raw literals cut short") }
                defer { p += size }
                return Array(UnsafeBufferPointer(rebasing: src[p..<p + size]))
            }
            guard p < end else { throw Failure.corrupted("RLE literal missing") }
            defer { p += 1 }
            return [UInt8](repeating: src[p], count: size)
        }

        // Huffman-coded, with its own table (2) or the previous block's (3).
        let headerBytes = format < 2 ? 3 : format == 2 ? 4 : 5
        let sizeBits = format < 2 ? 10 : format == 2 ? 14 : 18
        guard p + headerBytes <= end else { throw Failure.corrupted("literals header cut short") }
        let header = le(src, p, headerBytes)                 // up to 40 bits
        let sizeMask: UInt64 = (1 << UInt64(sizeBits)) - 1
        let regenerated = Int((header >> 4) & sizeMask)
        let compressed = Int((header >> UInt64(4 + sizeBits)) & sizeMask)
        let streams = format == 0 ? 1 : 4
        p += headerBytes
        guard regenerated <= blockMaximum else { throw Failure.corrupted("literals larger than a block") }
        guard p + compressed <= end else { throw Failure.corrupted("literals cut short") }
        var q = p
        let literalsEnd = p + compressed
        p = literalsEnd
        if type == 2 { state.huffman = try HuffmanTable(src, &q, literalsEnd) }
        guard let table = state.huffman else { throw Failure.corrupted("literals reuse a table that was never sent") }

        var literals: [UInt8] = []
        literals.reserveCapacity(regenerated)
        if streams == 1 {
            try table.decode(src, q, literalsEnd, count: regenerated, into: &literals)
        } else {
            guard literalsEnd - q >= 6 else { throw Failure.corrupted("literal stream sizes missing") }
            let s1 = Int(le(src, q, 2)), s2 = Int(le(src, q + 2, 2)), s3 = Int(le(src, q + 4, 2))
            q += 6
            let s4 = literalsEnd - q - s1 - s2 - s3
            guard s4 > 0 else { throw Failure.corrupted("literal streams overrun their section") }
            let each = (regenerated + 3) / 4
            guard regenerated >= 3 * each else { throw Failure.corrupted("too few literals for four streams") }
            try table.decode(src, q, q + s1, count: each, into: &literals)
            try table.decode(src, q + s1, q + s1 + s2, count: each, into: &literals)
            try table.decode(src, q + s1 + s2, q + s1 + s2 + s3, count: each, into: &literals)
            try table.decode(src, q + s1 + s2 + s3, literalsEnd, count: regenerated - 3 * each, into: &literals)
        }
        return literals
    }

    // MARK: - Sequences

    private static let literalLengthBase: [Int] = Array(0...15)
        + [16, 18, 20, 22, 24, 28, 32, 40, 48, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536]
    private static let literalLengthBits: [Int] = [Int](repeating: 0, count: 16)
        + [1, 1, 1, 1, 2, 2, 3, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
    private static let matchLengthBase: [Int] = Array(3...34)
        + [35, 37, 39, 41, 43, 47, 51, 59, 67, 83, 99, 131, 259, 515, 1027, 2051, 4099, 8195, 16387, 32771, 65539]
    private static let matchLengthBits: [Int] = [Int](repeating: 0, count: 32)
        + [1, 1, 1, 1, 2, 2, 3, 3, 4, 4, 5, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]

    private static let defaultLiteralLengths = FSETable(
        counts: [4, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 2, 1, 1, 1, 1, 1, -1, -1, -1, -1],
        log: 6)
    private static let defaultOffsets = FSETable(
        counts: [1, 1, 1, 1, 1, 1, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -1, -1, -1, -1, -1],
        log: 5)
    private static let defaultMatchLengths = FSETable(
        counts: [1, 4, 3, 2, 2, 2, 2, 2, 2] + [Int](repeating: 1, count: 37) + [-1, -1, -1, -1, -1, -1, -1],
        log: 6)

    private static func sequenceTable(mode: Int, _ src: Bytes, _ p: inout Int, _ end: Int, previous: FSETable?,
                                      standard: FSETable, maxLog: Int, maxSymbol: Int) throws -> FSETable {
        switch mode {
        case 0:
            return standard
        case 1:
            guard p < end else { throw Failure.corrupted("RLE table symbol missing") }
            defer { p += 1 }
            guard Int(src[p]) <= maxSymbol else { throw Failure.corrupted("RLE table symbol out of range") }
            return FSETable(single: src[p])
        case 2:
            return try FSETable(src, &p, end, maxLog: maxLog, maxSymbol: maxSymbol)
        default:
            guard let previous else { throw Failure.corrupted("sequences reuse a table that was never sent") }
            return previous
        }
    }

    private static func sequencesSection(_ src: Bytes, _ start: Int, _ end: Int, _ literals: [UInt8],
                                         _ out: inout [UInt8], _ frameStart: Int, _ state: inout FrameState,
                                         _ maximum: Int) throws {
        var p = start
        guard p < end else { throw Failure.corrupted("sequences section missing") }
        let first = Int(src[p]); p += 1
        var count = first
        if first >= 128 {
            if first < 255 {
                guard p < end else { throw Failure.corrupted("sequence count cut short") }
                count = ((first - 128) << 8) + Int(src[p]); p += 1
            } else {
                guard p + 2 <= end else { throw Failure.corrupted("sequence count cut short") }
                count = Int(le(src, p, 2)) + 0x7F00; p += 2
            }
        }
        if count == 0 {
            guard p == end else { throw Failure.corrupted("data after an empty sequences section") }
            guard literals.count <= maximum - out.count else { throw Failure.tooLarge }
            out.append(contentsOf: literals)
            return
        }

        guard p < end else { throw Failure.corrupted("sequence modes missing") }
        let modes = Int(src[p]); p += 1
        guard modes & 3 == 0 else { throw Failure.corrupted("reserved sequence mode bits set") }
        let lengths = try sequenceTable(mode: modes >> 6, src, &p, end, previous: state.literalLengths,
                                        standard: defaultLiteralLengths, maxLog: 9, maxSymbol: 35)
        let offsets = try sequenceTable(mode: (modes >> 4) & 3, src, &p, end, previous: state.offsets,
                                        standard: defaultOffsets, maxLog: 8, maxSymbol: 31)
        let matches = try sequenceTable(mode: (modes >> 2) & 3, src, &p, end, previous: state.matchLengths,
                                        standard: defaultMatchLengths, maxLog: 9, maxSymbol: 52)
        state.literalLengths = lengths
        state.offsets = offsets
        state.matchLengths = matches

        var bits = try BackwardBits(src, p, end)
        var lengthState = bits.read(lengths.log)
        var offsetState = bits.read(offsets.log)
        var matchState = bits.read(matches.log)
        var literalAt = 0
        var repeats = state.repeats

        for index in 0..<count {
            let offsetCode = Int(offsets.symbol[offsetState])
            let lengthCode = Int(lengths.symbol[lengthState])
            let matchCode = Int(matches.symbol[matchState])
            guard offsetCode <= 31, lengthCode <= 35, matchCode <= 52 else {
                throw Failure.corrupted("sequence code out of range")
            }
            // Up to 2^32: wider than an `Int` where that is 32 bits.
            let offsetValue = (UInt64(1) << UInt64(offsetCode)) + bits.readWide(offsetCode)
            let matchLength = matchLengthBase[matchCode] + bits.read(matchLengthBits[matchCode])
            let literalLength = literalLengthBase[lengthCode] + bits.read(literalLengthBits[lengthCode])

            let offset: Int
            if offsetValue > 3 {
                // Further back than anything written is damage, whatever the size.
                guard offsetValue - 3 <= UInt64(out.count - frameStart) + UInt64(literalLength) else {
                    throw Failure.corrupted("a match reaches before the start of the frame")
                }
                offset = Int(offsetValue - 3)
                repeats = (offset, repeats.0, repeats.1)
            } else {
                // A repeat of one of the last three offsets; with no
                // literals before it the three choices shift by one.
                let choice = Int(offsetValue) - 1 + (literalLength == 0 ? 1 : 0)
                switch choice {
                case 0:
                    offset = repeats.0
                case 1:
                    offset = repeats.1
                    repeats = (offset, repeats.0, repeats.2)
                case 2:
                    offset = repeats.2
                    repeats = (offset, repeats.0, repeats.1)
                default:
                    offset = repeats.0 - 1
                    guard offset > 0 else { throw Failure.corrupted("repeat offset of zero") }
                    repeats = (offset, repeats.0, repeats.1)
                }
            }

            if index + 1 < count {
                lengthState = Int(lengths.base[lengthState]) + bits.read(Int(lengths.bits[lengthState]))
                matchState = Int(matches.base[matchState]) + bits.read(Int(matches.bits[matchState]))
                offsetState = Int(offsets.base[offsetState]) + bits.read(Int(offsets.bits[offsetState]))
            }
            guard bits.remaining >= 0 else { throw Failure.corrupted("sequences read past their data") }

            guard literalLength <= literals.count - literalAt else {
                throw Failure.corrupted("a sequence asks for more literals than the block has")
            }
            guard literalLength + matchLength <= maximum - out.count else { throw Failure.tooLarge }
            literals.withUnsafeBufferPointer {
                out.append(contentsOf: UnsafeBufferPointer(rebasing: $0[literalAt..<literalAt + literalLength]))
            }
            literalAt += literalLength
            guard offset <= out.count - frameStart else {
                throw Failure.corrupted("a match reaches before the start of the frame")
            }
            // Byte by byte: a match may overlap what it is writing (that is
            // how a run is encoded), and a slice of `out` cannot be appended
            // to `out` without copying the whole array.
            var from = out.count - offset
            for _ in 0..<matchLength {
                out.append(out[from])
                from += 1
            }
        }
        guard bits.remaining == 0 else { throw Failure.corrupted("sequences left data unread") }
        state.repeats = repeats
        guard literals.count - literalAt <= maximum - out.count else { throw Failure.tooLarge }
        literals.withUnsafeBufferPointer {
            out.append(contentsOf: UnsafeBufferPointer(rebasing: $0[literalAt...]))
        }
    }

    // MARK: - Bit readers

    /// A stream read from its last byte towards its first. The highest set
    /// bit of the last byte marks the end and is not data. Reading past the
    /// first byte gives zeros and leaves `remaining` negative.
    private struct BackwardBits {
        let src: Bytes
        let start: Int
        let byteCount: Int
        var remaining: Int

        init(_ src: Bytes, _ start: Int, _ end: Int) throws {
            guard end > start, src[end - 1] != 0 else { throw Failure.corrupted("bit stream has no end mark") }
            self.src = src
            self.start = start
            byteCount = end - start
            remaining = (byteCount - 1) * 8 + ZstdDecoder.highBit(Int(src[end - 1]))
        }

        /// At most 16 bits: a table state, or a length's extra bits.
        mutating func read(_ count: Int) -> Int {
            remaining -= count
            return Int(bits(at: remaining, count))
        }

        /// At most 32 bits: an offset's extra bits.
        mutating func readWide(_ count: Int) -> UInt64 {
            remaining -= count
            return bits(at: remaining, count)
        }

        func peek(_ count: Int) -> Int { Int(bits(at: remaining - count, count)) }

        mutating func skip(_ count: Int) { remaining -= count }

        /// Bits `[bit, bit + count)` of the stream, `count` at most 32.
        private func bits(at bit: Int, _ count: Int) -> UInt64 {
            var bit = bit, count = count, missing = 0
            if bit < 0 {
                missing = min(-bit, count)
                count -= missing
                bit = 0
            }
            guard count > 0 else { return 0 }
            let byte = bit >> 3
            var value: UInt64 = 0
            for k in 0..<min(8, byteCount - byte) { value |= UInt64(src[start + byte + k]) << UInt64(8 * k) }
            value >>= UInt64(bit & 7)
            return (value & ((1 << UInt64(count)) - 1)) << UInt64(missing)
        }
    }

    /// A stream read from its first byte, low bits first (table descriptions).
    private struct ForwardBits {
        let src: Bytes
        let start: Int
        let end: Int
        var used = 0

        func peek(_ count: Int) throws -> Int {
            let byte = start + used >> 3
            guard start + (used + count + 7) >> 3 <= end else { throw Failure.corrupted("table description cut short") }
            var value: UInt64 = 0
            for k in 0..<min(8, end - byte) { value |= UInt64(src[byte + k]) << UInt64(8 * k) }
            value >>= UInt64(used & 7)
            return Int(value & ((1 << UInt64(count)) - 1))
        }

        mutating func read(_ count: Int) throws -> Int {
            defer { used += count }
            return try peek(count)
        }
    }

    // MARK: - FSE

    private struct FSETable {
        let log: Int
        var symbol: [UInt8]
        var bits: [UInt8]
        var base: [UInt16]

        /// One symbol, always (the RLE mode): a state that never moves.
        init(single: UInt8) {
            log = 0
            symbol = [single]
            bits = [0]
            base = [0]
        }

        /// From a table description at `p`, which is moved past it.
        init(_ src: Bytes, _ p: inout Int, _ end: Int, maxLog: Int, maxSymbol: Int) throws {
            var reader = ForwardBits(src: src, start: p, end: end)
            let log = try reader.read(4) + 5
            guard log <= maxLog else { throw Failure.corrupted("table accuracy too high") }
            var remaining = (1 << log) + 1
            var threshold = 1 << log
            var width = log + 1
            var counts: [Int] = []
            var afterZero = false
            while remaining > 1, counts.count <= maxSymbol {
                if afterZero {
                    // Runs of unused symbols: two bits at a time, 3 means more.
                    while true {
                        let run = try reader.read(2)
                        counts.append(contentsOf: repeatElement(0, count: run))
                        if run != 3 { break }
                        guard counts.count <= maxSymbol + 1 else { throw Failure.corrupted("table has too many symbols") }
                    }
                    guard counts.count <= maxSymbol else { throw Failure.corrupted("table has too many symbols") }
                }
                let limit = (2 * threshold - 1) - remaining
                var count = try reader.peek(width - 1)
                if count < limit {
                    reader.used += width - 1
                } else {
                    count = try reader.read(width)
                    if count >= threshold { count -= limit }
                }
                count -= 1                               // 0 codes "less than one": -1
                remaining -= abs(count)
                counts.append(count)
                afterZero = count == 0
                while remaining < threshold, threshold > 1 {
                    width -= 1
                    threshold >>= 1
                }
            }
            guard remaining == 1, counts.count <= maxSymbol + 1 else {
                throw Failure.corrupted("table probabilities do not add up")
            }
            p += (reader.used + 7) >> 3
            self.init(counts: counts, log: log)
        }

        /// From each symbol's share of `1 << log` states; -1 is a symbol
        /// given a single state at the top of the table.
        init(counts: [Int], log: Int) {
            self.log = log
            let size = 1 << log
            symbol = [UInt8](repeating: 0, count: size)
            bits = [UInt8](repeating: 0, count: size)
            base = [UInt16](repeating: 0, count: size)
            var next = [Int](repeating: 0, count: counts.count)
            var high = size - 1
            for (value, count) in counts.enumerated() {
                if count == -1 {
                    symbol[high] = UInt8(value)
                    high -= 1
                    next[value] = 1
                } else {
                    next[value] = count
                }
            }
            let step = (size >> 1) + (size >> 3) + 3
            var position = 0
            for (value, count) in counts.enumerated() where count > 0 {
                for _ in 0..<count {
                    symbol[position] = UInt8(value)
                    repeat { position = (position + step) & (size - 1) } while position > high
                }
            }
            for state in 0..<size {
                let value = Int(symbol[state])
                let nextState = next[value]
                next[value] += 1
                let width = log - ZstdDecoder.highBit(max(nextState, 1))
                bits[state] = UInt8(width)
                base[state] = UInt16(truncatingIfNeeded: (nextState << width) - size)
            }
        }
    }

    // MARK: - Huffman

    private struct HuffmanTable {
        let maxBits: Int
        var symbol: [UInt8]
        var length: [UInt8]

        /// From a tree description at `p`, which is moved past it.
        init(_ src: Bytes, _ p: inout Int, _ end: Int) throws {
            guard p < end else { throw Failure.corrupted("Huffman table missing") }
            let header = Int(src[p]); p += 1
            var weights: [Int] = []
            if header >= 128 {
                // Four bits a weight, written out.
                let count = header - 127
                let bytes = (count + 1) / 2
                guard p + bytes <= end else { throw Failure.corrupted("Huffman weights cut short") }
                for index in 0..<count {
                    let byte = Int(src[p + index / 2])
                    weights.append(index % 2 == 0 ? byte >> 4 : byte & 15)
                }
                p += bytes
            } else {
                // The weights, FSE-coded on two interleaved states.
                guard header > 0, p + header <= end else { throw Failure.corrupted("Huffman weights cut short") }
                var q = p
                let table = try FSETable(src, &q, p + header, maxLog: 6, maxSymbol: 255)
                var bits = try BackwardBits(src, q, p + header)
                var one = bits.read(table.log), two = bits.read(table.log)
                while true {
                    guard weights.count < 255 else { throw Failure.corrupted("too many Huffman weights") }
                    weights.append(Int(table.symbol[one]))
                    one = Int(table.base[one]) + bits.read(Int(table.bits[one]))
                    if bits.remaining < 0 { weights.append(Int(table.symbol[two])); break }
                    weights.append(Int(table.symbol[two]))
                    two = Int(table.base[two]) + bits.read(Int(table.bits[two]))
                    if bits.remaining < 0 { weights.append(Int(table.symbol[one])); break }
                }
                p += header
            }

            // The last symbol's weight is whatever completes a power of two.
            var total = 0
            for weight in weights {
                guard weight <= 11 else { throw Failure.corrupted("Huffman weight out of range") }
                if weight > 0 { total += 1 << (weight - 1) }
            }
            guard total > 0 else { throw Failure.corrupted("Huffman table is empty") }
            let maxBits = ZstdDecoder.highBit(total) + 1
            guard maxBits <= 11 else { throw Failure.corrupted("Huffman codes too long") }
            let rest = (1 << maxBits) - total
            guard rest & (rest - 1) == 0 else { throw Failure.corrupted("Huffman weights do not add up") }
            weights.append(ZstdDecoder.highBit(rest) + 1)
            guard weights.count <= 256 else { throw Failure.corrupted("too many Huffman symbols") }

            self.maxBits = maxBits
            symbol = [UInt8](repeating: 0, count: 1 << maxBits)
            length = [UInt8](repeating: 0, count: 1 << maxBits)
            // Longest codes first (weight 1), symbols in order within a
            // weight; a symbol of weight w fills 2^(w-1) entries.
            var position = 0
            for weight in 1...maxBits {
                for (value, w) in weights.enumerated() where w == weight {
                    let span = 1 << (weight - 1)
                    for entry in position..<position + span {
                        symbol[entry] = UInt8(value)
                        length[entry] = UInt8(maxBits + 1 - weight)
                    }
                    position += span
                }
            }
        }

        func decode(_ src: Bytes, _ start: Int, _ end: Int, count: Int, into out: inout [UInt8]) throws {
            var bits = try BackwardBits(src, start, end)
            for _ in 0..<count {
                let entry = bits.peek(maxBits)
                out.append(symbol[entry])
                bits.skip(Int(length[entry]))
            }
            guard bits.remaining == 0 else { throw Failure.corrupted("literal stream is the wrong length") }
        }
    }
}
