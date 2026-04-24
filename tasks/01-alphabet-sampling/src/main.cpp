#include <cstdlib>
#include <numeric>
#include <print>
#include <random>
#include <vector>

#include "task_runner.hpp"

struct Outcome {
  bool first_even;
  bool second_even;
};

int main(int argc, char** argv) {
  if (argc < 3) {
    std::print("Usage: {} <alphabet_size> <experiments>\n", argv[0]);
    return 1;
  }

  size_t alphabet_size = std::stoul(argv[1]);
  size_t experiments = std::stoul(argv[2]);

  TaskRunner runner;

  auto experiment_fixed_indices = [alphabet_size](auto& rng) {
    std::uniform_int_distribution<size_t> dist1(1, alphabet_size);
    size_t first = dist1(rng);

    std::vector<size_t> remaining;
    remaining.reserve(alphabet_size - 1);
    for (size_t i = 1; i <= alphabet_size; i++) {
      if (i != first) {
        remaining.push_back(i);
      }
    }

    std::uniform_int_distribution<size_t> dist2(0, remaining.size() - 1);
    size_t second = remaining[dist2(rng)];

    return Outcome{first % 2 == 0, second % 2 == 0};
  };

  auto experiment_reindexed = [alphabet_size](auto& rng) {
    std::vector<size_t> indices(alphabet_size);
    std::iota(indices.begin(), indices.end(), 1);

    std::uniform_int_distribution<size_t> dist1(0, indices.size() - 1);
    size_t first_pos = dist1(rng);
    bool first_even = (first_pos + 1) % 2 == 0;

    indices.erase(indices.begin() + first_pos);

    std::uniform_int_distribution<size_t> dist2(0, indices.size() - 1);
    size_t second_pos = dist2(rng);
    bool second_even = (second_pos + 1) % 2 == 0;

    return Outcome{first_even, second_even};
  };

  std::print("Running fixed experiment...\n");
  auto results_fixed = runner.run(experiment_fixed_indices, experiments);

  std::print("Running reindexed experiment...\n");
  auto results_reindexed = runner.run(experiment_reindexed, experiments);

  auto summarize = [&](const std::vector<Outcome>& results) {
    size_t first_even = 0;
    size_t second_even = 0;
    size_t both_even = 0;

    for (const auto& r : results) {
      if (r.first_even) {
        first_even++;
      }
      if (r.second_even) {
        second_even++;
      }
      if (r.first_even && r.second_even) {
        both_even++;
      }
    }

    std::print("First even:  {:.6f}\n", double(first_even) / results.size());
    std::print("Second even: {:.6f}\n", double(second_even) / results.size());
    std::print("Both even:   {:.6f}\n", double(both_even) / results.size());
  };

  std::print("\nFixed indices experiment\n");
  summarize(results_fixed);

  std::print("\nReindexed after first draw experiment\n");
  summarize(results_reindexed);

  if (alphabet_size % 2 == 0) {
    std::print(
        "\nAlphabet size is even (N = {}).\n"
        "There are exactly N/2 even and N/2 odd indices initially.\n"
        "First draw: probability of even index is (N/2)/N = 0.5.\n"
        "Second draw (fixed indices): parity balance is preserved, probability "
        "stays close to 0.5.\n"
        "Second draw (reindexed): after removal, N-1 is odd, so there are "
        "(N-2)/2 even positions.\n"
        "Probability of even index becomes ((N-2)/2)/(N-1) < 0.5.\n"
        "Probability of both draws being even is (N/2)/N * ((N/2)-1)/(N-1).\n",
        alphabet_size);
  } else {
    std::print(
        "\nAlphabet size is odd (N = {}).\n"
        "There are (N-1)/2 even and (N+1)/2 odd indices initially.\n"
        "First draw: probability of even index is ((N-1)/2)/N < 0.5.\n"
        "Second draw (fixed indices): probabilities depend on which parity was "
        "removed,\n"
        "but average probability stays close to 0.5 for large N.\n"
        "Second draw (reindexed): N-1 is even, so exactly (N-1)/2 even "
        "positions exist.\n"
        "Probability of even index becomes 0.5.\n"
        "Probability of both draws being even is ((N-1)/2)/N * "
        "(((N-1)/2)-1)/(N-1).\n",
        alphabet_size);
  }
}
