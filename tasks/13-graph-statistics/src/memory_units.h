#pragma once

#include "types.h"

    constexpr usize bytes(usize n) { return n; }
    constexpr usize kilobytes(usize n) { return n * 1024; }
    constexpr usize megabytes(usize n) { return n * 1024 * 1024; }
    constexpr usize gigabytes(usize n) {
        return n * 1024ull * 1024ull * 1024ull;
    }
