#pragma once
#include <QVariantList>
#include <QString>
#include <vector>
#include <random>

enum class Distribution { Uniform, Binomial, FiniteGeometric, DiscreteTriangular };

struct SimConfig {
    int    M              = 10;
    double h              = 1.0;
    double tau            = 1.0;
    int    n_values       = 5;
    Distribution dist     = Distribution::Uniform;
    int    N_generations  = 200;
    int    binom_trials   = 4;
    double binom_p        = 0.5;
    double geom_p         = 0.4;
    double tri_a          = 0.0;   // triangular min
    double tri_b          = 0.5;   // triangular peak (mode)
    double tri_c          = 1.0;   // triangular max
};

struct Generation {
    std::vector<double> steps;
    bool is_strictly_increasing;
};

class StaircaseSimulation {
public:
    explicit StaircaseSimulation(const SimConfig& cfg);

    std::vector<double> sample_step_values();
    Generation          run_single();
    std::vector<Generation> run_batch(int n);

    static bool check_strictly_increasing(const std::vector<double>& v);

    const SimConfig& config() const { return m_cfg; }

private:
    SimConfig    m_cfg;
    std::mt19937 m_rng;

    int    segment_count() const;
    double sample_one();
};
