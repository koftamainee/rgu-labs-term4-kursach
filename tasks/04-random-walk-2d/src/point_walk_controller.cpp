#include "point_walk_controller.hpp"
#include <QDebug>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QtConcurrent>
#include <algorithm>

struct BatchResult {
    std::vector<WalkResult> walks;
    int crossing_count;
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

PointWalkController::PointWalkController(QObject* parent) : QObject(parent) {
    rebuild_sim();
}

void PointWalkController::rebuild_sim() {
    m_sim = std::make_unique<PointWalkSimulation>(m_cfg);
}

void PointWalkController::load_config(const QString& path) {
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) { qWarning() << "Cannot open config:" << path; return; }
    QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
    f.close();
    QJsonObject obj = doc.object();

    if (obj.contains("h"))              m_cfg.h            = obj["h"].toDouble(m_cfg.h);
    if (obj.contains("Y"))              m_cfg.Y            = obj["Y"].toDouble(m_cfg.Y);
    if (obj.contains("K"))              m_cfg.K            = obj["K"].toInt(m_cfg.K);
    if (obj.contains("l"))              m_cfg.l_crossings  = obj["l"].toInt(m_cfg.l_crossings);
    if (obj.contains("N_simulations"))  m_cfg.N_sims       = obj["N_simulations"].toInt(m_cfg.N_sims);
    if (obj.contains("x_steps"))        m_cfg.x_steps      = obj["x_steps"].toInt(m_cfg.x_steps);
    if (obj.contains("distribution"))   m_cfg.dist         = dist_from_string(obj["distribution"].toString());
    if (obj.contains("binomial_trials")) m_cfg.binom_trials = obj["binomial_trials"].toInt(m_cfg.binom_trials);
    if (obj.contains("binomial_p"))      m_cfg.binom_p     = obj["binomial_p"].toDouble(m_cfg.binom_p);
    if (obj.contains("geometric_p"))     m_cfg.geom_p      = obj["geometric_p"].toDouble(m_cfg.geom_p);
    if (obj.contains("triangular_a"))    m_cfg.tri_a       = obj["triangular_a"].toDouble(m_cfg.tri_a);
    if (obj.contains("triangular_b"))    m_cfg.tri_b       = obj["triangular_b"].toDouble(m_cfg.tri_b);
    if (obj.contains("triangular_c"))    m_cfg.tri_c       = obj["triangular_c"].toDouble(m_cfg.tri_c);
    if (obj.contains("steps")) {
        QJsonArray arr = obj["steps"].toArray();
        m_cfg.steps.clear();
        for (const auto& v : arr) m_cfg.steps.push_back(v.toDouble());
    }

    m_cfg.h       = qBound(0.1, m_cfg.h, 100.0);
    m_cfg.K       = qBound(1, m_cfg.K, 200);
    m_cfg.l_crossings = qBound(0, m_cfg.l_crossings, 1000);
    m_cfg.N_sims  = qBound(10, m_cfg.N_sims, 10000);
    m_cfg.x_steps = qBound(2, m_cfg.x_steps, 500);
    m_cfg.binom_trials = qBound(1, m_cfg.binom_trials, 100);
    m_cfg.binom_p = qBound(0.01, m_cfg.binom_p, 0.99);
    m_cfg.geom_p  = qBound(0.01, m_cfg.geom_p,  0.99);
    // Ensure tri_a <= tri_b <= tri_c
    if (m_cfg.tri_a > m_cfg.tri_c) std::swap(m_cfg.tri_a, m_cfg.tri_c);
    m_cfg.tri_b = std::max(m_cfg.tri_a, std::min(m_cfg.tri_b, m_cfg.tri_c));
    if (m_cfg.steps.empty()) m_cfg.steps = {-1.0, 0.0, 1.0};

    rebuild_sim();
    m_has_walk = false;
    m_log.clear();
    m_crossing_prob = 0.0; m_crossing_count = 0; m_batch_n = 0; m_total_sims = 0;
    emit config_changed();
    emit log_updated();
    emit config_loaded();
}

void PointWalkController::push_log(const WalkResult& r, int idx) {
    LogEntry e;
    e.sim_index  = idx;
    e.crossings  = r.crossings;
    e.start_y    = r.start_y;
    e.x_steps    = (int)r.xs.size() - 1;
    e.dist_name  = dist_to_string(m_cfg.dist);
    m_log.push_front(e);
    while ((int)m_log.size() > m_cfg.K) m_log.pop_back();
}

void PointWalkController::run_single() {
    if (m_batch_running) return;
    WalkResult r = m_sim->run_single();
    m_last_walk  = r;
    m_has_walk   = true;
    m_total_sims++;
    push_log(r, m_total_sims);
    emit trajectory_updated();
    emit log_updated();
}

void PointWalkController::run_batch() {
    if (m_batch_running) return;
    m_batch_running = true;
    emit batch_running_changed();

    WalkConfig cfg = m_cfg;
    int target_l   = m_cfg.l_crossings;
    int total_prev = m_total_sims;

    auto* watcher = new QFutureWatcher<BatchResult>(this);
    connect(watcher, &QFutureWatcher<BatchResult>::finished, this, [=]() {
        BatchResult br = watcher->result();
        m_crossing_count = br.crossing_count;
        m_batch_n        = cfg.N_sims;
        m_crossing_prob  = (double)m_crossing_count / m_batch_n;

        if (!br.walks.empty()) {
            m_last_walk = br.walks.back();
            m_has_walk  = true;
        }

        int idx = total_prev;
        for (const auto& w : br.walks) {
            idx++;
            push_log(w, idx);
        }
        m_total_sims = idx;

        m_batch_running = false;
        emit batch_running_changed();
        emit batch_done();
        emit trajectory_updated();
        emit log_updated();
        watcher->deleteLater();
    });

    watcher->setFuture(QtConcurrent::run([=]() -> BatchResult {
        PointWalkSimulation sim(cfg);
        auto walks = sim.run_batch(cfg.N_sims);
        int cnt = 0;
        for (const auto& w : walks)
            if (target_l == 0 ? w.crossings == 0 : w.crossings == target_l) cnt++;
        return BatchResult{ std::move(walks), cnt };
    }));
}

