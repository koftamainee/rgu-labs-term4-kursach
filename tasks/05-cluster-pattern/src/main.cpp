#include <iostream>
#include <utility>
#include <vector>
#include <string>
#include <random>
#include <map>
#include <iomanip>
#include <ranges>

class ClusterSimulator {
private:
  int m_clusters_count;
  int m_cells_per_cluster;
  int m_pattern_length;
  std::string m_pattern;
  std::string m_alphabet;
  std::map<char, double> m_probabilities;

  std::vector<std::string> m_clusters;
  std::mt19937 m_generator;

public:
  ClusterSimulator(int clusters_count, int cells_per_cluster,
                   int pattern_length,
                   std::string pattern, std::string alphabet,
                   const std::map<char, double>& probabilities)
    : m_clusters_count(clusters_count), m_cells_per_cluster(cells_per_cluster),
      m_pattern_length(pattern_length), m_pattern(std::move(pattern)),
      m_alphabet(std::move(alphabet)),
      m_probabilities(probabilities), m_generator(std::random_device{}()) {
    if (m_pattern.length() != m_pattern_length) {
      throw std::invalid_argument("Pattern length does not match k");
    }

    double sum = 0.0;
    for (const auto& prob : m_probabilities | std::views::values) {
      sum += prob;
    }
    if (std::abs(sum - 1.0) > 1e-6) {
      throw std::invalid_argument("Sum of probabilities must equal 1");
    }
  }

  std::string generate_cluster() {
    std::string cluster;
    std::vector<double> cumulative_probabilities;
    std::vector<char> symbols;

    double cumulative = 0.0;
    for (const auto& [first, second] : m_probabilities) {
      cumulative += second;
      cumulative_probabilities.push_back(cumulative);
      symbols.push_back(first);
    }

    std::uniform_real_distribution<> distribution(0.0, 1.0);

    for (int i = 0; i < m_cells_per_cluster; ++i) {
      const double random_value = distribution(m_generator);
      for (size_t j = 0; j < cumulative_probabilities.size(); ++j) {
        if (random_value < cumulative_probabilities[j]) {
          cluster += symbols[j];
          break;
        }
      }
    }

    return cluster;
  }

  void generate_all_clusters() {
    m_clusters.clear();
    for (int i = 0; i < m_clusters_count; ++i) {
      m_clusters.push_back(generate_cluster());
    }
  }

  bool are_connected(const std::string& left_cluster,
                     const std::string& right_cluster) const {
    for (int left_length = 1; left_length <= m_cells_per_cluster && left_length
                              < m_pattern_length; ++left_length) {
      for (int right_length = 1;
           right_length <= m_cells_per_cluster && right_length <
           m_pattern_length; ++
           right_length) {
        if (left_length + right_length != m_pattern_length) continue;

        std::string left_part = left_cluster.substr(
            m_cells_per_cluster - left_length, left_length);
        std::string right_part = right_cluster.substr(0, right_length);

        if (left_part + right_part == m_pattern) {
          return true;
        }
      }
    }
    return false;
  }

  std::vector<int> find_connected_pairs() const {
    std::vector<int> connected_pairs;
    for (int i = 0; i < m_clusters_count - 1; ++i) {
      if (are_connected(m_clusters[i], m_clusters[i + 1])) {
        connected_pairs.push_back(i);
      }
    }
    return connected_pairs;
  }

  int count_connected_pairs() const {
    int count = 0;
    for (int i = 0; i < m_clusters_count - 1; ++i) {
      if (are_connected(m_clusters[i], m_clusters[i + 1])) {
        count++;
      }
    }
    return count;
  }

  double probability_all_connected() const {
    const int connected_pairs = count_connected_pairs();
    return (connected_pairs == m_clusters_count - 1) ? 1.0 : 0.0;
  }

  double probability_d_connected(int d) const {
    const int connected_pairs = count_connected_pairs();
    return (connected_pairs == d) ? 1.0 : 0.0;
  }

  double probability_all_disconnected() const {
    const int connected_pairs = count_connected_pairs();
    return (connected_pairs == 0) ? 1.0 : 0.0;
  }

