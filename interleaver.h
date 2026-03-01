#pragma once

#include <vector>
#include <cstddef>

struct InterleaveResult {
    std::vector<bool> bits;
    std::size_t paddingBits;
};

InterleaveResult interleave(const std::vector<bool>& bits);

std::vector<bool> deinterleave(const std::vector<bool>& bits, std::size_t paddingBits);