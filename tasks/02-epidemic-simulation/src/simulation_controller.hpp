#pragma once
#include <QObject>
#include <QVariantList>
#include <QVector>

#include "simulation.hpp"

class SimulationController : public QObject {
  Q_OBJECT
  Q_PROPERTY(int healthy_count READ get_healthy_count NOTIFY stats_changed)
  Q_PROPERTY(int infected_count READ get_infected_count NOTIFY stats_changed)
  Q_PROPERTY(int recovered_count READ get_recovered_count NOTIFY stats_changed)
 public:
  explicit SimulationController(QObject* parent = nullptr);

  Q_INVOKABLE void load_graph(const QString& path);
  Q_INVOKABLE void step();
  Q_INVOKABLE void reset();
  Q_INVOKABLE void set_infection_prob(double p);
  Q_INVOKABLE void set_recovery_prob(double p);

  Q_INVOKABLE void search_healthy();
  Q_INVOKABLE void search_recovered();
  Q_INVOKABLE void search_recovered_lonely();
  Q_INVOKABLE void search_healthy_surrounded();
  Q_INVOKABLE void clear_search();

  Q_INVOKABLE QVariantList get_node_states() const;

  Q_INVOKABLE QVariantList get_edges_for_nodes(const QVariantList& nodeIds) const;
  Q_INVOKABLE QVariantMap get_bfs_subgraph(int maxNodes) const;

  int get_healthy_count() const;
  int get_infected_count() const;
  int get_recovered_count() const;

 signals:
  void stats_changed();
  void simulation_updated();
  void search_results_ready(QVector<int> ids);
  void load_failed(QString reason);

 private:
  void emit_search(const std::vector<int>& ids);

  std::unique_ptr<Simulation> m_sim;
  double m_p_infect = 0.3;
  double m_p_recover = 0.1;
  QString m_csv_path;
};