  void simulate_empirical(int experiments_count) {
    std::map<int, int> d_counts;
    int all_connected_count = 0;
    int all_disconnected_count = 0;

    for (int exp = 0; exp < experiments_count; ++exp) {
      generate_all_clusters();
      int connected_pairs = count_connected_pairs();

      d_counts[connected_pairs]++;

      if (connected_pairs == m_clusters_count - 1) {
        all_connected_count++;
      }
      if (connected_pairs == 0) {
        all_disconnected_count++;
      }

      if (exp == 0) {
        std::cout << "\nGenerated clusters (first experiment):\n";
        for (size_t i = 0; i < m_clusters.size(); ++i) {
          std::cout << "Cluster " << i + 1 << ": " << m_clusters[i] << "\n";
        }

        std::cout << "\nConnected pairs:\n";
        auto connected = find_connected_pairs();
        for (const int idx : connected) {
          std::cout << "Pairs " << idx + 1 << " and " << idx + 2 <<
              " are connected\n";
          std::cout << "  " << m_clusters[idx] << " and " << m_clusters[idx + 1]
              << "\n";
        }
        if (connected.empty()) {
          std::cout << "No connected pairs\n";
        }
      }
    }

    std::cout << "\n========== SIMULATION RESULTS ==========\n";
    std::cout << "Parameters: M=" << m_clusters_count << ", n=" <<
        m_cells_per_cluster
        << ", k=" << m_pattern_length << ", pattern='" << m_pattern << "'\n";
    std::cout << "Alphabet: " << m_alphabet << "\n";
    std::cout << "Probability distribution:\n";
    for (const auto& [first, second] : m_probabilities) {
      std::cout << "  P('" << first << "') = " << second << "\n";
    }
    std::cout << "Number of experiments: " << experiments_count << "\n\n";

    const double prob_all_connected =
        static_cast<double>(all_connected_count) / experiments_count;
    std::cout << "a. Probability of all clusters being connected: "
        << prob_all_connected << " (" << all_connected_count << "/" <<
        experiments_count << ")\n";

    std::cout << "\nb. Probability distribution for D connected pairs:\n";
    for (int d = 0; d <= m_clusters_count - 1; ++d) {
      const double prob = static_cast<double>(d_counts[d]) / experiments_count;
      if (prob > 0) {
        std::cout << "  P(D=" << d << ") = " << prob
            << " (" << d_counts[d] << "/" << experiments_count << ")\n";
      }
    }

    const double prob_all_disconnected =
        static_cast<double>(all_disconnected_count) / experiments_count;
    std::cout << "\nc. Probability of all clusters being disconnected: "
        << prob_all_disconnected << " (" << all_disconnected_count << "/" <<
        experiments_count << ")\n";
  }

  const std::vector<std::string>& get_clusters() const {
    return m_clusters;
  }
};

int main() {
  try {
    int clusters_count = 10;
    int cells_per_cluster = 5;
    int pattern_length = 3;
    std::string pattern = "101";
    std::string alphabet = "01";

    std::map<char, double> probabilities;
    probabilities['0'] = 0.5;
    probabilities['1'] = 0.5;

    std::cout << "Cluster Connectivity Simulation\n";
    std::cout << "======================================\n";

    ClusterSimulator simulator(clusters_count, cells_per_cluster,
                               pattern_length,
                               pattern, alphabet, probabilities);

    int experiments_count = 1000000;
    simulator.simulate_empirical(experiments_count);

    std::cout << "\n\n======================================\n";
    std::cout << "Additional example with non-uniform distribution:\n";

    std::map<char, double> probabilities2;
    probabilities2['0'] = 0.3;
    probabilities2['1'] = 0.7;

    ClusterSimulator simulator2(clusters_count, cells_per_cluster,
                                pattern_length,
                                pattern, alphabet, probabilities2);
    simulator2.simulate_empirical(experiments_count);

    std::cout << "\n\n======================================\n";
    std::cout << "Example with different pattern '111':\n";

    ClusterSimulator simulator3(clusters_count, cells_per_cluster, 3, "111",
                                alphabet, probabilities);
    simulator3.simulate_empirical(experiments_count);
  } catch (const std::exception& e) {
    std::cerr << "Error: " << e.what() << std::endl;
    return 1;
  }

  return 0;
}