#include <iostream>
#include <string>
#include <vector>

// Include your header files
#include "fivebits.h"
#include "interleaver.h"
#include "frame_builder.h"

int main() {
    std::string userInput;
    
    std::cout << "=== Flashlight Binary Communication System ===" << std::endl;
    std::cout << "Enter text to send: ";
    std::getline(std::cin, userInput);

    try {
        // --- TRANSMISSION SIDE ---
        std::cout << "\n--- STEP 1: Encoding (5-bit) ---" << std::endl;
        std::vector<bool> encodedVec = encodeFiveBit(userInput);
        std::string encodedStr = vectorToBitString(encodedVec);
        std::cout << "Encoded Bits: " << encodedStr << std::endl;

        std::cout << "\n--- STEP 2: Interleaving (Depth 16) ---" << std::endl;
        InterleaveResult intResult = interleave(encodedVec);
        std::string interleavedStr = vectorToBitString(intResult.bits);
        std::cout << "Interleaved Bits: " << interleavedStr << std::endl;
        std::cout << "Padding Added:    " << intResult.paddingBits << " bits" << std::endl;

        std::cout << "\n--- STEP 3: Building Full Frame ---" << std::endl;
        std::string finalFrame = buildFrame(userInput);
        std::cout << "PREAMBLE:  " << PREAMBLE << std::endl;
        std::cout << "SYNC:      " << SYNC << std::endl;
        std::cout << "PAYLOAD:   " << interleavedStr << std::endl;
        // Checksum is the last 8 bits of the frame
        std::cout << "CHECKSUM:  " << finalFrame.substr(finalFrame.length() - 8) << std::endl;
        std::cout << "\nFINAL FRAME TO SEND:\n" << finalFrame << std::endl;

        // --- RECEIVING SIDE (Simulation) ---
        std::cout << "\n--- STEP 4: Receiving & Decoding ---" << std::endl;
        
        // 1. Extract payload (everything between SYNC and CHECKSUM)
        size_t payloadStart = PREAMBLE.length() + SYNC.length();
        size_t payloadLength = finalFrame.length() - payloadStart - 8; // subtract 8 for checksum
        std::string receivedPayloadStr = finalFrame.substr(payloadStart, payloadLength);
        
        // 2. Convert string back to vector<bool> for deinterleaver
        std::vector<bool> receivedVec;
        for(char c : receivedPayloadStr) receivedVec.push_back(c == '1');

        // 3. Deinterleave
        std::vector<bool> deinterleavedVec = deinterleave(receivedVec, intResult.paddingBits);
        std::cout << "Deinterleaved Bits: " << vectorToBitString(deinterleavedVec) << std::endl;

        // 4. Decode 5-bit back to Text
        std::string decodedText = decodeFiveBit(deinterleavedVec);
        
        std::cout << "\n--- RESULT ---" << std::endl;
        std::cout << "Original Input: " << userInput << std::endl;
        std::cout << "Decoded Output: " << decodedText << std::endl;

        if (userInput == decodedText) {
            std::cout << "\nSUCCESS: Data integrity maintained!" << std::endl;
        } else {
            std::cout << "\nERROR: Mismatch detected." << std::endl;
        }

    } catch (const std::exception& e) {
        std::cerr << "System Error: " << e.what() << std::endl;
    }

    return 0;
}