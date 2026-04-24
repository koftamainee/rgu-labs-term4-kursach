#pragma once
#include <random>
#include <vector>

struct NeedleResult {
    double x;
    double phi;
    bool crosses;
};

class NeedleSimulation {
public:
    NeedleSimulation(double d, double L);

    NeedleResult run_single();
    std::vector<NeedleResult> run_batch(int n);

    double d;
    double L;

private:
    std::mt19937 m_rng;
    std::uniform_real_distribution<double> m_dist_x;
    std::uniform_real_distribution<double> m_dist_phi;
};
