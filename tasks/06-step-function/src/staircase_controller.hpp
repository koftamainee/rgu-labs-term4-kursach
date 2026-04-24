#pragma once
#include <QFutureWatcher>
#include <QObject>
#include <QVariantList>
#include <QString>
#include <memory>
#include "staircase_sim.hpp"

class StaircaseController : public QObject {
    Q_OBJECT

    Q_PROPERTY(int    M               READ get_M              NOTIFY config_changed)
    Q_PROPERTY(double h               READ get_h              NOTIFY config_changed)
    Q_PROPERTY(double tau             READ get_tau            NOTIFY config_changed)
    Q_PROPERTY(int    n_values        READ get_n_values       NOTIFY config_changed)
    Q_PROPERTY(QString distribution   READ get_distribution   NOTIFY config_changed)
    Q_PROPERTY(int    N_generations   READ get_N              NOTIFY config_changed)
    Q_PROPERTY(int    segment_count   READ get_segment_count  NOTIFY config_changed)

    Q_PROPERTY(int    binom_trials    READ get_binom_trials   NOTIFY config_changed)
    Q_PROPERTY(double binom_p         READ get_binom_p        NOTIFY config_changed)
    Q_PROPERTY(double geom_p          READ get_geom_p         NOTIFY config_changed)
    Q_PROPERTY(double tri_a           READ get_tri_a          NOTIFY config_changed)
    Q_PROPERTY(double tri_b           READ get_tri_b          NOTIFY config_changed)
    Q_PROPERTY(double tri_c           READ get_tri_c          NOTIFY config_changed)

    Q_PROPERTY(double increasing_prob READ get_inc_prob       NOTIFY batch_done)
    Q_PROPERTY(int    increasing_count READ get_inc_count     NOTIFY batch_done)
    Q_PROPERTY(int    batch_n         READ get_batch_n        NOTIFY batch_done)

    Q_PROPERTY(bool   batch_running   READ is_batch_running   NOTIFY batch_running_changed)
    Q_PROPERTY(int    page_count      READ get_page_count     NOTIFY batch_done)
    Q_PROPERTY(int    current_page    READ get_current_page   NOTIFY page_changed)

public:
    explicit StaircaseController(QObject* parent = nullptr);

    Q_INVOKABLE void load_config(const QString& path);
    Q_INVOKABLE void run_batch();

    Q_INVOKABLE void set_M(int v);
    Q_INVOKABLE void set_h(double v);
    Q_INVOKABLE void set_tau(double v);
    Q_INVOKABLE void set_n_values(int v);
    Q_INVOKABLE void set_distribution(const QString& name);
    Q_INVOKABLE void set_N(int v);
    Q_INVOKABLE void set_binom_trials(int v);
    Q_INVOKABLE void set_binom_p(double v);
    Q_INVOKABLE void set_geom_p(double v);
    Q_INVOKABLE void set_tri_a(double v);
    Q_INVOKABLE void set_tri_b(double v);
    Q_INVOKABLE void set_tri_c(double v);

    Q_INVOKABLE void next_page();
    Q_INVOKABLE void prev_page();
    Q_INVOKABLE void goto_page(int p);

    Q_INVOKABLE QVariantList get_page_generations(int page, int per_page) const;
    Q_INVOKABLE QVariantList get_current_page_data(int per_page) const;

    int     get_M()             const;
    double  get_h()             const;
    double  get_tau()           const;
    int     get_n_values()      const;
    QString get_distribution()  const;
    int     get_N()             const;
    int     get_segment_count() const;
    int     get_binom_trials()  const;
    double  get_binom_p()       const;
    double  get_geom_p()        const;
    double  get_tri_a()         const;
    double  get_tri_b()         const;
    double  get_tri_c()         const;
    double  get_inc_prob()      const;
    int     get_inc_count()     const;
    int     get_batch_n()       const;
    bool    is_batch_running()  const;
    int     get_page_count()    const;
    int     get_current_page()  const;

signals:
    void config_changed();
    void batch_done();
    void batch_running_changed();
    void page_changed();
    void config_loaded();

private:
    void rebuild_sim();
    void save_config(const QString& path);

    SimConfig m_cfg;
    std::unique_ptr<StaircaseSimulation> m_sim;

    std::vector<Generation> m_generations;
    int    m_inc_count     = 0;
    double m_inc_prob      = 0.0;
    int    m_batch_n       = 0;
    bool   m_batch_running = false;

    int    m_current_page  = 0;
    int    m_page_count    = 0;
    static constexpr int PER_PAGE = 6;
};
