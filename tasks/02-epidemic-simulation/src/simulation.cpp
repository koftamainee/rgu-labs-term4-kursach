#include "simulation.hpp"

#include <fstream>
#include <sstream>
#include <stdexcept>
#include <unordered_map>

Simulation::Simulation(const std::vector<Person>& people, double p_infect,
                       double p_recover)
    : m_people(people),
      p_infect(p_infect),
      p_recover(p_recover),
      m_dist(0.0, 1.0),
      m_rng(std::random_device{}()),
      m_current_step(0) {}

const std::vector<Person>& Simulation::step() {
    if (m_current_step == 0) {
        std::uniform_int_distribution<size_t> pick(0, m_people.size() - 1);
        m_people[pick(m_rng)].state = PersonState::Infected;
        m_current_step++;
        return m_people;
    }

    std::vector<int> newly_infected;
    for (const auto& person : m_people) {
        if (person.state != PersonState::Infected) continue;
        for (int cid : person.contacts) {
            if ((m_people[cid].state == PersonState::Recovered || m_people[cid].state
                    == PersonState::Healthy) &&
                m_dist(m_rng) < p_infect)
                newly_infected.push_back(cid);
        }
    }
    for (int id : newly_infected) m_people[id].state = PersonState::Infected;

    for (auto& person : m_people)
        if (person.state == PersonState::Infected && m_dist(m_rng) < p_recover)
            person.state = PersonState::Recovered;

    m_current_step++;
    return m_people;
}

const std::vector<Person>& Simulation::get_people() const { return m_people; }

std::vector<int> Simulation::get_healthy() const {
    std::vector<int> r;
    for (const auto& p : m_people)
        if (p.state == PersonState::Healthy) r.push_back(p.id);
    return r;
}

std::vector<int> Simulation::get_infected() const {
    std::vector<int> r;
    for (const auto& p : m_people)
        if (p.state == PersonState::Infected) r.push_back(p.id);
    return r;
}

std::vector<int> Simulation::get_recovered() const {
    std::vector<int> r;
    for (const auto& p : m_people)
        if (p.state == PersonState::Recovered) r.push_back(p.id);
    return r;
}

std::vector<int> Simulation::recovered_with_sick_contacts() const {
    std::vector<int> r;
    for (const auto& p : m_people) {
        if (p.state != PersonState::Recovered) continue;
        for (int cid : p.contacts) {
            if (m_people[cid].state != PersonState::Recovered) {
                r.push_back(p.id);
                break;
            }
        }
    }
    return r;
}

std::vector<int> Simulation::healthy_with_all_infected_contacts() const {
    std::vector<int> r;
    for (const auto& p : m_people) {
        if (p.state != PersonState::Healthy) continue;
        if (p.contacts.empty()) {
            continue;
        }
        bool all_gone = true;
        for (int cid : p.contacts) {
            if (m_people[cid].state == PersonState::Healthy || m_people[cid].state ==
                PersonState::Recovered) {
                all_gone = false;
                break;
            }
        }
        if (all_gone) r.push_back(p.id);
    }
    return r;
}

std::vector<Person> Simulation::load_csv(const std::string& csv_path) {
    std::ifstream file(csv_path);
    if (!file.is_open())
        throw std::runtime_error("Cannot open file: " + csv_path);

    std::unordered_map<int, std::vector<int>> adj;
    std::string line;
    while (std::getline(file, line)) {
        if (line.empty()) continue;
        std::stringstream ss(line);
        int a, b;
        if (!(ss >> a >> b)) continue;
        adj[a].push_back(b);
        adj[b].push_back(a);
    }

    if (adj.empty())
        throw std::runtime_error(
            "No valid edges found. Expected format: two integers per line (e.g. '0 "
            "1').");

    if (adj.size() < 2)
        throw std::runtime_error(
            "Graph has fewer than 2 nodes. Check that the file is a valid edge "
            "list.");

    size_t total_contacts = 0;
    for (auto& [id, nbrs] : adj) total_contacts += nbrs.size();
    double avg_degree = (double)total_contacts / adj.size();
    if (avg_degree < 1.0)
        throw std::runtime_error(
            "Average node degree is less than 1. File likely isn't a valid edge "
            "list.");

    std::vector<Person> people;
    people.reserve(adj.size());
    for (auto& [id, neighbours] : adj) {
        Person p;
        p.id = id;
        p.contacts = std::move(neighbours);
        people.push_back(std::move(p));
    }
    return people;
}