void PointWalkController::set_h(double v)          { m_cfg.h = qBound(0.1, v, 100.0); rebuild_sim(); emit config_changed(); }
void PointWalkController::set_start_y(double v)    { m_cfg.Y = v; rebuild_sim(); emit config_changed(); }
void PointWalkController::set_x_steps(int v)       { m_cfg.x_steps = qBound(2, v, 500); rebuild_sim(); emit config_changed(); }
void PointWalkController::set_K(int v)             { m_cfg.K = qBound(1, v, 200); emit config_changed(); }
void PointWalkController::set_l(int v)             { m_cfg.l_crossings = qBound(0, v, 1000); emit config_changed(); }
void PointWalkController::set_N(int v)             { m_cfg.N_sims = qBound(10, v, 10000); emit config_changed(); }
void PointWalkController::set_distribution(const QString& name) {
    m_cfg.dist = dist_from_string(name);
    rebuild_sim();
    emit config_changed();
}
void PointWalkController::set_binom_trials(int v)    { m_cfg.binom_trials = qBound(1, v, 100); rebuild_sim(); emit config_changed(); }
void PointWalkController::set_binom_p(double v)      { m_cfg.binom_p = qBound(0.01, v, 0.99); rebuild_sim(); emit config_changed(); }
void PointWalkController::set_geom_p(double v)       { m_cfg.geom_p  = qBound(0.01, v, 0.99); rebuild_sim(); emit config_changed(); }
void PointWalkController::set_tri_a(double v)        { m_cfg.tri_a = v; if (m_cfg.tri_b < v) m_cfg.tri_b = v; if (m_cfg.tri_c < v) m_cfg.tri_c = v; rebuild_sim(); emit config_changed(); }
void PointWalkController::set_tri_b(double v)        { m_cfg.tri_b = qBound(m_cfg.tri_a, v, m_cfg.tri_c); rebuild_sim(); emit config_changed(); }
void PointWalkController::set_tri_c(double v)        { m_cfg.tri_c = v; if (m_cfg.tri_b > v) m_cfg.tri_b = v; if (m_cfg.tri_a > v) m_cfg.tri_a = v; rebuild_sim(); emit config_changed(); }
void PointWalkController::set_steps(const QString& csv) {
    QStringList parts = csv.split(',', Qt::SkipEmptyParts);
    std::vector<double> vals;
    for (const QString& p : parts) {
        bool ok; double d = p.trimmed().toDouble(&ok);
        if (ok) vals.push_back(d);
    }
    if (!vals.empty()) { m_cfg.steps = vals; rebuild_sim(); emit config_changed(); }
}

QVariantList PointWalkController::get_last_trajectory() const {
    if (!m_has_walk) return {};
    QVariantList pts;
    for (size_t i = 0; i < m_last_walk.xs.size(); i++) {
        QVariantMap m;
        m["x"] = m_last_walk.xs[i];
        m["y"] = m_last_walk.ys[i];
        pts.append(m);
    }
    return pts;
}

QVariantList PointWalkController::get_log_entries() const {
    QVariantList result;
    for (const auto& e : m_log) {
        QVariantMap m;
        m["sim_index"]  = e.sim_index;
        m["crossings"]  = e.crossings;
        m["start_y"]    = e.start_y;
        m["x_steps"]    = e.x_steps;
        m["dist_name"]  = e.dist_name;
        result.append(m);
    }
    return result;
}

double       PointWalkController::get_h()              const { return m_cfg.h; }
double       PointWalkController::get_start_y()        const { return m_cfg.Y; }
int          PointWalkController::get_x_steps()        const { return m_cfg.x_steps; }
int          PointWalkController::get_K()              const { return m_cfg.K; }
int          PointWalkController::get_l()              const { return m_cfg.l_crossings; }
int          PointWalkController::get_N()              const { return m_cfg.N_sims; }
QString      PointWalkController::get_distribution()   const { return dist_to_string(m_cfg.dist); }
int          PointWalkController::get_binom_trials()   const { return m_cfg.binom_trials; }
double       PointWalkController::get_binom_p()        const { return m_cfg.binom_p; }
double       PointWalkController::get_geom_p()         const { return m_cfg.geom_p; }
double       PointWalkController::get_tri_a()          const { return m_cfg.tri_a; }
double       PointWalkController::get_tri_b()          const { return m_cfg.tri_b; }
double       PointWalkController::get_tri_c()          const { return m_cfg.tri_c; }
QVariantList PointWalkController::get_step_values()    const {
    QVariantList r;
    for (double v : m_cfg.steps) r.append(v);
    return r;
}
double       PointWalkController::get_crossing_prob()  const { return m_crossing_prob; }
int          PointWalkController::get_crossing_count() const { return m_crossing_count; }
int          PointWalkController::get_batch_n()        const { return m_batch_n; }
bool         PointWalkController::is_batch_running()   const { return m_batch_running; }
