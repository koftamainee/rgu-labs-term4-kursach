#include "complex_walk_controller.hpp"
#include <QDebug>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QtConcurrent>
#include <algorithm>

struct BatchResult {
    std::vector<WalkResult> walks;
    int return_count;
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

ComplexWalkController::ComplexWalkController(QObject* parent) : QObject(parent) {
    rebuild_sim();
}

void ComplexWalkController::rebuild_sim() {
    m_sim = std::make_unique<ComplexWalkSimulation>(m_cfg);
}

void ComplexWalkController::load_config(const QString& path) {
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) { qWarning() << "Cannot open config:" << path; return; }
    QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
    f.close();
    QJsonObject obj = doc.object();

    if (obj.contains("rho"))             m_cfg.rho          = obj["rho"].toDouble(m_cfg.rho);
    if (obj.contains("n"))               m_cfg.n            = obj["n"].toInt(m_cfg.n);
    if (obj.contains("M"))               m_cfg.M            = obj["M"].toInt(m_cfg.M);
    if (obj.contains("K"))               m_cfg.K            = obj["K"].toInt(m_cfg.K);
    if (obj.contains("distribution"))    m_cfg.dist         = dist_from_string(obj["distribution"].toString());
    if (obj.contains("binomial_trials")) m_cfg.binom_trials = obj["binomial_trials"].toInt(m_cfg.binom_trials);
    if (obj.contains("binomial_p"))      m_cfg.binom_p      = obj["binomial_p"].toDouble(m_cfg.binom_p);
    if (obj.contains("geometric_p"))     m_cfg.geom_p       = obj["geometric_p"].toDouble(m_cfg.geom_p);
    if (obj.contains("triangular_a"))    m_cfg.tri_a        = obj["triangular_a"].toDouble(m_cfg.tri_a);
    if (obj.contains("triangular_b"))    m_cfg.tri_b        = obj["triangular_b"].toDouble(m_cfg.tri_b);
    if (obj.contains("triangular_c"))    m_cfg.tri_c        = obj["triangular_c"].toDouble(m_cfg.tri_c);
    if (obj.contains("return_epsilon"))  m_cfg.epsilon      = obj["return_epsilon"].toDouble(m_cfg.epsilon);

    m_cfg.rho     = qBound(0.01, m_cfg.rho, 100.0);
    m_cfg.n       = qBound(4, m_cfg.n, 64);
    m_cfg.M       = qBound(1, m_cfg.M, 10000);
    m_cfg.K       = qBound(1, m_cfg.K, 100000);
    m_cfg.epsilon = qBound(1e-6, m_cfg.epsilon, 1.0);
    m_cfg.binom_trials = qBound(1, m_cfg.binom_trials, 100);
    m_cfg.binom_p = qBound(0.01, m_cfg.binom_p, 0.99);
    m_cfg.geom_p  = qBound(0.01, m_cfg.geom_p,  0.99);
    if (m_cfg.tri_a > m_cfg.tri_c) std::swap(m_cfg.tri_a, m_cfg.tri_c);
    m_cfg.tri_b   = std::max(m_cfg.tri_a, std::min(m_cfg.tri_b, m_cfg.tri_c));

    rebuild_sim();
    m_has_walk = false;
    m_return_prob = 0.0; m_return_count = 0; m_batch_n = 0;
    emit config_changed();
    emit config_loaded();
}

void ComplexWalkController::run_single() {
    if (m_batch_running) return;
    m_last_walk = m_sim->run_single();
    m_has_walk  = true;
    emit trajectory_updated();
}

void ComplexWalkController::run_batch() {
    if (m_batch_running) return;
    m_batch_running = true;
    emit batch_running_changed();

    WalkConfig cfg = m_cfg;

    auto* watcher = new QFutureWatcher<BatchResult>(this);
    connect(watcher, &QFutureWatcher<BatchResult>::finished, this, [=]() {
        BatchResult br = watcher->result();
        m_return_count = br.return_count;
        m_batch_n      = cfg.M;
        m_return_prob  = (double)m_return_count / m_batch_n;
        if (!br.walks.empty()) {
            m_last_walk = br.walks.back();
            m_has_walk  = true;
        }
        m_batch_running = false;
        emit batch_running_changed();
        emit batch_done();
        emit trajectory_updated();
        watcher->deleteLater();
    });

    watcher->setFuture(QtConcurrent::run([=]() -> BatchResult {
        ComplexWalkSimulation sim(cfg);
        auto walks = sim.run_batch(cfg.M);
        int cnt = 0;
        for (const auto& w : walks) if (w.returned) cnt++;
        return BatchResult{ std::move(walks), cnt };
    }));
}

