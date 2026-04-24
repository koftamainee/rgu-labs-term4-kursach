#include "staircase_controller.hpp"
#include <QDebug>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QtConcurrent>
#include <algorithm>

struct BatchResult {
    std::vector<Generation> gens;
    int inc_count;
};

static Distribution dist_from_string(const QString& s) {
    if (s == "binomial")   return Distribution::Binomial;
    if (s == "geometric")  return Distribution::FiniteGeometric;
    if (s == "triangular") return Distribution::DiscreteTriangular;
    return Distribution::Uniform;
}

static QString dist_to_string(Distribution d) {
    switch (d) {
    case Distribution::Binomial:           return "binomial";
    case Distribution::FiniteGeometric:    return "geometric";
    case Distribution::DiscreteTriangular: return "triangular";
    default:                               return "uniform";
    }
}

StaircaseController::StaircaseController(QObject* parent) : QObject(parent) {
    rebuild_sim();
}

void StaircaseController::rebuild_sim() {
    m_sim = std::make_unique<StaircaseSimulation>(m_cfg);
}

void StaircaseController::load_config(const QString& path) {
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) { qWarning() << "Cannot open config:" << path; return; }
    QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
    f.close();
    QJsonObject obj = doc.object();

    if (obj.contains("M"))              m_cfg.M             = obj["M"].toInt(m_cfg.M);
    if (obj.contains("h"))              m_cfg.h             = obj["h"].toDouble(m_cfg.h);
    if (obj.contains("tau"))            m_cfg.tau           = obj["tau"].toDouble(m_cfg.tau);
    if (obj.contains("n_values"))       m_cfg.n_values      = obj["n_values"].toInt(m_cfg.n_values);
    if (obj.contains("distribution"))   m_cfg.dist          = dist_from_string(obj["distribution"].toString());
    if (obj.contains("N_generations"))  m_cfg.N_generations = obj["N_generations"].toInt(m_cfg.N_generations);
    if (obj.contains("binomial_trials")) m_cfg.binom_trials = obj["binomial_trials"].toInt(m_cfg.binom_trials);
    if (obj.contains("binomial_p"))      m_cfg.binom_p      = obj["binomial_p"].toDouble(m_cfg.binom_p);
    if (obj.contains("geometric_p"))     m_cfg.geom_p       = obj["geometric_p"].toDouble(m_cfg.geom_p);
    if (obj.contains("triangular_a"))    m_cfg.tri_a        = obj["triangular_a"].toDouble(m_cfg.tri_a);
    if (obj.contains("triangular_b"))    m_cfg.tri_b        = obj["triangular_b"].toDouble(m_cfg.tri_b);
    if (obj.contains("triangular_c"))    m_cfg.tri_c        = obj["triangular_c"].toDouble(m_cfg.tri_c);

    m_cfg.M             = qBound(1, m_cfg.M, 100);
    m_cfg.h             = qBound(0.5, m_cfg.h, (double)m_cfg.M);
    m_cfg.tau           = qBound(0.1, m_cfg.tau, 100.0);
    m_cfg.n_values      = qBound(2, m_cfg.n_values, 20);
    m_cfg.N_generations = qBound(10, m_cfg.N_generations, 10000);
    m_cfg.binom_trials  = qBound(1, m_cfg.binom_trials, 100);
    m_cfg.binom_p       = qBound(0.01, m_cfg.binom_p, 0.99);
    m_cfg.geom_p        = qBound(0.01, m_cfg.geom_p,  0.99);
    if (m_cfg.tri_a > m_cfg.tri_c) std::swap(m_cfg.tri_a, m_cfg.tri_c);
    m_cfg.tri_b         = std::max(m_cfg.tri_a, std::min(m_cfg.tri_b, m_cfg.tri_c));

    rebuild_sim();
    m_generations.clear();
    m_inc_count = 0; m_inc_prob = 0.0; m_batch_n = 0;
    m_current_page = 0; m_page_count = 0;
    emit config_changed();
    emit config_loaded();
}

void StaircaseController::run_batch() {
    if (m_batch_running) return;
    m_batch_running = true;
    emit batch_running_changed();

    SimConfig cfg = m_cfg;

    auto* watcher = new QFutureWatcher<BatchResult>(this);
    connect(watcher, &QFutureWatcher<BatchResult>::finished, this, [=]() {
        BatchResult r = watcher->result();
        m_generations  = std::move(r.gens);
        m_inc_count    = r.inc_count;
        m_batch_n      = cfg.N_generations;
        m_inc_prob     = (double)m_inc_count / m_batch_n;
        m_page_count   = (m_batch_n + PER_PAGE - 1) / PER_PAGE;
        m_current_page = 0;
        m_batch_running = false;
        emit batch_running_changed();
        emit batch_done();
        emit page_changed();
        watcher->deleteLater();
    });

    watcher->setFuture(QtConcurrent::run([=]() -> BatchResult {
        StaircaseSimulation sim(cfg);
        auto gens = sim.run_batch(cfg.N_generations);
        int cnt = 0;
        for (const auto& g : gens) if (g.is_strictly_increasing) cnt++;
        return BatchResult{ std::move(gens), cnt };
    }));
}

