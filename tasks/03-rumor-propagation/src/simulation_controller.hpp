#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <memory>
#include <vector>

#include "simulation.hpp"

class SimulationController : public QObject {
  Q_OBJECT

  Q_PROPERTY(int n READ get_n WRITE set_n NOTIFY params_changed)
  Q_PROPERTY(int r READ get_r WRITE set_r NOTIFY params_changed)
  Q_PROPERTY(int N READ get_N WRITE set_N NOTIFY params_changed)
  Q_PROPERTY(qint64 K READ get_K WRITE set_K NOTIFY params_changed)
  Q_PROPERTY(int mode READ get_mode WRITE set_mode NOTIFY params_changed)
  Q_PROPERTY(bool fast_mode READ get_fast_mode WRITE set_fast_mode NOTIFY params_changed)

  Q_PROPERTY(int success_count READ get_success_count NOTIFY stats_changed)
  Q_PROPERTY(int failure_count READ get_failure_count NOTIFY stats_changed)
  Q_PROPERTY(double success_prob READ get_success_prob NOTIFY stats_changed)
  Q_PROPERTY(int experiments_done READ get_experiments_done NOTIFY stats_changed)
  Q_PROPERTY(bool is_running READ get_is_running NOTIFY running_changed)

 public:
  explicit SimulationController(QObject* parent = nullptr);

  int get_n() const { return static_cast<int>(m_n); }
  int get_r() const { return static_cast<int>(m_r); }
  int get_N() const { return static_cast<int>(m_N); }
  qint64 get_K() const { return static_cast<qint64>(m_K); }
  int get_mode() const { return static_cast<int>(m_mode); }
  bool get_fast_mode() const { return m_fast_mode; }

  void set_n(int n);
  void set_r(int r);
  void set_N(int N);
  void set_K(qint64 K);
  void set_mode(int mode);
  void set_fast_mode(bool fast);

  int get_success_count() const { return m_success_count; }
  int get_failure_count() const { return m_failure_count; }
  double get_success_prob() const;
  int get_experiments_done() const { return m_experiments_done; }
  bool get_is_running() const { return m_is_running; }

  Q_INVOKABLE void start();
  Q_INVOKABLE void stop();
  Q_INVOKABLE void reset();
  Q_INVOKABLE void run_single();

  Q_INVOKABLE QVariantList get_results() const;
  Q_INVOKABLE QVariantMap get_result_at(int index) const;
  Q_INVOKABLE QVariantMap get_experiment_graph(int index) const;
  Q_INVOKABLE QVariantMap get_last_graph() const;

 signals:
  void params_changed();
  void stats_changed();
  void running_changed();
  void experiment_completed(int index, bool success, int steps);
  void all_experiments_completed();
  void error_occurred(QString message);

 private:
  void run_next_experiment();
  void run_fast_batch();

  struct ExperimentResult {
    bool success;
    int steps_taken;
    std::vector<Simulation::GraphNode> graph;
  };

  size_t m_n = 10;
  size_t m_r = 5;
  size_t m_N = 1;
  size_t m_K = 1000;
  Simulation::Mode m_mode = Simulation::Mode::ReturnToSender;
  bool m_fast_mode = false;

  int m_success_count = 0;
  int m_failure_count = 0;
  int m_experiments_done = 0;
  bool m_is_running = false;
  bool m_stop_requested = false;

  std::unique_ptr<Simulation> m_sim;
  std::vector<ExperimentResult> m_results;
};
