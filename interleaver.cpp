#include "interleaver.h"
#include <vector>
#include <stdexcept>
#include <cstddef>

constexpr size_t INTERLEAVER_DEPTH = 16;

InterleaveResult interleave(const std::vector<bool>& bits) {
    if (bits.empty()) {
        return {{}, 0};
    }

    size_t orig_size = bits.size();
    size_t paddingBits = (INTERLEAVER_DEPTH - (orig_size % INTERLEAVER_DEPTH)) % INTERLEAVER_DEPTH;
    size_t padded_size = orig_size + paddingBits;
    size_t cols = padded_size / INTERLEAVER_DEPTH;

    std::vector<bool> interleaved_bits;
    interleaved_bits.reserve(padded_size);

    for (size_t c = 0; c < cols; ++c) {
        for (size_t r = 0; r < INTERLEAVER_DEPTH; ++r) {
            size_t idx = r * cols + c;
            if (idx < orig_size) {
                interleaved_bits.push_back(bits[idx]);
            } else {
                interleaved_bits.push_back(false);
            }
        }
    }

    return {std::move(interleaved_bits), paddingBits};
}

std::vector<bool> deinterleave(const std::vector<bool>& bits, size_t paddingBits) {
    if (bits.size() % INTERLEAVER_DEPTH != 0) {
        throw std::invalid_argument("Input size must be divisible by 16.");
    }

    if (paddingBits > bits.size()) {
        throw std::invalid_argument("Padding bits cannot be larger than the bitstream size.");
    }

    if (bits.empty()) {
        return {};
    }

    size_t padded_size = bits.size();
    size_t cols = padded_size / INTERLEAVER_DEPTH;
    size_t orig_size = padded_size - paddingBits;

    std::vector<bool> deinterleaved_bits;
    deinterleaved_bits.reserve(orig_size);

    for (size_t i = 0; i < orig_size; ++i) {
        size_t r = i / cols;
        size_t c = i % cols;
        size_t in_idx = c * INTERLEAVER_DEPTH + r;
        deinterleaved_bits.push_back(bits[in_idx]);
    }

    return deinterleaved_bits;
}