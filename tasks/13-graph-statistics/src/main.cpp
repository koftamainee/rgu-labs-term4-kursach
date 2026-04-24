#include <iostream>
#include <fstream>
#include <unordered_map>
#include <string>

#include <nlohmann/json.hpp>

#include "simulator.h"

using json = nlohmann::json;

static Metric metric_from_string(const std::string& s) {
  static const std::unordered_map<std::string, Metric> map = {
      {"mst_weight", Metric::kMstWeight},
      {"longest_cycle_edges", Metric::kLongestCycleEdges},
      {"heaviest_cycle_edges", Metric::kHeaviestCycleEdges},
      {"isolated_vertices", Metric::kIsolatedVertices},
      {"spanning_trees", Metric::kSpanningTrees},
      {"connected_components", Metric::kConnectedComponents},
      {"clique_components", Metric::kCliqueComponents},
  };

  return map.at(s);
}

static std::string metric_to_string(Metric m) {
  switch (m) {
    case Metric::kMstWeight:
      return "mst_weight";
    case Metric::kLongestCycleEdges:
      return "longest_cycle_edges";
    case Metric::kHeaviestCycleEdges:
      return "heaviest_cycle_edges";
    case Metric::kIsolatedVertices:
      return "isolated_vertices";
    case Metric::kSpanningTrees:
      return "spanning_trees";
    case Metric::kConnectedComponents:
      return "connected_components";
    case Metric::kCliqueComponents:
      return "clique_components";
    default:
      return "unknown";
  }
}

static Precision parse_precision(const std::string& p) {
  if (p == "extreme") return Precision::kExtreme;
  if (p == "high") return Precision::kHigh;
  if (p == "medium") return Precision::kMedium;
  return Precision::kLow;
}

int main(int argc, char** argv) {
  if (argc < 3) {
    std::cerr << "usage: simulator <input.json> <output.json>\n";
    return 1;
  }

  std::ifstream in(argv[1]);
  json j;
  in >> j;

  SimulatorConfig config{
      .n = j["n"].get<i32>(),
      .edge_length = j["edge_length"].get<i32>(),
      .graph_density = j["graph_density"].get<f32>(),
      .seed = j["seed"].get<i64>(),
      .precision = parse_precision(j["precision"].get<std::string>()),
  };

  for (u32 i = 0; i < static_cast<u32>(Metric::kCount); ++i) {
    config.metrics[i] = false;
  }

  for (auto& [key, value] : j["metrics"].items()) {
    if (value.get<bool>()) {
      Metric m = metric_from_string(key);
      config.metrics[static_cast<u32>(m)] = true;
    }
  }

  SimulatorResult result = run_simulation(config);

  json out;
  json results_json;

  for (u32 i = 0; i < static_cast<u32>(Metric::kCount); ++i) {
    auto m = static_cast<Metric>(i);
    const Stats& stats = result.results[i];

    if (!config.metrics[i]) continue;

    results_json[metric_to_string(m)] = {
        {"mean", stats.mean},
        {"variance", stats.variance}
    };
  }

  out["results"] = results_json;

  std::ofstream os(argv[2]);
  os << out.dump(2);

  return 0;
}