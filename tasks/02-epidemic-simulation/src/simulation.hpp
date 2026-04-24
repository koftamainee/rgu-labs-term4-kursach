#pragma once
#include <random>
#include <vector>

enum class PersonState { Healthy, Infected, Recovered };

struct Person {
  int id;
  PersonState state = PersonState::Healthy;
  std::vector<int> contacts;
};

class Simulation {
 public:
  Simulation(const std::vector<Person>& people, double p_infect, double p_recover);
  const std::vector<Person>& step();
  const std::vector<Person>& get_people() const;
  std::vector<int> get_healthy() const;
  std::vector<int> get_infected() const;
  std::vector<int> get_recovered() const;
  std::vector<int> recovered_with_sick_contacts() const;
  std::vector<int> healthy_with_all_infected_contacts() const;
  static std::vector<Person> load_csv(const std::string& csv_path);

  double p_infect;
  double p_recover;

 private:
  std::mt19937 m_rng;
  std::uniform_real_distribution<double> m_dist;
  std::vector<Person> m_people;
  size_t m_current_step;
};
