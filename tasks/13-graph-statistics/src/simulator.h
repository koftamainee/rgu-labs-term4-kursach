#pragma once

#include <cstdint>

#include "types.h"

enum class Metric : u8 {
  kMstWeight = 0,
  kLongestCycleEdges = 1,
  kHeaviestCycleEdges = 2,
  kIsolatedVertices = 3,
  kSpanningTrees = 4,
  kConnectedComponents = 5,
  kCliqueComponents = 6,
  kCount = 7,
};

struct Stats {
  double mean;
  double variance;
};

enum class Precision : u8 {
  kLow = 0,
  kMedium = 1,
  kHigh = 2,
  kExtreme = 3,
};

constexpr i32 precision_to_trials(Precision p) {
  switch (p) {
    case Precision::kLow:
      return 1'000;
    case Precision::kMedium:
      return 10'000;
    case Precision::kHigh:
      return 100'000;
    case Precision::kExtreme:
      return 1'000'000;
  }
  return 10'000;
}

struct SimulatorConfig {
  i32 n;
  i32 edge_length;
  f32 graph_density;
  i64 seed;
  Precision precision;
  bool metrics[static_cast<int>(Metric::kCount)];
};

struct SimulatorResult {
  Stats results[static_cast<int>(Metric::kCount)];
  bool computed[static_cast<int>(Metric::kCount)];
};

SimulatorResult run_simulation(const SimulatorConfig& config);