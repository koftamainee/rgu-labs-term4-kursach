#ifndef TASK_RUNNER_HPP
#define TASK_RUNNER_HPP

#include <iostream>
#include <map>
#include <print>
#include <random>
#include <vector>

template <typename E, typename RNG>
concept Experiment =
    std::uniform_random_bit_generator<RNG> && std::invocable<E, RNG&>;

template <std::uniform_random_bit_generator RNG = std::mt19937>
class TaskRunner {
 public:
  template <Experiment<RNG> E>
  auto run(E&& experiment, size_t simulations, bool show_progress = true) {
    using result_type = std::invoke_result_t<E, RNG&>;

    std::vector<result_type> results;
    results.reserve(simulations);

    RNG rng(std::random_device{}());

    for (size_t i = 0; i < simulations; i++) {
      results.push_back(std::forward<E>(experiment)(rng));
      if (show_progress && i % 1000 == 0) {
        print_progress(i, simulations);
      }
    }

    if (show_progress) {
      std::print("\r[{:=>50}] {:>3}%\n", "", 100);
    }

    return results;
  }

 private:
  void print_progress(size_t current, size_t total) {
    int pos = static_cast<int>(50.0 * static_cast<double>(current) /
                               static_cast<double>(total));
    std::print("\r[{:=>{}}{:<{}}] {:>3}% ", "", pos, "", 50 - pos,
               100 * current / total);
    std::cout.flush();
  }
};

template <typename T>
auto tally(const std::vector<T>& results) {
  std::map<T, size_t> counts;
  for (const auto& r : results) {
    counts[r]++;
  }
  return counts;
}

#endif  // !TASK_RUNNER_HPP
