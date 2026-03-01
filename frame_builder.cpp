#include <string>
#include <vector>
#include "fivebits.h"
#include "interleaver.h"

// Protocol Constants
// Defined with extern linkage to match the extern declarations in frame_builder.h
extern const std::string PREAMBLE = "1010101010101010";
extern const std::string SYNC     = "1110001110001110";

/**
 * HELPER: Converts std::vector<bool> to a std::string of '0's and '1's
 * This bridges your encoder/interleaver logic with the string-based frame.
 */
std::string vectorToBitString(const std::vector<bool>& bits) {
    std::string out;
    out.reserve(bits.size());
    for (bool b : bits) {
        out += (b ? '1' : '0');
    }
    return out;
}

// Converts an integer to a binary string of a specified bit length
std::string toBinary(int value, int bits) {
    std::string result = "";
    for (int i = bits - 1; i >= 0; --i) {
        result += ((value >> i) & 1) ? '1' : '0';
    }
    return result;
}

// Computes an 8-bit XOR checksum of the given binary string
std::string computeChecksum(const std::string& bits) {
    int checksum = 0;
    
    // Process the bit string in 8-bit chunks
    for (size_t i = 0; i < bits.length(); i += 8) {
        std::string block = bits.substr(i, 8);
        
        // Pad the final block with trailing '0's if it's not exactly 8 bits
        while (block.length() < 8) {
            block += '0';
        }
        
        // Convert the 8-bit string block to an integer
        int blockValue = 0;
        for (char c : block) {
            blockValue = (blockValue << 1) + (c == '1' ? 1 : 0);
        }
        
        checksum ^= blockValue;
    }
    
    return toBinary(checksum, 8);
}

// Builds the complete transmission frame
std::string buildFrame(const std::string& message) {
    // 1. Encode message to vector of bits
    std::vector<bool> encodedVec = encodeFiveBit(message);
    
    // 2. Interleave the bits
    // Note: interleave returns an InterleaveResult struct
    InterleaveResult result = interleave(encodedVec);
    
    // 3. Convert the interleaved vector to a string of '0's and '1's
    std::string payload = vectorToBitString(result.bits);
    
    // 4. Compute the 8-bit XOR checksum of the bit string
    std::string checksum = computeChecksum(payload);
    
    // 5. Assemble: [PREAMBLE][SYNC][PAYLOAD][CHECKSUM]
    return PREAMBLE + SYNC + payload + checksum;
}