void StaircaseController::set_M(int v) {
    m_cfg.M = qBound(1, v, 100);
    rebuild_sim(); m_generations.clear();
    m_batch_n = 0; m_inc_count = 0; m_inc_prob = 0; m_page_count = 0; m_current_page = 0;
    emit config_changed();
}

void StaircaseController::set_h(double v) {
    m_cfg.h = qBound(0.5, v, (double)m_cfg.M);
    rebuild_sim(); m_generations.clear();
    m_batch_n = 0; m_inc_count = 0; m_inc_prob = 0; m_page_count = 0; m_current_page = 0;
    emit config_changed();
}

void StaircaseController::set_tau(double v) {
    m_cfg.tau = qBound(0.1, v, 100.0);
    rebuild_sim();
    emit config_changed();
}

void StaircaseController::set_n_values(int v) {
    m_cfg.n_values = qBound(2, v, 20);
    rebuild_sim(); m_generations.clear();
    m_batch_n = 0; m_inc_count = 0; m_inc_prob = 0; m_page_count = 0; m_current_page = 0;
    emit config_changed();
}

void StaircaseController::set_distribution(const QString& name) {
    m_cfg.dist = dist_from_string(name);
    rebuild_sim(); m_generations.clear();
    m_batch_n = 0; m_inc_count = 0; m_inc_prob = 0; m_page_count = 0; m_current_page = 0;
    emit config_changed();
}

void StaircaseController::set_N(int v) {
    m_cfg.N_generations = qBound(10, v, 10000);
    emit config_changed();
}

void StaircaseController::set_binom_trials(int v) { m_cfg.binom_trials = qBound(1, v, 100); rebuild_sim(); emit config_changed(); }
void StaircaseController::set_binom_p(double v)   { m_cfg.binom_p = qBound(0.01, v, 0.99); rebuild_sim(); emit config_changed(); }
void StaircaseController::set_geom_p(double v)    { m_cfg.geom_p  = qBound(0.01, v, 0.99); rebuild_sim(); emit config_changed(); }
void StaircaseController::set_tri_a(double v)     { m_cfg.tri_a = v; if (m_cfg.tri_b < v) m_cfg.tri_b = v; if (m_cfg.tri_c < v) m_cfg.tri_c = v; rebuild_sim(); emit config_changed(); }
void StaircaseController::set_tri_b(double v)     { m_cfg.tri_b = std::max(m_cfg.tri_a, std::min(v, m_cfg.tri_c)); rebuild_sim(); emit config_changed(); }
void StaircaseController::set_tri_c(double v)     { m_cfg.tri_c = v; if (m_cfg.tri_b > v) m_cfg.tri_b = v; if (m_cfg.tri_a > v) m_cfg.tri_a = v; rebuild_sim(); emit config_changed(); }

void StaircaseController::next_page() {
    if (m_current_page < m_page_count - 1) { m_current_page++; emit page_changed(); }
}

void StaircaseController::prev_page() {
    if (m_current_page > 0) { m_current_page--; emit page_changed(); }
}

void StaircaseController::goto_page(int p) {
    if (p >= 0 && p < m_page_count) { m_current_page = p; emit page_changed(); }
}

QVariantList StaircaseController::get_page_generations(int page, int per_page) const {
    QVariantList result;
    int start = page * per_page;
    int end   = qMin(start + per_page, (int)m_generations.size());
    for (int i = start; i < end; i++) {
        const auto& g = m_generations[i];
        QVariantMap m;
        QVariantList steps;
        for (double v : g.steps) steps.append(v);
        m["steps"]               = steps;
        m["index"]               = i;
        m["strictly_increasing"] = g.is_strictly_increasing;
        result.append(m);
    }
    return result;
}

QVariantList StaircaseController::get_current_page_data(int per_page) const {
    return get_page_generations(m_current_page, per_page);
}

int     StaircaseController::get_M()             const { return m_cfg.M; }
double  StaircaseController::get_h()             const { return m_cfg.h; }
double  StaircaseController::get_tau()           const { return m_cfg.tau; }
int     StaircaseController::get_n_values()      const { return m_cfg.n_values; }
QString StaircaseController::get_distribution()  const { return dist_to_string(m_cfg.dist); }
int     StaircaseController::get_N()             const { return m_cfg.N_generations; }
int     StaircaseController::get_segment_count() const { return (int)std::round(m_cfg.M / m_cfg.h); }
double  StaircaseController::get_inc_prob()      const { return m_inc_prob; }
int     StaircaseController::get_inc_count()     const { return m_inc_count; }
int     StaircaseController::get_batch_n()       const { return m_batch_n; }
bool    StaircaseController::is_batch_running()  const { return m_batch_running; }
int     StaircaseController::get_page_count()    const { return m_page_count; }
int     StaircaseController::get_current_page()  const { return m_current_page; }
int     StaircaseController::get_binom_trials()  const { return m_cfg.binom_trials; }
double  StaircaseController::get_binom_p()       const { return m_cfg.binom_p; }
double  StaircaseController::get_geom_p()        const { return m_cfg.geom_p; }
double  StaircaseController::get_tri_a()         const { return m_cfg.tri_a; }
double  StaircaseController::get_tri_b()         const { return m_cfg.tri_b; }
double  StaircaseController::get_tri_c()         const { return m_cfg.tri_c; }
