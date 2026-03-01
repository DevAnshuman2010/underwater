import SwiftUI
import AVFoundation
struct ReceiveView: View {

    @State private var decodedMessage: String = ""
    @State private var status:         String = "Tap Start to begin"
    @State private var rawBits:        String = ""
    @State private var isListening:    Bool   = false

    private let decoder = ManchesterDecoder()

    var body: some View {
        VStack(spacing: 20) {

            Text("Receive Mode")
                .font(.title)
                .fontWeight(.bold)

            CameraView(brightnessHandler: { brightness in
                if isListening {
                    decoder.feedBrightness(brightness)
                }
            })
            .frame(height: 220)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isListening ? Color.green : Color.gray, lineWidth: 2)
            )

            Text(status)
                .foregroundColor(.secondary)
                .font(.subheadline)

            ScrollView(.horizontal, showsIndicators: false) {
                Text(rawBits.isEmpty ? "—" : rawBits)
                    .font(.system(.caption2, design: .monospaced))
                    .padding(.horizontal)
            }
            .frame(height: 24)

            Text(decodedMessage.isEmpty ? "Waiting for message…" : decodedMessage)
                .font(.title2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 80)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)

            Button(action: toggleListening) {
                Text(isListening ? "Stop" : "Start Listening")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isListening ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 40)
        .onAppear(perform: wireDecoder)
    }

    private func wireDecoder() {
        decoder.onStatusChanged  = { msg  in status       = msg }
        decoder.onBitsUpdated    = { bits in rawBits      = bits.map(String.init).joined() }
        decoder.onMessageDecoded = { msg  in decodedMessage = msg }
    }

    private func toggleListening() {
        if isListening {
            decoder.stop()
            status = "Stopped."
        } else {
            decodedMessage = ""
            rawBits        = ""
            decoder.start()
        }
        isListening.toggle()
    }
}
