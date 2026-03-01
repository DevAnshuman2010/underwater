import Foundation

class ManchesterDecoder {

    private let halfBitInterval: TimeInterval = 0.5

    private var latestBrightness: Float = 0
    private var halfPeriodSamples: [Bool] = []

    private var timer: DispatchSourceTimer?

    private var minBrightness: Float = 1.0
    private var maxBrightness: Float = 0.0
    private var calibrationSamples = 0
    private let calibrationCount   = 6

    var onStatusChanged:  ((String) -> Void)?
    var onBitsUpdated:    (([Int])  -> Void)?
    var onMessageDecoded: ((String) -> Void)?

    func start() {
        halfPeriodSamples.removeAll()
        minBrightness      = 1.0
        maxBrightness      = 0.0
        calibrationSamples = 0
        onStatusChanged?("Calibrating")

        let t = DispatchSource.makeTimerSource(queue: .global(qos: .userInitiated))
        t.schedule(deadline: .now() + halfBitInterval, repeating: halfBitInterval)
        t.setEventHandler { [weak self] in self?.tick() }
        t.resume()
        timer = t
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    func feedBrightness(_ brightness: Float) {
        latestBrightness = brightness
    }

    private var threshold: Float {
        guard maxBrightness > minBrightness + 0.05 else { return 0.35 }
        return (minBrightness + maxBrightness) / 2.0
    }

    private func tick() {
        let b = latestBrightness
        minBrightness = min(minBrightness, b)
        maxBrightness = max(maxBrightness, b)

        if calibrationSamples < calibrationCount {
            calibrationSamples += 1
            if calibrationSamples == calibrationCount {
                DispatchQueue.main.async {
                    self.onStatusChanged?(
                        "Listening threshold = \(String(format: "%.2f", self.threshold))"
                    )
                }
            }
            return
        }

        halfPeriodSamples.append(b > threshold)

        guard halfPeriodSamples.count % 2 == 0 else { return }

        for offset in 0...1 {
            let bits = manchesterDecode(offset: offset)
            DispatchQueue.main.async { self.onBitsUpdated?(bits.map { $0 ? 1 : 0 }) }

            if let message = tryFindFrame(in: bits) {
                DispatchQueue.main.async {
                    self.onMessageDecoded?(message)
                    self.onStatusChanged?("Frame received!")
                    self.halfPeriodSamples.removeAll()
                }
                return
            }
        }
    }

    private func manchesterDecode(offset: Int) -> [Bool] {
        var bits = [Bool]()
        bits.reserveCapacity(halfPeriodSamples.count / 2)
        var i = offset
        while i + 1 < halfPeriodSamples.count {
            let first  = halfPeriodSamples[i]
            let second = halfPeriodSamples[i + 1]
            switch (first, second) {
            case (false, true):  bits.append(true)
            case (true,  false): bits.append(false)
            default: break
            }
            i += 2
        }
        return bits
    }

    private func tryFindFrame(in bits: [Bool]) -> String? {
        let bitStr  = String(bits.map { $0 ? "1" : "0" })
        let preamble = FrameBuilder.preamble 

        guard let preambleRange = bitStr.range(of: preamble) else { return nil }

        let afterPreamble = String(bitStr[preambleRange.upperBound...])

        var payloadLen = Interleaver.depth
        while payloadLen + 8 <= afterPreamble.count {
            let payloadBits  = String(afterPreamble.prefix(payloadLen))
            let checksumBits = String(afterPreamble.dropFirst(payloadLen).prefix(8))
            guard checksumBits.count == 8 else { payloadLen += Interleaver.depth; continue }

            let expected = FrameBuilder.computeChecksum(of: payloadBits)
            if expected == checksumBits {
                return decodePayload(payloadBits)
            }
            payloadLen += Interleaver.depth
        }
        return nil
    }

    private func decodePayload(_ payloadStr: String) -> String? {
        let paddedSize = payloadStr.count
        guard let paddingBits = (0...15).first(where: { (paddedSize - $0) % 5 == 0 }) else {
            return nil
        }
        do {
            return try FrameBuilder.decodePayload(payloadStr, paddingBits: paddingBits)
        } catch {
            print("Decode error:", error.localizedDescription)
            return nil
        }
    }
}
