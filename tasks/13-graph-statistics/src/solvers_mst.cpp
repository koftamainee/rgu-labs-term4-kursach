#include "solvers_mst.h"

#include <limits>

// Prim's algorithm on adjacency matrix, O(n^2)
i32 mst_weight(const Graph& g) {
  i32 n = g.n;
  if (n <= 1) {
    return 0;
  }

  constexpr i32 kInf = std::numeric_limits<i32>::max();

  i32 key[n];
  bool in_mst[n];

  for (i32 i = 0; i < n; i++) {
    key[i] = kInf;
    in_mst[i] = false;
  }
  key[0] = 0;

  i32 total = 0;
  for (i32 iter = 0; iter < n; iter++) {
    i32 u = -1;
    for (i32 v = 0; v < n; v++) {
      if (!in_mst[v] && (u == -1 || key[v] < key[u])) {
        u = v;
      }
    }

    if (key[u] == kInf) {
      break;
    }

    in_mst[u] = true;
    total += key[u];

    for (i32 v = 0; v < n; v++) {
      if (!in_mst[v] && edge_exists(g, u, v)) {
        i32 w = static_cast<i32>(edge_weight(g, u, v));
        if (w < key[v]) {
          key[v] = w;
        }
      }
    }
  }

  return total;
}