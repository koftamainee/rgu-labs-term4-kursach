#include "simulation.hpp"

Simulation::Simulation() : m_n(0), m_N(1), m_mode(Mode::ReturnToSender) {}

void Simulation::set_n(size_t n) { m_n = n; }

void Simulation::set_N(size_t N) { m_N = N; }

void Simulation::set_mode(Mode mode) { m_mode = mode; }

std::pair<bool, std::vector<Simulation::GraphNode>> Simulation::run(size_t r, int seed) {
  m_rng = std::mt19937(seed);

  std::uniform_int_distribution<int> dist(0, m_n);

  std::vector<bool> knows(m_n + 1, false);
  knows[0] = true;

  std::vector<GraphNode> graph;

  for (size_t step = 0; step < r; ++step) {
    std::vector<size_t> knowers;
    for (size_t i = 0; i <= m_n; ++i) {
      if (knows[i]) {
        knowers.push_back(i);
      }
    }

    for (size_t ki = 0; ki < knowers.size(); ++ki) {
      size_t sender = knowers[ki];

      for (size_t j = 0; j < m_N; ++j) {
        int target;
        do {
          target = dist(m_rng);
        } while (static_cast<size_t>(target) == sender);

        if (m_mode == Mode::ReturnToSender) {
          if (target == 0) {
            GraphNode node;
            node.from = sender;
            node.to = 0;
            node.step = step;
            graph.push_back(node);
            return std::make_pair(false, graph);
          }
        } else {
          if (knows[static_cast<size_t>(target)]) {
            GraphNode node;
            node.from = sender;
            node.to = static_cast<size_t>(target);
            node.step = step;
            graph.push_back(node);
            return std::make_pair(false, graph);
          }
        }

        GraphNode node;
        node.from = sender;
        node.to = static_cast<size_t>(target);
        node.step = step;
        graph.push_back(node);
        knows[static_cast<size_t>(target)] = true;
      }
    }
  }

  return std::make_pair(true, graph);
}
