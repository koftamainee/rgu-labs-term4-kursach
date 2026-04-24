#pragma once

#include "graph.h"
#include "types.h"

struct CycleStats {
  i32 longest_by_edges;
  i32 edge_count_of_heaviest;
};

CycleStats find_cycle_stats(const Graph& g);