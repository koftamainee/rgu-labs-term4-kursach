#include <print>
#include "task_runner.hpp"
#include <string>

int main(int argc, char *argv[]) {
  int n = 10;
  int k = 3;
  size_t simulations = 1e7;

  if (argc != 4) {
    std::println("Usage: {} <n> <k> <experiments>", argv[0]);
    return 1;
  }

  n = std::stoi(argv[1]);
  k = std::stoi(argv[2]);
  simulations = std::stoi(argv[3]);

  auto experiment = [n, k](auto& rng) -> std::pair<bool, bool> {
    std::uniform_int_distribution<int> coin_dist(0, n - 1);
    std::bernoulli_distribution fair(0.5);

    int coin = coin_dist(rng);
    bool double_headed = coin < k;

    bool first = double_headed ? true : fair(rng);
    bool second = double_headed ? true : fair(rng);
    bool third = double_headed ? true : fair(rng);
    bool fourth = double_headed ? true : fair(rng);

    bool first_three = first && second && third;
    return {first_three, first_three && fourth};
  };

  TaskRunner runner;
  auto results = runner.run(experiment, simulations);
  std::println();

  size_t three_heads = 0;
  size_t four_heads = 0;
  for (const auto& [cond, full] : results) {
    if (cond) ++three_heads;
    if (full) ++four_heads;
  }

  std::print("Coins in wallet:        {}\n", n);
  std::print("Double-headed coins:    {}\n", k);
  std::print("Simulations:            {}\n\n", simulations);
  std::print("P(4th heads | first 3 heads) = {:.6f}\n",
             static_cast<double>(four_heads) / three_heads);
}
