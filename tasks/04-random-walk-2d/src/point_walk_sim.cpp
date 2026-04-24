#include "point_walk_sim.hpp"
#include <cmath>
#include <algorithm>

PointWalkSimulation::PointWalkSimulation(const WalkConfig& cfg)
    : m_cfg(cfg), m_rng(std::random_device{}()) {}

double PointWalkSimulation::sample_step() {
    int n = (int)m_cfg.steps.size() - 1;
    if (n < 0) return 0.0;

    switch (m_cfg.dist) {
    case Distribution::Uniform: {
        std::uniform_int_distribution<int> d(0, n);
        return m_cfg.steps[d(m_rng)];
    }
    case Distribution::Binomial: {
        std::binomial_distribution<int> d(m_cfg.binom_trials, m_cfg.binom_p);
        int k = d(m_rng) % (n + 1);
        return m_cfg.steps[k];
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
        return m_cfg.steps[d(m_rng)];
    }
    case Distribution::DiscreteTriangular: {
        // Sample from continuous Triangular(a, b, c) then snap to nearest step value.
        // CDF inversion: F_c = (c-a)/(b-a) is the breakpoint.
        double a = m_cfg.tri_a, peak = m_cfg.tri_b, c = m_cfg.tri_c;
        if (a >= c) { // degenerate — fall back to uniform
            std::uniform_int_distribution<int> d(0, n);
            return m_cfg.steps[d(m_rng)];
        }
        // Clamp peak to [a, c]
        peak = std::max(a, std::min(peak, c));
        std::uniform_real_distribution<double> u01(0.0, 1.0);
        double u = u01(m_rng);
        double Fc = (peak - a) / (c - a);
        double sample;
        if (u < Fc)
            sample = a + std::sqrt(u * (c - a) * (peak - a));
        else
            sample = c - std::sqrt((1.0 - u) * (c - a) * (c - peak));
        // Snap to nearest step value
        int best = 0;
        double bestDist = std::abs(m_cfg.steps[0] - sample);
        for (int i = 1; i <= n; i++) {
            double d = std::abs(m_cfg.steps[i] - sample);
            if (d < bestDist) { bestDist = d; best = i; }
        }
        return m_cfg.steps[best];
    }
    }
    return 0.0;
}

int PointWalkSimulation::count_crossings(const std::vector<double>& ys) {
    int cnt = 0;
    for (size_t i = 1; i < ys.size(); i++) {
        double a = ys[i - 1];
        double b = ys[i];
        if (a == 0.0 && b != 0.0) { cnt++; continue; }
        if (b == 0.0) { cnt++; continue; }
        if ((a > 0.0) != (b > 0.0)) cnt++;
    }
    return cnt;
}

WalkResult PointWalkSimulation::run_single() {
    WalkResult r;
    r.start_y = m_cfg.Y;
    int steps = m_cfg.x_steps;
    r.xs.reserve(steps + 1);
    r.ys.reserve(steps + 1);

    double x = 0.0, y = m_cfg.Y;
    r.xs.push_back(x);
    r.ys.push_back(y);
    for (int i = 0; i < steps; i++) {
        x += m_cfg.h;
        y += sample_step();
        r.xs.push_back(x);
        r.ys.push_back(y);
    }
    r.crossings = count_crossings(r.ys);
    return r;
}

std::vector<WalkResult> PointWalkSimulation::run_batch(int n) {
    std::vector<WalkResult> results;
    results.reserve(n);
    for (int i = 0; i < n; i++)
        results.push_back(run_single());
    return results;
}
