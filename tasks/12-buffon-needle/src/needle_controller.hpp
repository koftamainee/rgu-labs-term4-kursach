#pragma once
#include <QFutureWatcher>
#include <QObject>
#include <QVariantList>
#include <QVector>
#include <memory>
#include "needle_simulation.hpp"

class NeedleController : public QObject {
    Q_OBJECT

    Q_PROPERTY(double d             READ get_d              NOTIFY params_changed)
    Q_PROPERTY(double l             READ get_L              NOTIFY params_changed)
    Q_PROPERTY(double exact_prob    READ get_exact_prob     NOTIFY params_changed)

    Q_PROPERTY(double sim_prob      READ get_sim_prob       NOTIFY batch_done)
    Q_PROPERTY(int    crosses_count READ get_crosses_count  NOTIFY batch_done)
    Q_PROPERTY(int    total_count   READ get_total_count    NOTIFY batch_done)
    Q_PROPERTY(double error         READ get_error          NOTIFY batch_done)

    Q_PROPERTY(bool   batch_running READ is_batch_running   NOTIFY batch_running_changed)

public:
    explicit NeedleController(QObject* parent = nullptr);

    Q_INVOKABLE void run_batch(int n);
    Q_INVOKABLE void run_visual(int n);
    Q_INVOKABLE void reset();

    Q_INVOKABLE void set_d(double d);
    Q_INVOKABLE void set_L(double L);

    double get_d()             const;
    double get_L()             const;
    double get_exact_prob()    const;
    double get_sim_prob()      const;
    int    get_crosses_count() const;
    int    get_total_count()   const;
    double get_error()         const;
    bool   is_batch_running()  const;

signals:
    void params_changed();
    void batch_done();
    void batch_running_changed();
    void visual_ready(QVariantList needles);

private:
    void rebuild_sim();

    double m_d = 1.0;
    double m_L = 0.7;

    std::unique_ptr<NeedleSimulation> m_sim;

    double m_sim_prob      = 0.0;
    int    m_crosses_count = 0;
    int    m_total_count   = 0;
    bool   m_batch_running = false;
};
