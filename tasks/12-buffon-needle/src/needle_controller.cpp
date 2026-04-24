#include "needle_controller.hpp"
#include <QDebug>
#include <QtConcurrent>
#include <cmath>

NeedleController::NeedleController(QObject* parent) : QObject(parent) {
    rebuild_sim();
}

void NeedleController::rebuild_sim() {
    m_sim = std::make_unique<NeedleSimulation>(m_d, m_L);
}

void NeedleController::run_batch(int n) {
    if (n <= 0 || m_batch_running) return;
    m_batch_running = true;
    emit batch_running_changed();

    double d = m_d;
    double L = m_L;

    struct BatchResult { int n; int crosses; };

    auto* watcher = new QFutureWatcher<BatchResult>(this);
    connect(watcher, &QFutureWatcher<BatchResult>::finished, this, [=]() {
        BatchResult r = watcher->result();
        m_total_count   = m_total_count + r.n;
        m_crosses_count = m_crosses_count + r.crosses;
        m_sim_prob      = (double)m_crosses_count / m_total_count;
        m_batch_running = false;
        emit batch_running_changed();
        emit batch_done();
        qDebug() << "Batch" << r.n << "sim_prob=" << m_sim_prob;
        watcher->deleteLater();
    });

    watcher->setFuture(QtConcurrent::run([=]() -> BatchResult {
        NeedleSimulation sim(d, L);
        auto results = sim.run_batch(n);
        int crosses = 0;
        for (const auto& r : results)
            if (r.crosses) crosses++;
        return { n, crosses };
    }));
}

void NeedleController::run_visual(int n) {
    if (n <= 0 || m_batch_running) return;
    m_batch_running = true;
    emit batch_running_changed();

    double d = m_d;
    double L = m_L;

    auto* watcher = new QFutureWatcher<QVector<NeedleResult>>(this);
    connect(watcher, &QFutureWatcher<QVector<NeedleResult>>::finished, this, [=]() {
        QVector<NeedleResult> pts = watcher->result();

        int crosses = 0;
        QVariantList list;
        list.reserve(pts.size());
        for (const auto& r : pts) {
            QVariantMap m;
            m["x"]       = r.x;
            m["phi"]     = r.phi;
            m["crosses"] = r.crosses;
            list.append(m);
            if (r.crosses) crosses++;
        }

        m_total_count   = m_total_count + pts.size();
        m_crosses_count = m_crosses_count + crosses;
        m_sim_prob      = (double)m_crosses_count / m_total_count;

        m_batch_running = false;
        emit batch_running_changed();
        emit batch_done();
        emit visual_ready(list);
        watcher->deleteLater();
    });

    watcher->setFuture(QtConcurrent::run([=]() -> QVector<NeedleResult> {
        NeedleSimulation sim(d, L);
        auto results = sim.run_batch(n);
        return QVector<NeedleResult>(results.begin(), results.end());
    }));
}

void NeedleController::reset() {
    m_sim_prob      = 0.0;
    m_crosses_count = 0;
    m_total_count   = 0;
    rebuild_sim();
    emit batch_done();
}

void NeedleController::set_d(double d) {
    if (d <= 0.0) return;
    m_d = d;
    reset();
    rebuild_sim();
    emit params_changed();
}

void NeedleController::set_L(double L) {
    if (L <= 0.0 || L > m_d) return;
    m_L = L;
    reset();
    rebuild_sim();
    emit params_changed();
}

double NeedleController::get_d()             const { return m_d; }
double NeedleController::get_L()             const { return m_L; }
double NeedleController::get_exact_prob()    const { return (2.0 * m_L) / (M_PI * m_d); }
double NeedleController::get_sim_prob()      const { return m_sim_prob; }
int    NeedleController::get_crosses_count() const { return m_crosses_count; }
int    NeedleController::get_total_count()   const { return m_total_count; }
double NeedleController::get_error()         const {
    if (m_total_count == 0) return 0.0;
    return std::abs(m_sim_prob - get_exact_prob());
}
bool   NeedleController::is_batch_running()  const { return m_batch_running; }
