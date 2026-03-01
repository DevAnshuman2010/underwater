import SwiftUI
import AVFoundation

enum SendMode: String, CaseIterable {
    case fiveBit = "5-Bit"
    case dictionary = "Dictionary"
}

struct SendView: View {
    @State private var selectedMode: SendMode = .fiveBit
    @State private var message: String = ""
    @State private var frameAlert: String = ""
    @State private var showFrameAlert = false
    var body: some View {
        VStack(spacing: 25) {

            Text("Send Message")
                .font(.title)
                .fontWeight(.bold)

            Picker("Mode", selection: $selectedMode) {
                ForEach(SendMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            TextField("Enter message", text: $message)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            Button(action: sendMessage) {
                Text("Send")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top, 40)
        .alert("Frame Bits", isPresented: $showFrameAlert) {
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(frameAlert)
        }
    }

    func sendMessage() {
        switch selectedMode {
        case .fiveBit:
            sendFiveBit(message)
        case .dictionary:
            sendDictionary(message)
        }
    }

    func sendFiveBit(_ text: String) {
        do {
            let binaryString = try FrameBuilder.buildFrame(for: text)
            print("5-Bit Mode → Frame:", binaryString)
            frameAlert = binaryString
            showFrameAlert = true
            transmitBits(binaryString)
        } catch {
            print("Encoding error:", error.localizedDescription)
        }
    }

    func sendDictionary(_ text: String) {
        print("Dictionary Mode →", text)
    }

    func transmitBits(_ bits: String) {

        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else {
            print("Torch unavailable")
            return
        }

        let HIGH: Float = 1.0
        let LOW: Float  = 0.001

        let halfBitInterval = 0.5
        var encodedLevels: [Float] = [HIGH, HIGH]

        for bit in bits {
            if bit == "1" {
                encodedLevels.append(LOW)
                encodedLevels.append(HIGH)
            } else {
                encodedLevels.append(HIGH)
                encodedLevels.append(LOW)
            }
        }

        var index = 0

        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInitiated))
        timer.schedule(deadline: .now(), repeating: halfBitInterval)

        timer.setEventHandler {
            do {
                try device.lockForConfiguration()

                if index < encodedLevels.count {
                    try device.setTorchModeOn(level: encodedLevels[index])
                    index += 1
                } else {
                    device.torchMode = .off
                    device.unlockForConfiguration()
                    timer.cancel()
                }

            } catch {
                print("Torch error:", error)
            }
        }

        timer.resume()
    }
}

#Preview {
    SendView()
}
