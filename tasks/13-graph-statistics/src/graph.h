#pragma once

#include <cstdint>
#include <memory_resource>
#include <random>
#include <span>
#include <vector>

#include "arena_allocator.h"
#include "arena_resource.h"
#include "types.h"

struct Graph {
  i32 n;
  std::span<u8> edges;
};

struct AdjNode {
  i32 to;
  u8 weight;
};

using AdjList = std::pmr::vector<std::pmr::vector<AdjNode>>;

i32 upper_triangle_size(i32 n);
i32 edge_index(i32 n, i32 i, i32 j);
u8 edge_weight(const Graph& g, i32 i, i32 j);
bool edge_exists(const Graph& g, i32 i, i32 j);

Graph make_graph(ArenaAllocator& arena, i32 n);
void generate_graph(Graph& g, std::mt19937& rng, i32 edge_length,
                    f32 graph_density);
AdjList make_adj_list(const Graph& g, std::pmr::memory_resource* mr);