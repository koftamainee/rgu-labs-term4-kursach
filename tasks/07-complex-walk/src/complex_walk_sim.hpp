#pragma once
#include <vector>
#include <random>

enum class Distribution { Uniform, Binomial, FiniteGeometric, DiscreteTriangular };

struct WalkConfig {
    double       rho          = 1.0;
    int          n            = 4;
    int          M            = 100;
    int          K            = 200;
    Distribution dist         = Distribution::Uniform;
    int          binom_trials = 6;
    double       binom_p      = 0.5;
    double       geom_p       = 0.4;
    double       tri_a        = 0.0;   // triangular min
    double       tri_b        = 0.5;   // triangular peak (mode)
    double       tri_c        = 1.0;   // triangular max
    double       epsilon      = 0.01;
};

struct Point2D { double x; double y; };

struct WalkResult {
    std::vector<Point2D> path;
    bool                 returned;
    int                  return_step;
};

class ComplexWalkSimulation {
public:
    explicit ComplexWalkSimulation(const WalkConfig& cfg);

    WalkResult              run_single();
    std::vector<WalkResult> run_batch(int m);

    const WalkConfig& config() const { return m_cfg; }

private:
    WalkConfig   m_cfg;
    std::mt19937 m_rng;

    int sample_xi();
};
