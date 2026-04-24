#include <vector>
#include <algorithm>

#include "graph.h"


i64 count_spanning_trees(const Graph& g) {
  i32 n = g.n;
  if (n <= 1) return 1;

  i32 m = n - 1;

  std::vector<std::vector<i64>> a(m, std::vector<i64>(m, 0));

  // reduced Laplacian ????
  for (i32 i = 0; i < m; i++) {
    i64 degree = 0;

    for (i32 k = 0; k < n; k++) {
      if (k != i && edge_exists(g, i, k)) {
        degree++;
      }
    }

    a[i][i] = degree;

    for (i32 j = 0; j < m; j++) {
      if (i == j) continue;
      a[i][j] = edge_exists(g, i, j) ? -1 : 0;
    }
  }

  i64 prev = 1;

  for (i32 k = 0; k < m; k++) {
    if (a[k][k] == 0) return 0;

    for (i32 i = k + 1; i < m; i++) {
      for (i32 j = k + 1; j < m; j++) {

        i64 numerator =
            a[i][j] * a[k][k] -
            a[i][k] * a[k][j];

        a[i][j] = numerator / prev;
      }
    }

    prev = a[k][k];
  }

  return a[m - 1][m - 1];
}