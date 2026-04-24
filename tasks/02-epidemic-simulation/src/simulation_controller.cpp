#include "simulation_controller.hpp"

#include <QDebug>
#include <QVariantMap>
#include <queue>
#include <unordered_map>
#include <unordered_set>

SimulationController::SimulationController(QObject* parent) : QObject(parent) {}

void SimulationController::load_graph(const QString& path) {
  m_csv_path = path;
  try {
    auto people = Simulation::load_csv(path.toStdString());
    m_sim = std::make_unique<Simulation>(people, m_p_infect, m_p_recover);
    emit stats_changed();
    emit simulation_updated();
    qDebug() << "Loaded" << m_sim->get_people().size() << "nodes.";
  } catch (const std::exception& e) {
    m_sim.reset();
    qWarning() << "Failed to load graph:" << e.what();
    emit stats_changed();
    emit load_failed(QString::fromStdString(e.what()));
  }
}

void SimulationController::step() {
  if (m_sim) {
    m_sim->step();
    emit stats_changed();
    emit simulation_updated();
  }
}

void SimulationController::reset() {
  if (m_csv_path.isEmpty()) return;
  try {
    auto people = Simulation::load_csv(m_csv_path.toStdString());
    m_sim = std::make_unique<Simulation>(people, m_p_infect, m_p_recover);
    emit stats_changed();
    emit simulation_updated();
    qDebug() << "Reset. Nodes:" << m_sim->get_people().size();
  } catch (const std::exception& e) {
    m_sim.reset();
    qWarning() << "Reset failed:" << e.what();
    emit stats_changed();
  }
}

void SimulationController::set_infection_prob(double p) {
  m_p_infect = p;
  if (m_sim) m_sim->p_infect = p;
}
void SimulationController::set_recovery_prob(double p) {
  m_p_recover = p;
  if (m_sim) m_sim->p_recover = p;
}

int SimulationController::get_healthy_count() const { return m_sim ? (int)m_sim->get_healthy().size() : 0; }
int SimulationController::get_infected_count() const { return m_sim ? (int)m_sim->get_infected().size() : 0; }
int SimulationController::get_recovered_count() const { return m_sim ? (int)m_sim->get_recovered().size() : 0; }


QVariantList SimulationController::get_node_states() const {
  QVariantList result;
  if (!m_sim) return result;
  const auto& people = m_sim->get_people();
  result.reserve(people.size());
  for (const auto& p : people) {
    QVariantMap node;
    node["id"] = p.id;
    node["state"] = static_cast<int>(p.state);  // 0=Healthy 1=Infected 2=Recovered
    result.append(node);
  }
  return result;
}

QVariantList SimulationController::get_edges_for_nodes(const QVariantList& nodeIds) const {
  QVariantList result;
  if (!m_sim) return result;

  std::unordered_set<int> idSet;
  idSet.reserve(nodeIds.size());
  for (const auto& v : nodeIds) idSet.insert(v.toInt());

  const auto& people = m_sim->get_people();

  struct PairHash {
    size_t operator()(std::pair<int, int> p) const {
      return std::hash<long long>()(((long long)p.first << 32) | (unsigned)p.second);
    }
  };
  std::unordered_set<std::pair<int, int>, PairHash> seen;

  for (const auto& person : people) {
    if (!idSet.count(person.id)) continue;
    for (int nb : person.contacts) {
      if (!idSet.count(nb)) continue;
      int lo = std::min(person.id, nb), hi = std::max(person.id, nb);
      if (seen.insert({lo, hi}).second) {
        QVariantMap edge;
        edge["a"] = lo;
        edge["b"] = hi;
        result.append(edge);
      }
    }
  }
  return result;
}


void SimulationController::emit_search(const std::vector<int>& ids) {
  QVector<int> qids(ids.begin(), ids.end());
  emit search_results_ready(qids);
}

void SimulationController::search_healthy() {
  if (m_sim) emit_search(m_sim->get_healthy());
}
void SimulationController::search_recovered() {
  if (m_sim) emit_search(m_sim->get_recovered());
}
void SimulationController::search_recovered_lonely() {
  if (m_sim) emit_search(m_sim->recovered_with_sick_contacts());
}
void SimulationController::search_healthy_surrounded() {
  if (m_sim) emit_search(m_sim->healthy_with_all_infected_contacts());
}
void SimulationController::clear_search() { emit search_results_ready(QVector<int>{}); }

// Returns { nodes:[{id,state}], edges:[{a,b}] } — all in C++, one bridge call
QVariantMap SimulationController::get_bfs_subgraph(int maxNodes) const {
  QVariantMap result;
  if (!m_sim) return result;

  const auto& people = m_sim->get_people();
  if (people.empty()) return result;

  std::unordered_map<int, int> idToIdx;
  idToIdx.reserve(people.size());
  for (int i = 0; i < (int)people.size(); i++) idToIdx[people[i].id] = i;

  int seedIdx = 0;
  size_t bestDeg = 0;
  for (int i = 0; i < (int)people.size(); i++) {
    if (people[i].contacts.size() > bestDeg) {
      bestDeg = people[i].contacts.size();
      seedIdx = i;
    }
  }

  std::vector<int> visited(people.size(), 0);
  std::vector<int> order;
  order.reserve(maxNodes);
  std::queue<int> q;
  q.push(seedIdx);
  visited[seedIdx] = 1;

  while (!q.empty() && (int)order.size() < maxNodes) {
    int cur = q.front();
    q.pop();
    order.push_back(cur);
    for (int nb : people[cur].contacts) {
      auto it = idToIdx.find(nb);
      if (it == idToIdx.end()) continue;
      int nbIdx = it->second;
      if (!visited[nbIdx]) {
        visited[nbIdx] = 1;
        q.push(nbIdx);
      }
    }
  }

  std::unordered_map<int, int> subIdx;
  subIdx.reserve(order.size());
  for (int si = 0; si < (int)order.size(); si++) subIdx[order[si]] = si;

  QVariantList nodes;
  nodes.reserve(order.size());
  for (int idx : order) {
    QVariantMap n;
    n["id"] = people[idx].id;
    n["state"] = static_cast<int>(people[idx].state);
    nodes.append(n);
  }

  struct PairHash {
    size_t operator()(std::pair<int, int> p) const {
      return std::hash<long long>()(((long long)p.first << 32) | (unsigned)p.second);
    }
  };
  std::unordered_set<std::pair<int, int>, PairHash> seen;
  QVariantList edges;
  for (int idx : order) {
    for (int nb : people[idx].contacts) {
      auto it = idToIdx.find(nb);
      if (it == idToIdx.end()) continue;
      if (subIdx.find(it->second) == subIdx.end()) continue;
      int lo = std::min(people[idx].id, nb);
      int hi = std::max(people[idx].id, nb);
      if (seen.insert({lo, hi}).second) {
        QVariantMap e;
        e["a"] = lo;
        e["b"] = hi;
        edges.append(e);
      }
    }
  }

  result["nodes"] = nodes;
  result["edges"] = edges;
  return result;
}
