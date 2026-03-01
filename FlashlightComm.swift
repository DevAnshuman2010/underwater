
import Foundation

public enum FlashlightCommError: Error, LocalizedError {
    case unsupportedCharacter(Character)
    case invalidBitPattern(UInt8)
    case bitStreamNotMultipleOfFive
    case inputSizeNotDivisibleBy16
    case paddingBitsExceedStreamSize

    public var errorDescription: String? {
        switch self {
        case .unsupportedCharacter(let c):
            return "Unsupported character in text: '\(c)'"
        case .invalidBitPattern(let v):
            return "Invalid bit pattern (value out of range): \(v)"
        case .bitStreamNotMultipleOfFive:
            return "Bit stream length is not a multiple of 5"
        case .inputSizeNotDivisibleBy16:
            return "Input size must be divisible by 16"
        case .paddingBitsExceedStreamSize:
            return "Padding bits cannot be larger than the bitstream size"
        }
    }
}


public enum FiveBits {

    public static func encode(_ text: String) throws -> [Bool] {
        var bits = [Bool]()
        bits.reserveCapacity(text.count * 5)
        for char in text {
            let val = try charToValue(char)
            for i in stride(from: 4, through: 0, by: -1) {
                bits.append((val >> i) & 1 == 1)
            }
        }
        return bits
    }

    public static func decode(_ bits: [Bool]) throws -> String {
        guard bits.count % 5 == 0 else {
            throw FlashlightCommError.bitStreamNotMultipleOfFive
        }
        var text = ""
        text.reserveCapacity(bits.count / 5)
        var i = 0
        while i < bits.count {
            var val: UInt8 = 0
            for j in 0..<5 {
                val = (val << 1) | (bits[i + j] ? 1 : 0)
            }
            text.append(try valueToChar(val))
            i += 5
        }
        return text
    }

    private static func charToValue(_ c: Character) throws -> UInt8 {
        let lower = Character(c.lowercased())
        if lower == " "  { return 0 }
        if lower == "."  { return 27 }
        if lower == ","  { return 28 }
        if lower == "?"  { return 29 }
        if lower == "!"  { return 30 }
        if lower == "\n" { return 31 }
        let scalars = lower.unicodeScalars
        if let first = scalars.first,
           first.value >= 97 && first.value <= 122 {
            return UInt8(first.value - 97 + 1)
        }
        throw FlashlightCommError.unsupportedCharacter(c)
    }

    private static func valueToChar(_ val: UInt8) throws -> Character {
        switch val {
        case 0:       return " "
        case 1...26:  return Character(UnicodeScalar(UInt32("a".unicodeScalars.first!.value) + UInt32(val) - 1)!)
        case 27:      return "."
        case 28:      return ","
        case 29:      return "?"
        case 30:      return "!"
        case 31:      return "\n"
        default:      throw FlashlightCommError.invalidBitPattern(val)
        }
    }
}


public enum Interleaver {

    public static let depth: Int = 16

    public struct InterleaveResult {
        public let bits: [Bool]
        public let paddingBits: Int
    }

    public static func interleave(_ bits: [Bool]) -> InterleaveResult {
        guard !bits.isEmpty else { return InterleaveResult(bits: [], paddingBits: 0) }
        let origSize    = bits.count
        let paddingBits = (depth - (origSize % depth)) % depth
        let paddedSize  = origSize + paddingBits
        let cols        = paddedSize / depth
        var result = [Bool]()
        result.reserveCapacity(paddedSize)
        for c in 0..<cols {
            for r in 0..<depth {
                let idx = r * cols + c
                result.append(idx < origSize ? bits[idx] : false)
            }
        }
        return InterleaveResult(bits: result, paddingBits: paddingBits)
    }

    public static func deinterleave(_ bits: [Bool], paddingBits: Int) throws -> [Bool] {
        guard bits.count % depth == 0 else {
            throw FlashlightCommError.inputSizeNotDivisibleBy16
        }
        guard paddingBits <= bits.count else {
            throw FlashlightCommError.paddingBitsExceedStreamSize
        }
        guard !bits.isEmpty else { return [] }
        let paddedSize = bits.count
        let cols       = paddedSize / depth
        let origSize   = paddedSize - paddingBits
        var result = [Bool]()
        result.reserveCapacity(origSize)
        for i in 0..<origSize {
            let r     = i / cols
            let c     = i % cols
            let inIdx = c * depth + r
            result.append(bits[inIdx])
        }
        return result
    }
}


public enum FrameBuilder {

    
    public static let preamble = "10101010"


    public static func buildFrame(for message: String) throws -> String {
        let encodedVec = try FiveBits.encode(message)
        let intResult  = Interleaver.interleave(encodedVec)
        let payload    = bitsToString(intResult.bits)
        let checksum   = computeChecksum(of: payload)
        return preamble + payload + checksum
    }

    public static func extractPayload(from frame: String) -> String {
        let headerLen  = preamble.count
        let payloadLen = frame.count - headerLen - 8
        guard payloadLen > 0 else { return "" }
        let start = frame.index(frame.startIndex, offsetBy: headerLen)
        let end   = frame.index(start, offsetBy: payloadLen)
        return String(frame[start..<end])
    }

    public static func decodePayload(_ payloadStr: String, paddingBits: Int) throws -> String {
        let bits          = stringToBits(payloadStr)
        let deinterleaved = try Interleaver.deinterleave(bits, paddingBits: paddingBits)
        return try FiveBits.decode(deinterleaved)
    }

    public static func bitsToString(_ bits: [Bool]) -> String {
        bits.map { $0 ? "1" : "0" }.joined()
    }

    public static func stringToBits(_ s: String) -> [Bool] {
        s.map { $0 == "1" }
    }

    public static func toBinary(_ value: Int, bits: Int) -> String {
        var result = ""
        for i in stride(from: bits - 1, through: 0, by: -1) {
            result += ((value >> i) & 1) == 1 ? "1" : "0"
        }
        return result
    }

    public static func computeChecksum(of bitString: String) -> String {
        var checksum = 0
        let chars = Array(bitString)
        var i = 0
        while i < chars.count {
            var block = String(chars[i..<min(i + 8, chars.count)])
            while block.count < 8 { block += "0" }
            let blockValue = block.reduce(0) { ($0 << 1) + ($1 == "1" ? 1 : 0) }
            checksum ^= blockValue
            i += 8
        }
        return toBinary(checksum, bits: 8)
    }
}
