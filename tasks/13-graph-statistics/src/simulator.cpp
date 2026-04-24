#include "simulator.h"

#include <atomic>
#include <chrono>
#include <cstdio>
#include <mutex>
#include <random>
#include <thread>
#include <vector>

#include "arena_allocator.h"
#include "arena_resource.h"
#include "graph.h"
#include "memory_units.h"
#include "os_memory.h"
#include "solvers_connectivity.h"
#include "solvers_cycle.h"
#include "solvers_mst.h"
#include "solvers_spanning.h"
#include "virtual_heap.h"

static constexpr i32 kMetricCount = static_cast<i32>(Metric::kCount);
static constexpr usize kHeapSize = megabytes(4);

struct Accum {
  double sum = 0.0;
  double sum_sq = 0.0;
  i32 count = 0;

  void add(double v) {
    sum += v;
    sum_sq += v * v;
    count++;
  }

  Stats finalize() const {
    if (count == 0) {
      return {0.0, 0.0};
    }
    double mean = sum / count;
    double var = sum_sq / count - mean * mean;
    return {mean, var};
  }
};

static bool needs_adj(const bool* metrics) {
  return metrics[static_cast<int>(Metric::kConnectedComponents)]
         || metrics[static_cast<int>(Metric::kCliqueComponents)];
}

static bool needs_cycle(const bool* metrics) {
  return metrics[static_cast<int>(Metric::kLongestCycleEdges)]
         || metrics[static_cast<int>(Metric::kHeaviestCycleEdges)];
}

static void run_trials_range(
    i32 start, i32 end,
    const SimulatorConfig& config,
    Accum* accums,
    std::mutex* mu,
    std::atomic<i32>* progress
    ) {
  OSMemory os;
  os.init();

  VirtualHeap heap;
  heap.init(os, kHeapSize);

  MemoryBlock block = heap.take(kHeapSize);
  ArenaAllocator arena;
  arena.init(block);

  ArenaResource res(&arena);

  std::mt19937 rng(config.seed ^ start);

  Accum local[kMetricCount];

  for (i32 trial = start; trial < end; trial++) {
    auto mark = arena.save();

    Graph g = make_graph(arena, config.n);
    generate_graph(g, rng, config.edge_length, config.graph_density);

    const AdjList* adj_ptr = nullptr;
    AdjList adj(0, std::pmr::vector<AdjNode>(&res), &res);

    if (needs_adj(config.metrics)) {
      adj = make_adj_list(g, &res);
      adj_ptr = &adj;
    }

    CycleStats cycle_stats{};
    if (needs_cycle(config.metrics)) {
      cycle_stats = find_cycle_stats(g);
    }

    if (config.metrics[static_cast<int>(Metric::kMstWeight)]) {
      local[static_cast<int>(Metric::kMstWeight)].add(
          static_cast<double>(mst_weight(g)));
    }
    if (config.metrics[static_cast<int>(Metric::kLongestCycleEdges)]) {
      local[static_cast<int>(Metric::kLongestCycleEdges)].add(
          static_cast<double>(cycle_stats.longest_by_edges));
    }
    if (config.metrics[static_cast<int>(Metric::kHeaviestCycleEdges)]) {
      local[static_cast<int>(Metric::kHeaviestCycleEdges)].add(
          static_cast<double>(cycle_stats.edge_count_of_heaviest));
    }
    if (config.metrics[static_cast<int>(Metric::kIsolatedVertices)]) {
      local[static_cast<int>(Metric::kIsolatedVertices)].add(
          static_cast<double>(count_isolated_vertices(g)));
    }
    if (config.metrics[static_cast<int>(Metric::kSpanningTrees)]) {
      local[static_cast<int>(Metric::kSpanningTrees)].add(
          static_cast<double>(count_spanning_trees(g)));
    }
    if (config.metrics[static_cast<int>(Metric::kConnectedComponents)]) {
      local[static_cast<int>(Metric::kConnectedComponents)].add(
          static_cast<double>(count_connected_components(*adj_ptr)));
    }
    if (config.metrics[static_cast<int>(Metric::kCliqueComponents)]) {
      local[static_cast<int>(Metric::kCliqueComponents)].add(
          static_cast<double>(count_clique_components(g, *adj_ptr)));
    }

    arena.restore(mark);
    progress->fetch_add(1, std::memory_order_relaxed);
  }

  {
    std::lock_guard lock(*mu);
    for (i32 m = 0; m < kMetricCount; m++) {
      accums[m].sum += local[m].sum;
      accums[m].sum_sq += local[m].sum_sq;
      accums[m].count += local[m].count;
    }
  }

  arena.destroy();
  heap.destroy();
  os.destroy();
}

