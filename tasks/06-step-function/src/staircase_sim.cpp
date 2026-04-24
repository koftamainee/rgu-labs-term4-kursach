#include "staircase_sim.hpp"
#include <cmath>
#include <algorithm>

StaircaseSimulation::StaircaseSimulation(const SimConfig& cfg)
    : m_cfg(cfg), m_rng(std::random_device{}()) {}

int StaircaseSimulation::segment_count() const {
    return static_cast<int>(std::round(m_cfg.M / m_cfg.h));
}

double StaircaseSimulation::sample_one() {
    int n = m_cfg.n_values;
    double tau = m_cfg.tau;

    switch (m_cfg.dist) {
    case Distribution::Uniform: {
        std::uniform_int_distribution<int> d(0, n);
        return d(m_rng) * tau;
    }
    case Distribution::Binomial: {
        std::binomial_distribution<int> d(m_cfg.binom_trials, m_cfg.binom_p);
        int k = d(m_rng);
        return (k % (n + 1)) * tau;
    }
    case Distribution::FiniteGeometric: {
        double p = m_cfg.geom_p;
        std::vector<double> weights(n + 1);
        double sum = 0.0;
        for (int i = 0; i <= n; i++) {
            weights[i] = std::pow(1.0 - p, i) * p;
            sum += weights[i];
        }
        for (auto& w : weights) w /= sum;
        std::discrete_distribution<int> d(weights.begin(), weights.end());
        return d(m_rng) * tau;
    }
    case Distribution::DiscreteTriangular: {
        // Sample continuous Triangular(tri_a, tri_b, tri_c), then snap to nearest k*tau in {0..n*tau}.
        double a = m_cfg.tri_a, peak = m_cfg.tri_b, c = m_cfg.tri_c;
        if (a >= c) {
            // degenerate — fall back to uniform
            std::uniform_int_distribution<int> d(0, n);
            return d(m_rng) * tau;
        }
        peak = std::max(a, std::min(peak, c));
        std::uniform_real_distribution<double> u01(0.0, 1.0);
        double u = u01(m_rng);
        double Fc = (peak - a) / (c - a);
        double sample;
        if (u < Fc)
            sample = a + std::sqrt(u * (c - a) * (peak - a));
        else
            sample = c - std::sqrt((1.0 - u) * (c - a) * (c - peak));
        // Snap to nearest k*tau value in [0, n*tau]
        int best = static_cast<int>(std::round((sample - a) / (c - a) * n));
        best = std::max(0, std::min(best, n));
        return best * tau;
    }
    }
    return 0.0;
}

std::vector<double> StaircaseSimulation::sample_step_values() {
    int cnt = segment_count();
    std::vector<double> vals(cnt);
    for (auto& v : vals) v = sample_one();
    return vals;
}

bool StaircaseSimulation::check_strictly_increasing(const std::vector<double>& v) {
    for (size_t i = 1; i < v.size(); i++)
        if (v[i] <= v[i - 1]) return false;
    return !v.empty();
}

Generation StaircaseSimulation::run_single() {
    Generation g;
    g.steps = sample_step_values();
    g.is_strictly_increasing = check_strictly_increasing(g.steps);
    return g;
}

std::vector<Generation> StaircaseSimulation::run_batch(int n) {
    std::vector<Generation> results;
    results.reserve(n);
    for (int i = 0; i < n; i++)
        results.push_back(run_single());
    return results;
}
