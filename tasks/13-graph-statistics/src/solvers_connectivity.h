#pragma once

#include "graph.h"
#include "types.h"

i32 count_isolated_vertices(const Graph &g);
i32 count_connected_components(const AdjList &adj);
i32 count_clique_components(const Graph &g, const AdjList &adj);