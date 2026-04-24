#include <print>
#include <charconv>
#include <cstdlib>
#include "task_runner.hpp"

static void print_usage(const char* prog) {
  std::println("Usage:");
  std::println("  {} <p> <p1> <n> <simulations>", prog);
  std::println();
  std::println("Arguments:");
  std::println("  p            - hit probability (0..1)");
  std::println("  p1           - explosion probability on 1 hit (0..1)");
  std::println("  n            - number of shots (int > 0)");
  std::println("  simulations  - number of experiments (size_t > 0)");
}

int main(int argc, char** argv) {
  if (argc != 5) {
    print_usage(argv[0]);
    return 1;
  }

  double p = std::strtod(argv[1], nullptr);
  double p1 = std::strtod(argv[2], nullptr);
  int n = std::strtol(argv[3], nullptr, 10);
  size_t simulations = static_cast<size_t>(std::strtoull(argv[4], nullptr, 10));

  auto experiment = [p, p1, n](auto& rng) {
    std::bernoulli_distribution hit(p);

    int hits = 0;
    for (int i = 0; i < n; i++) {
      if (hit(rng)) ++hits;
    }

    if (hits == 0) return false;
    if (hits >= 2) return true;

    return std::bernoulli_distribution(p1)(rng);
  };

  std::print("Barrel explosion simulation\n");
  std::print("Hit probability:                {:.2f}\n", p);
  std::print("Explosion probability on 1 hit: {:.2f}\n", p1);
  std::print("Number of shots:                {}\n", n);
  std::print("Simulations:                    {}\n\n", simulations);

  TaskRunner runner;
  auto results = runner.run(experiment, simulations);

  auto counts = tally(results);

  std::print("P(barrel explodes) = {:.6f}\n",
             static_cast<double>(counts[true]) / simulations);
  std::print("P(barrel survives) = {:.6f}\n",
             static_cast<double>(counts[false]) / simulations);
}
