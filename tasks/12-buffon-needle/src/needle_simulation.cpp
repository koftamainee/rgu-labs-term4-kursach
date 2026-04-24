#include "needle_simulation.hpp"
#include <cmath>

NeedleSimulation::NeedleSimulation(double d, double L)
    : d(d), L(L),
      m_rng(std::random_device{}()),
      m_dist_x(0.0, d / 2.0),
      m_dist_phi(0.0, M_PI / 2.0) {}

NeedleResult NeedleSimulation::run_single() {
    double x   = m_dist_x(m_rng);
    double phi = m_dist_phi(m_rng);
    bool crosses = x <= (L / 2.0) * std::sin(phi);
    return { x, phi, crosses };
}

std::vector<NeedleResult> NeedleSimulation::run_batch(int n) {
    std::vector<NeedleResult> results;
    results.reserve(n);
    for (int i = 0; i < n; i++)
        results.push_back(run_single());
    return results;
}
