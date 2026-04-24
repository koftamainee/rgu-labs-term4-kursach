#pragma once
#include <QFutureWatcher>
#include <QObject>
#include <QVariantList>
#include <QString>
#include <memory>
#include <deque>
#include "point_walk_sim.hpp"

struct LogEntry {
    int    sim_index;
    int    crossings;
    double start_y;
    int    x_steps;
    QString dist_name;
};

class PointWalkController : public QObject {
    Q_OBJECT

    Q_PROPERTY(double  h              READ get_h              NOTIFY config_changed)
    Q_PROPERTY(double  start_y        READ get_start_y        NOTIFY config_changed)
    Q_PROPERTY(int     x_steps        READ get_x_steps        NOTIFY config_changed)
    Q_PROPERTY(int     K              READ get_K              NOTIFY config_changed)
    Q_PROPERTY(int     l_crossings    READ get_l              NOTIFY config_changed)
    Q_PROPERTY(int     N_sims         READ get_N              NOTIFY config_changed)
    Q_PROPERTY(QString distribution   READ get_distribution   NOTIFY config_changed)
    Q_PROPERTY(QVariantList step_values READ get_step_values  NOTIFY config_changed)

    Q_PROPERTY(int    binom_trials    READ get_binom_trials   NOTIFY config_changed)
    Q_PROPERTY(double binom_p         READ get_binom_p        NOTIFY config_changed)
    Q_PROPERTY(double geom_p          READ get_geom_p         NOTIFY config_changed)
    Q_PROPERTY(double tri_a           READ get_tri_a          NOTIFY config_changed)
    Q_PROPERTY(double tri_b           READ get_tri_b          NOTIFY config_changed)
    Q_PROPERTY(double tri_c           READ get_tri_c          NOTIFY config_changed)

    Q_PROPERTY(double  crossing_prob  READ get_crossing_prob  NOTIFY batch_done)
    Q_PROPERTY(int     crossing_count READ get_crossing_count NOTIFY batch_done)
    Q_PROPERTY(int     batch_n        READ get_batch_n        NOTIFY batch_done)
    Q_PROPERTY(bool    batch_running  READ is_batch_running   NOTIFY batch_running_changed)

    Q_PROPERTY(QVariantList last_trajectory READ get_last_trajectory NOTIFY trajectory_updated)
    Q_PROPERTY(QVariantList log_entries     READ get_log_entries     NOTIFY log_updated)

public:
    explicit PointWalkController(QObject* parent = nullptr);

    Q_INVOKABLE void load_config(const QString& path);
    Q_INVOKABLE void run_single();
    Q_INVOKABLE void run_batch();

    Q_INVOKABLE void set_h(double v);
    Q_INVOKABLE void set_start_y(double v);
    Q_INVOKABLE void set_x_steps(int v);
    Q_INVOKABLE void set_K(int v);
    Q_INVOKABLE void set_l(int v);
    Q_INVOKABLE void set_N(int v);
    Q_INVOKABLE void set_distribution(const QString& name);
    Q_INVOKABLE void set_binom_trials(int v);
    Q_INVOKABLE void set_binom_p(double v);
    Q_INVOKABLE void set_geom_p(double v);
    Q_INVOKABLE void set_tri_a(double v);
    Q_INVOKABLE void set_tri_b(double v);
    Q_INVOKABLE void set_tri_c(double v);
    Q_INVOKABLE void set_steps(const QString& csv); // e.g. "-2,-1,0,1,2"

    double       get_h()             const;
    double       get_start_y()       const;
    int          get_x_steps()       const;
    int          get_K()             const;
    int          get_l()             const;
    int          get_N()             const;
    QString      get_distribution()  const;
    int          get_binom_trials()  const;
    double       get_binom_p()       const;
    double       get_geom_p()        const;
    double       get_tri_a()         const;
    double       get_tri_b()         const;
    double       get_tri_c()         const;
    QVariantList get_step_values()   const;
    double       get_crossing_prob() const;
    int          get_crossing_count()const;
    int          get_batch_n()       const;
    bool         is_batch_running()  const;
    QVariantList get_last_trajectory()const;
    QVariantList get_log_entries()   const;

signals:
    void config_changed();
    void batch_done();
    void batch_running_changed();
    void trajectory_updated();
    void log_updated();
    void config_loaded();

private:
    void rebuild_sim();
    void push_log(const WalkResult& r, int idx);
    WalkResult result_to_trajectory(const WalkResult& r) const;

    WalkConfig   m_cfg;
    std::unique_ptr<PointWalkSimulation> m_sim;

    WalkResult   m_last_walk;
    bool         m_has_walk    = false;

    std::deque<LogEntry> m_log;

    double  m_crossing_prob  = 0.0;
    int     m_crossing_count = 0;
    int     m_batch_n        = 0;
    bool    m_batch_running  = false;
    int     m_total_sims     = 0;
};
