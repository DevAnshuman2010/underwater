#ifndef FRAME_BUILDER_H
#define FRAME_BUILDER_H

#include <string>
#include <vector>

// Note: We include these so the header knows about InterleaveResult 
// and the vector-based function signatures.
#include "fivebits.h"
#include "interleaver.h"

// Protocol Constants
extern const std::string PREAMBLE;
extern const std::string SYNC;

// Bridge Helper
std::string vectorToBitString(const std::vector<bool>& bits);

// Core Frame Builder Functions
std::string toBinary(int value, int bits);
std::string computeChecksum(const std::string& bits);
std::string buildFrame(const std::string& message);

#endif // FRAME_BUILDER_H