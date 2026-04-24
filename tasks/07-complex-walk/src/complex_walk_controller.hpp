#pragma once
#include <QFutureWatcher>
#include <QObject>
#include <QVariantList>
#include <QString>
#include <memory>
#include "complex_walk_sim.hpp"

class ComplexWalkController : public QObject {
    Q_OBJECT

    Q_PROPERTY(double  rho           READ get_rho          NOTIFY config_changed)
    Q_PROPERTY(int     n             READ get_n            NOTIFY config_changed)
    Q_PROPERTY(int     M             READ get_M            NOTIFY config_changed)
    Q_PROPERTY(int     K             READ get_K            NOTIFY config_changed)
    Q_PROPERTY(double  epsilon       READ get_epsilon      NOTIFY config_changed)
    Q_PROPERTY(QString distribution  READ get_distribution NOTIFY config_changed)

    Q_PROPERTY(int    binom_trials   READ get_binom_trials NOTIFY config_changed)
    Q_PROPERTY(double binom_p        READ get_binom_p      NOTIFY config_changed)
    Q_PROPERTY(double geom_p         READ get_geom_p       NOTIFY config_changed)
    Q_PROPERTY(double tri_a          READ get_tri_a        NOTIFY config_changed)
    Q_PROPERTY(double tri_b          READ get_tri_b        NOTIFY config_changed)
    Q_PROPERTY(double tri_c          READ get_tri_c        NOTIFY config_changed)

    Q_PROPERTY(double  return_prob   READ get_return_prob  NOTIFY batch_done)
    Q_PROPERTY(int     return_count  READ get_return_count NOTIFY batch_done)
    Q_PROPERTY(int     batch_n       READ get_batch_n      NOTIFY batch_done)
    Q_PROPERTY(bool    batch_running READ is_batch_running NOTIFY batch_running_changed)

    Q_PROPERTY(QVariantList last_path    READ get_last_path    NOTIFY trajectory_updated)
    Q_PROPERTY(bool         last_returned READ get_last_returned NOTIFY trajectory_updated)
    Q_PROPERTY(int          last_return_step READ get_last_return_step NOTIFY trajectory_updated)

public:
    explicit ComplexWalkController(QObject* parent = nullptr);

    Q_INVOKABLE void load_config(const QString& path);
    Q_INVOKABLE void run_single();
    Q_INVOKABLE void run_batch();

    Q_INVOKABLE void set_rho(double v);
    Q_INVOKABLE void set_n(int v);
    Q_INVOKABLE void set_M(int v);
    Q_INVOKABLE void set_K(int v);
    Q_INVOKABLE void set_epsilon(double v);
    Q_INVOKABLE void set_distribution(const QString& name);
    Q_INVOKABLE void set_binom_trials(int v);
    Q_INVOKABLE void set_binom_p(double v);
    Q_INVOKABLE void set_geom_p(double v);
    Q_INVOKABLE void set_tri_a(double v);
    Q_INVOKABLE void set_tri_b(double v);
    Q_INVOKABLE void set_tri_c(double v);

    double       get_rho()              const;
    int          get_n()                const;
    int          get_M()                const;
    int          get_K()                const;
    double       get_epsilon()          const;
    QString      get_distribution()     const;
    int          get_binom_trials()     const;
    double       get_binom_p()          const;
    double       get_geom_p()           const;
    double       get_tri_a()            const;
    double       get_tri_b()            const;
    double       get_tri_c()            const;
    double       get_return_prob()      const;
    int          get_return_count()     const;
    int          get_batch_n()          const;
    bool         is_batch_running()     const;
    QVariantList get_last_path()        const;
    bool         get_last_returned()    const;
    int          get_last_return_step() const;

signals:
    void config_changed();
    void batch_done();
    void batch_running_changed();
    void trajectory_updated();
    void config_loaded();

private:
    void rebuild_sim();

    WalkConfig   m_cfg;
    std::unique_ptr<ComplexWalkSimulation> m_sim;

    WalkResult   m_last_walk;
    bool         m_has_walk    = false;

    double  m_return_prob  = 0.0;
    int     m_return_count = 0;
    int     m_batch_n      = 0;
    bool    m_batch_running = false;
};
