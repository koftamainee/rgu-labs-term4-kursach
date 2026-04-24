#pragma once
#include "arena_allocator.h"

    struct ScopeArena final {
        ArenaAllocator *arena;
        ArenaAllocator::Marker tag;

        // NOTE: maybe use only no copy, and implement move operator
        MANTLE_NO_COPY_NO_MOVE(ScopeArena);

        explicit ScopeArena(ArenaAllocator *a) : arena(a), tag(a->save()) {}
        ~ScopeArena() { arena->restore(tag); }
    };