static void progress_thread_fn(
    std::atomic<i32>* progress,
    std::atomic<bool>* done,
    i32 total
) {
  using clock = std::chrono::steady_clock;
  auto t_start = clock::now();

  while (!done->load(std::memory_order_relaxed)) {
    std::this_thread::sleep_for(std::chrono::milliseconds(200));

    i32 done_count = progress->load(std::memory_order_relaxed);
    if (done_count == 0) continue;

    double elapsed = std::chrono::duration<double>(clock::now() - t_start).count();
    double eta = elapsed / done_count * (total - done_count);

    int pct = done_count * 100 / total;
    int bar_filled = pct / 5;

    char eta_buf[32];
    if (eta < 60.0) {
      std::snprintf(eta_buf, sizeof(eta_buf), "%4.1fs", eta);
    } else if (eta < 3600.0) {
      int m = static_cast<int>(eta) / 60;
      int s = static_cast<int>(eta) % 60;
      std::snprintf(eta_buf, sizeof(eta_buf), "%dm%02ds", m, s);
    } else {
      int h = static_cast<int>(eta) / 3600;
      int m = (static_cast<int>(eta) % 3600) / 60;
      std::snprintf(eta_buf, sizeof(eta_buf), "%dh%02dm", h, m);
    }

    std::fprintf(stderr,
        "\r[%-20.*s%*s] %3d%%  ETA: %8s  (%d/%d)",
        bar_filled, "====================",
        20 - bar_filled, "",
        pct, eta_buf,
        done_count, total);
    std::fflush(stderr);
  }

  std::fprintf(stderr,
      "\r[====================] 100%%  Done                    \n");
  std::fflush(stderr);
}

SimulatorResult run_simulation(const SimulatorConfig& config) {
  i32 trials = precision_to_trials(config.precision);
  i32 hw_threads = static_cast<i32>(std::thread::hardware_concurrency());
  i32 num_threads = hw_threads < 1 ? 1 : hw_threads;

  bool any_metric = false;
  for (i32 m = 0; m < kMetricCount; m++) {
    if (config.metrics[m]) {
      any_metric = true;
      break;
    }
  }

  SimulatorResult result{};
  if (!any_metric) {
    return result;
  }

  Accum accums[kMetricCount];
  std::mutex mu;

  std::atomic<i32> progress{0};
  std::atomic<bool> prog_done{false};
  std::thread prog_thread(progress_thread_fn, &progress, &prog_done, trials);

  if (num_threads == 1) {
    run_trials_range(0, trials, config, accums, &mu, &progress);
  } else {
    std::vector<std::thread> threads;
    threads.reserve(num_threads);

    i32 chunk = trials / num_threads;
    i32 rem = trials % num_threads;
    i32 offset = 0;

    for (i32 t = 0; t < num_threads; t++) {
      i32 count = chunk + (t < rem ? 1 : 0);
      threads.emplace_back(run_trials_range,
                           offset, offset + count,
                           std::cref(config), accums, &mu, &progress);
      offset += count;
    }
    for (auto& th : threads) {
      th.join();
    }
  }

  prog_done.store(true, std::memory_order_relaxed);
  prog_thread.join();

  for (i32 m = 0; m < kMetricCount; m++) {
    if (config.metrics[m]) {
      result.results[m] = accums[m].finalize();
      result.computed[m] = true;
    }
  }

  return result;
}