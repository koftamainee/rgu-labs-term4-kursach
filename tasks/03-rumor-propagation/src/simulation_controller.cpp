#include "simulation_controller.hpp"

#include <QCoreApplication>
#include <QVariantList>
#include <QVariantMap>
#include <random>
#include <stdexcept>

SimulationController::SimulationController(QObject* parent) : QObject(parent), m_sim(std::make_unique<Simulation>()) {
  m_sim->set_n(m_n);
  m_sim->set_N(m_N);
  m_sim->set_mode(m_mode);
}

void SimulationController::set_n(int n) {
  if (n < 1) {
    return;
  }
  m_n = static_cast<size_t>(n);
  emit params_changed();
}

void SimulationController::set_r(int r) {
  if (r < 1) {
    return;
  }
  m_r = static_cast<size_t>(r);
  emit params_changed();
}

void SimulationController::set_N(int N) {
  if (N < 1) {
    return;
  }
  m_N = static_cast<size_t>(N);
  emit params_changed();
}

void SimulationController::set_K(qint64 K) {
  if (K < 1) {
    return;
  }
  m_K = static_cast<size_t>(K);
  emit params_changed();
}

void SimulationController::set_mode(int mode) {
  if (mode == 0) {
    m_mode = Simulation::Mode::ReturnToSender;
  } else {
    m_mode = Simulation::Mode::RepeatedMessage;
  }
  emit params_changed();
}

void SimulationController::set_fast_mode(bool fast) {
  m_fast_mode = fast;
  emit params_changed();
}

double SimulationController::get_success_prob() const {
  if (m_experiments_done == 0) {
    return 0.0;
  }
  return static_cast<double>(m_success_count) / m_experiments_done;
}

void SimulationController::start() {
  if (m_is_running) {
    return;
  }
  reset();
  m_is_running = true;
  m_stop_requested = false;
  emit running_changed();

  if (m_fast_mode) {
    run_fast_batch();
  } else {
    for (size_t k = 0; k < m_K; ++k) {
      if (m_stop_requested) {
        break;
      }
      run_next_experiment();
      QCoreApplication::processEvents();
    }
  }

  m_is_running = false;
  m_stop_requested = false;
  emit running_changed();
  emit all_experiments_completed();
}

void SimulationController::stop() { m_stop_requested = true; }

void SimulationController::reset() {
  m_success_count = 0;
  m_failure_count = 0;
  m_experiments_done = 0;
  m_results.clear();
  emit stats_changed();
}

void SimulationController::run_single() {
  if (m_is_running) {
    return;
  }
  run_next_experiment();
  emit all_experiments_completed();
}

void SimulationController::run_fast_batch() {
  const size_t n = m_n;
  const size_t r = m_r;
  const size_t N = m_N;
  const bool return_to_sender = (m_mode == Simulation::Mode::ReturnToSender);
  const size_t flush_interval = 65536;

  std::mt19937 rng(std::random_device{}());
  std::uniform_int_distribution<int> dist(0, static_cast<int>(n));

  std::vector<size_t> knowers;
  knowers.reserve(n + 1);

  for (size_t k = 0; k < m_K; ++k) {
    if (m_stop_requested) {
      break;
    }

    std::vector<bool> knows(n + 1, false);
    knows[0] = true;
    bool failed = false;

    for (size_t step = 0; step < r && !failed; ++step) {
      knowers.clear();
      for (size_t i = 0; i <= n; ++i) {
        if (knows[i]) {
          knowers.push_back(i);
        }
      }

      for (size_t ki = 0; ki < knowers.size() && !failed; ++ki) {
        size_t sender = knowers[ki];
        for (size_t j = 0; j < N && !failed; ++j) {
          int target;
          do {
            target = dist(rng);
          } while (static_cast<size_t>(target) == sender);

          if (return_to_sender) {
            if (target == 0) {
              failed = true;
              break;
            }
          } else {
            if (knows[static_cast<size_t>(target)]) {
              failed = true;
              break;
            }
          }
          knows[static_cast<size_t>(target)] = true;
        }
      }
    }

    if (!failed) {
      ++m_success_count;
    } else {
      ++m_failure_count;
    }
    ++m_experiments_done;

    if (k % flush_interval == 0) {
      emit stats_changed();
      QCoreApplication::processEvents();
    }
  }

  emit stats_changed();
}

void SimulationController::run_next_experiment() {
  try {
    m_sim->set_n(m_n);
    m_sim->set_N(m_N);
    m_sim->set_mode(m_mode);

    auto [success, graph] = m_sim->run(m_r);

    ExperimentResult result;
    result.success = success;
    result.steps_taken = static_cast<int>(graph.size());
    result.graph = std::move(graph);

    if (result.success) {
      ++m_success_count;
    } else {
      ++m_failure_count;
    }
    ++m_experiments_done;

    const int max_stored_graphs = 100000;
    if (static_cast<int>(m_results.size()) >= max_stored_graphs) {
      m_results.erase(m_results.begin());
    }
    m_results.push_back(std::move(result));

    emit stats_changed();
    emit experiment_completed(m_experiments_done - 1, m_results.back().success, m_results.back().steps_taken);

  } catch (const std::exception& e) {
    emit error_occurred(QString::fromStdString(e.what()));
  }
}

QVariantList SimulationController::get_results() const {
  QVariantList list;
  list.reserve(static_cast<int>(m_results.size()));
  for (int i = 0; i < static_cast<int>(m_results.size()); ++i) {
    const auto& r = m_results[static_cast<size_t>(i)];
    QVariantMap map;
    map["index"] = i;
    map["success"] = r.success;
    map["steps_taken"] = r.steps_taken;
    list.append(map);
  }
  return list;
}

QVariantMap SimulationController::get_experiment_graph(int index) const {
  if (index < 0 || index >= static_cast<int>(m_results.size())) {
    return {};
  }

  const auto& result = m_results[static_cast<size_t>(index)];

  QSet<int> nodeSet;
  nodeSet.insert(0);
  for (const auto& node : result.graph) {
    nodeSet.insert(static_cast<int>(node.from));
    nodeSet.insert(static_cast<int>(node.to));
  }

  QVariantList nodes;
  for (int id : nodeSet) {
    nodes.append(id);
  }

  QVariantList edges;
  for (const auto& node : result.graph) {
    QVariantMap edge;
    edge["from"] = static_cast<int>(node.from);
    edge["to"] = static_cast<int>(node.to);
    edge["step"] = static_cast<int>(node.step);
    edges.append(edge);
  }

  QVariantMap graph;
  graph["nodes"] = nodes;
  graph["edges"] = edges;
  graph["success"] = result.success;
  graph["index"] = index;
  return graph;
}

QVariantMap SimulationController::get_result_at(int index) const {
  if (index < 0 || index >= static_cast<int>(m_results.size())) {
    return {};
  }
  const auto& r = m_results[static_cast<size_t>(index)];
  QVariantMap map;
  map["index"] = index;
  map["success"] = r.success;
  map["steps_taken"] = r.steps_taken;
  return map;
}

QVariantMap SimulationController::get_last_graph() const {
  if (m_results.empty()) {
    return {};
  }
  return get_experiment_graph(static_cast<int>(m_results.size()) - 1);
}
