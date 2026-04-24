#pragma once
#include <random>
#include <utility>
#include <vector>

class Simulation {
 public:
  enum class Mode {
    ReturnToSender,
    RepeatedMessage,
  };

  struct GraphNode {
    size_t from;
    size_t to;
    size_t step;
  };

  Simulation();
  void set_n(size_t n);
  void set_N(size_t N);
  void set_mode(Mode mode);
  std::pair<bool, std::vector<GraphNode>> run(size_t r, int seed = std::random_device{}());

 private:
  size_t m_n;
  size_t m_N;
  std::mt19937 m_rng;
  Mode m_mode;
};
