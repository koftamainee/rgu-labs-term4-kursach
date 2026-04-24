#pragma once

#include <map>
#include <nlohmann/json.hpp>
#include <string>
#include <utility>
#include <vector>

class DiscreteRandomVariable {
 public:
  DiscreteRandomVariable();
  explicit DiscreteRandomVariable(
      const std::vector<std::pair<double, double>>& data);

  static DiscreteRandomVariable from_map(const std::map<double, double>& data);

  double expectation() const;
  double variance() const;
  double skewness() const;
  double kurtosis() const;

  std::vector<std::pair<double, double>> pmf() const;
  std::vector<std::pair<double, double>> cdf() const;

  DiscreteRandomVariable operator+(const DiscreteRandomVariable& other) const;
  DiscreteRandomVariable operator*(const DiscreteRandomVariable& other) const;
  DiscreteRandomVariable operator*(double scalar) const;

  void normalize();

  void save_to_file(const std::string& path) const;
  static DiscreteRandomVariable load_from_file(const std::string& path);

 private:
  std::map<double, double> m_data;

  friend void to_json(nlohmann::json& j, const DiscreteRandomVariable& rv);
  friend void from_json(const nlohmann::json& j, DiscreteRandomVariable& rv);

  void validate() const;
};

void to_json(nlohmann::json& j, const DiscreteRandomVariable& rv);
void from_json(const nlohmann::json& j, DiscreteRandomVariable& rv);

#ifdef DISCRETE_RANDOM_VARIABLE_IMPL
#include <cmath>
#include <fstream>
#include <stdexcept>

DiscreteRandomVariable::DiscreteRandomVariable() = default;

DiscreteRandomVariable::DiscreteRandomVariable(
    const std::vector<std::pair<double, double>>& data) {
  for (const auto& [value, probability] : data) {
    m_data[value] = probability;
  }

  validate();
}

DiscreteRandomVariable DiscreteRandomVariable::from_map(
    const std::map<double, double>& data) {
  DiscreteRandomVariable rv;
  rv.m_data = data;
  rv.validate();
  return rv;
}

double DiscreteRandomVariable::expectation() const {
  double result = 0.0;

  for (const auto& [value, probability] : m_data) {
    result += value * probability;
  }

  return result;
}

double DiscreteRandomVariable::variance() const {
  double mu = expectation();
  double result = 0.0;

  for (const auto& [value, probability] : m_data) {
    double diff = value - mu;
    result += diff * diff * probability;
  }

  return result;
}

double DiscreteRandomVariable::skewness() const {
  double mu = expectation();
  double var = variance();
  double sigma = std::sqrt(var);

  if (sigma == 0.0) {
    return 0.0;
  }

  double result = 0.0;

  for (const auto& [value, probability] : m_data) {
    double diff = value - mu;
    result += diff * diff * diff * probability;
  }

  return result / (sigma * sigma * sigma);
}

double DiscreteRandomVariable::kurtosis() const {
  double mu = expectation();
  double var = variance();
  double sigma = std::sqrt(var);

  if (sigma == 0.0) {
    return -3.0;
  }

  double result = 0.0;

  for (const auto& [value, probability] : m_data) {
    double diff = value - mu;
    result += diff * diff * diff * diff * probability;
  }

  return result / (sigma * sigma * sigma * sigma) - 3.0;
}

std::vector<std::pair<double, double>> DiscreteRandomVariable::pmf() const {
  std::vector<std::pair<double, double>> result;

  result.reserve(m_data.size());
for (const auto& [value, probability] : m_data) {
    result.emplace_back(value, probability);
  }

  return result;
}

std::vector<std::pair<double, double>> DiscreteRandomVariable::cdf() const {
  std::vector<std::pair<double, double>> result;

  double cumulative = 0.0;

  for (const auto& [value, probability] : m_data) {
    cumulative += probability;
    result.emplace_back(value, cumulative);
  }

  return result;
}

DiscreteRandomVariable DiscreteRandomVariable::operator+(
    const DiscreteRandomVariable& other) const {
  std::map<double, double> result_map;

  for (const auto& [v1, p1] : m_data) {
    for (const auto& [v2, p2] : other.m_data) {
      double value = v1 + v2;
      double prob = p1 * p2;

      result_map[value] += prob;
    }
  }

  return from_map(result_map);
}

DiscreteRandomVariable DiscreteRandomVariable::operator*(
    const DiscreteRandomVariable& other) const {
  std::map<double, double> result_map;

  for (const auto& [v1, p1] : m_data) {
    for (const auto& [v2, p2] : other.m_data) {
      double value = v1 * v2;
      double prob = p1 * p2;

      result_map[value] += prob;
    }
  }

  return from_map(result_map);
}

DiscreteRandomVariable DiscreteRandomVariable::operator*(double scalar) const {
  std::map<double, double> result_map;

  for (const auto& [value, probability] : m_data) {
    result_map[value * scalar] = probability;
  }

  return from_map(result_map);
}

void DiscreteRandomVariable::normalize() {
  double sum = 0.0;

  for (const auto& probability : m_data | std::views::values) {
    sum += probability;
  }

  if (sum == 0.0) {
    throw std::runtime_error("sum of probabilities is zero");
  }

  for (auto& probability : m_data | std::views::values) {
    probability /= sum;
  }
}

void DiscreteRandomVariable::save_to_file(const std::string& path) const {
  nlohmann::json j = *this;

  std::ofstream file(path);

  if (!file.is_open()) {
    throw std::runtime_error("failed to open file");
  }

  file << j.dump(4);
}

DiscreteRandomVariable DiscreteRandomVariable::load_from_file(
    const std::string& path) {
  std::ifstream file(path);

  if (!file.is_open()) {
    throw std::runtime_error("failed to open file");
  }

  nlohmann::json j;
  file >> j;

  return j.get<DiscreteRandomVariable>();
}

void DiscreteRandomVariable::validate() const {
  double sum = 0.0;

  for (const auto& probability : m_data | std::views::values) {
    if (probability < 0.0) {
      throw std::runtime_error("negative probability");
    }

    sum += probability;
  }

  double eps = 1e-9;

  if (std::abs(sum - 1.0) > eps) {
    throw std::runtime_error("probabilities do not sum to 1");
  }
}

void to_json(nlohmann::json& j, const DiscreteRandomVariable& rv) {
  j = nlohmann::json::array();

  for (const auto& [value, probability] : rv.m_data) {
    j.push_back({{"value", value}, {"probability", probability}});
  }
}

void from_json(const nlohmann::json& j, DiscreteRandomVariable& rv) {
  std::map<double, double> data;

  for (const auto & i : j) {
    double value = i.at("value").get<double>();
    double probability = i.at("probability").get<double>();

    data[value] = probability;
  }

  rv = DiscreteRandomVariable::from_map(data);
}
#endif