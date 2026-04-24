#include "complex_walk_sim.hpp"
#include <cmath>
#include <algorithm>

static constexpr double PI = 3.14159265358979323846;

ComplexWalkSimulation::ComplexWalkSimulation(const WalkConfig& cfg)
    : m_cfg(cfg), m_rng(std::random_device{}()) {}

int ComplexWalkSimulation::sample_xi() {
    int n = m_cfg.n;

    switch (m_cfg.dist) {
    case Distribution::Uniform: {
        std::uniform_int_distribution<int> d(0, n - 1);
        return d(m_rng);
    }
    case Distribution::Binomial: {
        std::binomial_distribution<int> d(m_cfg.binom_trials, m_cfg.binom_p);
        return d(m_rng) % n;
    }
    case Distribution::FiniteGeometric: {
        double p = m_cfg.geom_p;
        std::vector<double> weights(n);
        double sum = 0.0;
        for (int i = 0; i < n; i++) {
            weights[i] = std::pow(1.0 - p, i) * p;
            sum += weights[i];
        }
        for (auto& w : weights) w /= sum;
        std::discrete_distribution<int> d(weights.begin(), weights.end());
        return d(m_rng);
    }
    case Distribution::DiscreteTriangular: {
        // Sample continuous Triangular(tri_a, tri_b, tri_c), map onto index {0…n-1}.
        double a = m_cfg.tri_a, peak = m_cfg.tri_b, c = m_cfg.tri_c;
        if (a >= c) {
            std::uniform_int_distribution<int> d(0, n - 1);
            return d(m_rng);
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
        // Map [a, c] -> [0, n-1] and snap to nearest integer index
        int idx = static_cast<int>(std::round((sample - a) / (c - a) * (n - 1)));
        return std::max(0, std::min(idx, n - 1));
    }
    }
    return 0;
}

WalkResult ComplexWalkSimulation::run_single() {
    WalkResult r;
    r.returned     = false;
    r.return_step  = -1;

    double x = 0.0, y = 0.0;
    r.path.push_back({x, y});

    for (int k = 1; k <= m_cfg.K; k++) {
        int xi    = sample_xi();
        double angle = (2.0 * PI / m_cfg.n) * xi;
        x += m_cfg.rho * std::cos(angle);
        y += m_cfg.rho * std::sin(angle);
        r.path.push_back({x, y});

        if (k > 0 && std::sqrt(x * x + y * y) < m_cfg.epsilon) {
            r.returned    = true;
            r.return_step = k;
            break;
        }
    }
    return r;
}

std::vector<WalkResult> ComplexWalkSimulation::run_batch(int m) {
    std::vector<WalkResult> results;
    results.reserve(m);
    for (int i = 0; i < m; i++)
        results.push_back(run_single());
    return results;
}
