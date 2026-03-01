#include "fivebits.h"
#include <vector>
#include <string>
#include <stdexcept>
#include <cctype>
#include <cstdint>

namespace {

    uint8_t charToValue(char c) {
        unsigned char uc = std::tolower(static_cast<unsigned char>(c));
        
        if (uc == ' ') return 0;
        if (uc >= 'a' && uc <= 'z') return (uc - 'a') + 1;
        
        switch (uc) {
            case '.': return 27;
            case ',': return 28;
            case '?': return 29;
            case '!': return 30;
            case '\n': return 31;
            default: throw std::runtime_error("Unsupported character in text");
        }
    }

    char valueToChar(uint8_t val) {
        if (val == 0) return ' ';
        if (val >= 1 && val <= 26) return static_cast<char>('a' + (val - 1));
        
        switch (val) {
            case 27: return '.';
            case 28: return ',';
            case 29: return '?';
            case 30: return '!';
            case 31: return '\n';
            default: throw std::runtime_error("Invalid bit pattern (value out of range)");
        }
    }

} // anonymous namespace

std::vector<bool> encodeFiveBit(const std::string& text) {
    std::vector<bool> bits;
    bits.reserve(text.size() * 5);

    for (char c : text) {
        uint8_t val = charToValue(c);
        
        // Extract 5 bits, MSB first
        for (int i = 4; i >= 0; --i) {
            bits.push_back((val >> i) & 1);
        }
    }

    return bits;
}

std::string decodeFiveBit(const std::vector<bool>& bits) {
    if (bits.size() % 5 != 0) {
        throw std::runtime_error("Bit stream length is not a multiple of 5");
    }

    std::string text;
    text.reserve(bits.size() / 5);

    for (size_t i = 0; i < bits.size(); i += 5) {
        uint8_t val = 0;
        
        // Combine 5 bits, MSB first
        for (int j = 0; j < 5; ++j) {
            val = (val << 1) | bits[i + j];
        }
        
        text.push_back(valueToChar(val));
    }

    return text;
}