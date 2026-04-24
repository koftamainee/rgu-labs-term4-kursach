#include "solvers_cycle.h"

struct CycleDfs {
  const Graph& g;
  bool* visited;
  i32 path_len;
  i32 best_edges;
  i32 best_weight_edges;
  i32 best_weight;
};

static void dfs(CycleDfs& s, i32 v, i32 start, i32 depth, i32 weight_so_far) {
  s.visited[v] = true;
  s.path_len++;

  for (i32 u = 0; u < s.g.n; u++) {
    if (u == v || !edge_exists(s.g, v, u)) {
      continue;
    }
    i32 w = static_cast<i32>(edge_weight(s.g, v, u));

    if (u == start && depth >= 2) {
      i32 cycle_edges = s.path_len;
      i32 cycle_weight = weight_so_far + w;
      if (cycle_edges > s.best_edges) {
        s.best_edges = cycle_edges;
      }
      if (cycle_weight > s.best_weight) {
        s.best_weight = cycle_weight;
        s.best_weight_edges = cycle_edges;
      }
      continue;
    }

    if (!s.visited[u]) {
      dfs(s, u, start, depth + 1, weight_so_far + w);
    }
  }

  s.path_len--;
  s.visited[v] = false;
}

// in worst case this is exp :(
CycleStats find_cycle_stats(const Graph& g) {
  i32 n = g.n;

  bool visited[n];

  CycleDfs s{
      .g = g,
      .visited = visited,
      .path_len = 0,
      .best_edges = 0,
      .best_weight_edges = 0,
      .best_weight = 0,
  };

  for (i32 start = 0; start < n; start++) {
    for (i32 i = 0; i < n; i++) {
      visited[i] = false;
    }
    s.path_len = 0;
    dfs(s, start, start, 0, 0);
  }

  return CycleStats{
      .longest_by_edges = s.best_edges,
      .edge_count_of_heaviest = s.best_weight_edges,
  };
}