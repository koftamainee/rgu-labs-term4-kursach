#include "solvers_connectivity.h"

#include <memory_resource>
#include <vector>

i32 count_isolated_vertices(const Graph &g) {
  i32 count = 0;
  for (i32 i = 0; i < g.n; i++) {
    bool isolated = true;
    for (i32 j = 0; j < g.n; j++) {
      if (i != j && edge_exists(g, i, j)) {
        isolated = false;
        break;
      }
    }
    if (isolated) {
      count++;
    }
  }
  return count;
}

static std::pmr::vector<i32> label_components(const AdjList &adj,
                                              std::pmr::memory_resource *mr) {
  i32 n = static_cast<i32>(adj.size());
  std::pmr::vector<i32> label(n, -1, mr);
  std::pmr::vector<i32> queue(n, 0, mr);

  i32 next_label = 0;
  for (i32 start = 0; start < n; start++) {
    if (label[start] != -1) {
      continue;
    }

    i32 head = 0, tail = 0;
    queue[tail++] = start;
    label[start] = next_label;

    while (head < tail) {
      i32 v = queue[head++];
      for (const AdjNode &nb : adj[v]) {
        if (label[nb.to] == -1) {
          label[nb.to] = next_label;
          queue[tail++] = nb.to;
        }
      }
    }
    next_label++;
  }

  return label;
}

i32 count_connected_components(const AdjList &adj) {
  std::pmr::unsynchronized_pool_resource pool;
  std::pmr::vector<i32> label = label_components(adj, &pool);

  i32 max_label = -1;
  for (i32 l : label) {
    if (l > max_label) {
      max_label = l;
    }
  }
  return max_label + 1;
}

static bool component_is_clique(const Graph &g,
                                const std::pmr::vector<i32> &label,
                                i32 target_label,
                                std::pmr::memory_resource *mr) {
  std::pmr::vector<i32> verts(mr);
  for (i32 i = 0; i < g.n; i++) {
    if (label[i] == target_label) {
      verts.push_back(i);
    }
  }

  for (i32 a = 0; a < static_cast<i32>(verts.size()); a++) {
    for (i32 b = a + 1; b < static_cast<i32>(verts.size()); b++) {
      if (!edge_exists(g, verts[a], verts[b])) {
        return false;
      }
    }
  }
  return true;
}

i32 count_clique_components(const Graph &g, const AdjList &adj) {
  std::pmr::unsynchronized_pool_resource pool;
  std::pmr::vector<i32> label = label_components(adj, &pool);

  i32 max_label = -1;
  for (i32 l : label) {
    if (l > max_label) {
      max_label = l;
    }
  }
  i32 num_components = max_label + 1;

  i32 count = 0;
  for (i32 cid = 0; cid < num_components; cid++) {
    if (component_is_clique(g, label, cid, &pool)) {
      count++;
    }
  }
  return count;
}