#include "graph.h"

#include <algorithm>

#include "check.h"

i32 upper_triangle_size(i32 n) {
  return n * (n - 1) / 2;
}

i32 edge_index(i32 n, i32 i, i32 j) {
  if (i > j) { std::swap(i, j); }
  return i * n - i * (i + 1) / 2 + j - i - 1;
}

u8 edge_weight(const Graph& g, i32 i, i32 j) {
  return g.edges[edge_index(g.n, i, j)];
}

bool edge_exists(const Graph& g, i32 i, i32 j) {
  return edge_weight(g, i, j) != 0;
}

Graph make_graph(ArenaAllocator& arena, i32 n) {
  check(n > 0);
  i32 total = upper_triangle_size(n);
  u8* data = arena.push<u8>(total);
  return Graph{.n = n, .edges = {data, static_cast<usize>(total)}};
}

void generate_graph(Graph& g, std::mt19937& rng, i32 edge_length,
                    f32 graph_density) {
  std::uniform_real_distribution<f32> is_empty(0, 1.0);
  std::uniform_int_distribution<i32> dist(1, edge_length);
  for (auto& e : g.edges) {
    if (is_empty(rng) < graph_density) {
      e = static_cast<u8>(dist(rng));
    } else {
      e = 0;
    }
  }
}

AdjList make_adj_list(const Graph& g, std::pmr::memory_resource* mr) {
  AdjList adj(g.n, std::pmr::vector<AdjNode>(mr), mr);

  for (i32 i = 0; i < g.n; i++) {
    for (i32 j = i + 1; j < g.n; j++) {
      u8 w = edge_weight(g, i, j);
      if (w == 0) { continue; }
      adj[i].push_back({.to = j, .weight = w});
      adj[j].push_back({.to = i, .weight = w});
    }
  }

  return adj;
}