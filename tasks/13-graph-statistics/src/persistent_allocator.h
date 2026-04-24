#pragma once

#include <type_traits>
#include <utility>

#include "memory_block.h"
#include "virtual_heap.h"
#include "types.h"

    class PersistentAllocator final {
    public:
        PersistentAllocator() = default;
        ~PersistentAllocator() = default;

        MANTLE_NO_COPY(PersistentAllocator);

        void init(VirtualHeap *heap);

        [[nodiscard]] MemoryBlock take(usize size);

        template <typename T, typename... Args>
        [[nodiscard]] T *emplace(Args &&...args) {
            MemoryBlock block = take(sizeof(T));
            return new (block.ptr) T(std::forward<Args>(args)...);
        }

        template <typename T>
        [[nodiscard]] T *push(usize count = 1) {
            static_assert(std::is_trivially_constructible_v<T>);
            MemoryBlock block = take(sizeof(T) * count);
            return static_cast<T *>(block.ptr);
        }

    private:
        VirtualHeap *m_heap = nullptr;
    };