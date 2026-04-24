#pragma once
#include <vector>
#include <string>
#include <random>

enum class Distribution { Uniform, Binomial, FiniteGeometric, DiscreteTriangular };

struct WalkConfig {
    double              h            = 1.0;
    double              Y            = 0.0;
    std::vector<double> steps        = {-2.0, -1.0, 0.0, 1.0, 2.0};
    int                 K            = 20;
    int                 l_crossings  = 2;
    int                 N_sims       = 500;
    Distribution        dist         = Distribution::Uniform;
    int                 binom_trials = 4;
    double              binom_p      = 0.5;
    double              geom_p       = 0.4;
    double              tri_a        = 0.0;   // triangular min
    double              tri_b        = 0.5;   // triangular peak (mode)
    double              tri_c        = 1.0;   // triangular max
    int                 x_steps      = 30;
};

struct WalkResult {
    std::vector<double> xs;
    std::vector<double> ys;
    int                 crossings;
    double              start_y;
};

class PointWalkSimulation {
public:
    explicit PointWalkSimulation(const WalkConfig& cfg);

    WalkResult              run_single();
    std::vector<WalkResult> run_batch(int n);

    const WalkConfig& config() const { return m_cfg; }

private:
    WalkConfig   m_cfg;
    std::mt19937 m_rng;

    double sample_step();
    static int count_crossings(const std::vector<double>& ys);
};