void ComplexWalkController::set_rho(double v)           { m_cfg.rho = qBound(0.01, v, 100.0); rebuild_sim(); emit config_changed(); }
void ComplexWalkController::set_n(int v)                { m_cfg.n = qBound(4, v, 64); rebuild_sim(); emit config_changed(); }
void ComplexWalkController::set_M(int v)                { m_cfg.M = qBound(1, v, 10000); emit config_changed(); }
void ComplexWalkController::set_K(int v)                { m_cfg.K = qBound(1, v, 100000); rebuild_sim(); emit config_changed(); }
void ComplexWalkController::set_epsilon(double v)       { m_cfg.epsilon = qBound(1e-6, v, 1.0); rebuild_sim(); emit config_changed(); }
void ComplexWalkController::set_distribution(const QString& s) { m_cfg.dist = dist_from_string(s); rebuild_sim(); emit config_changed(); }
void ComplexWalkController::set_binom_trials(int v)    { m_cfg.binom_trials = qBound(1, v, 100); rebuild_sim(); emit config_changed(); }
void ComplexWalkController::set_binom_p(double v)      { m_cfg.binom_p = qBound(0.01, v, 0.99); rebuild_sim(); emit config_changed(); }
void ComplexWalkController::set_geom_p(double v)       { m_cfg.geom_p  = qBound(0.01, v, 0.99); rebuild_sim(); emit config_changed(); }
void ComplexWalkController::set_tri_a(double v)        { m_cfg.tri_a = v; if (m_cfg.tri_b < v) m_cfg.tri_b = v; if (m_cfg.tri_c < v) m_cfg.tri_c = v; rebuild_sim(); emit config_changed(); }
void ComplexWalkController::set_tri_b(double v)        { m_cfg.tri_b = std::max(m_cfg.tri_a, std::min(v, m_cfg.tri_c)); rebuild_sim(); emit config_changed(); }
void ComplexWalkController::set_tri_c(double v)        { m_cfg.tri_c = v; if (m_cfg.tri_b > v) m_cfg.tri_b = v; if (m_cfg.tri_a > v) m_cfg.tri_a = v; rebuild_sim(); emit config_changed(); }

QVariantList ComplexWalkController::get_last_path() const {
    if (!m_has_walk) return {};
    QVariantList pts;
    for (const auto& p : m_last_walk.path) {
        QVariantMap m;
        m["x"] = p.x;
        m["y"] = p.y;
        pts.append(m);
    }
    return pts;
}

double  ComplexWalkController::get_rho()              const { return m_cfg.rho; }
int     ComplexWalkController::get_n()                const { return m_cfg.n; }
int     ComplexWalkController::get_M()                const { return m_cfg.M; }
int     ComplexWalkController::get_K()                const { return m_cfg.K; }
double  ComplexWalkController::get_epsilon()          const { return m_cfg.epsilon; }
QString ComplexWalkController::get_distribution()     const { return dist_to_string(m_cfg.dist); }
double  ComplexWalkController::get_return_prob()      const { return m_return_prob; }
int     ComplexWalkController::get_return_count()     const { return m_return_count; }
int     ComplexWalkController::get_batch_n()          const { return m_batch_n; }
bool    ComplexWalkController::is_batch_running()     const { return m_batch_running; }
bool    ComplexWalkController::get_last_returned()    const { return m_has_walk && m_last_walk.returned; }
int     ComplexWalkController::get_last_return_step() const { return m_has_walk ? m_last_walk.return_step : -1; }
int     ComplexWalkController::get_binom_trials()     const { return m_cfg.binom_trials; }
double  ComplexWalkController::get_binom_p()          const { return m_cfg.binom_p; }
double  ComplexWalkController::get_geom_p()           const { return m_cfg.geom_p; }
double  ComplexWalkController::get_tri_a()            const { return m_cfg.tri_a; }
double  ComplexWalkController::get_tri_b()            const { return m_cfg.tri_b; }
double  ComplexWalkController::get_tri_c()            const { return m_cfg.tri_c; }
