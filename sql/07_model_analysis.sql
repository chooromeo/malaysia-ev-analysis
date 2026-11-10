-- Compare EV registrations by maker and model.
WITH model_totals AS (
    SELECT
        maker,
        model,
        COUNT(*) FILTER (
            WHERE date_reg >= DATE '2025-01-01'
              AND date_reg < DATE '2025-10-01'
        ) AS ev_2025,
        COUNT(*) FILTER (
            WHERE date_reg >= DATE '2026-01-01'
              AND date_reg < DATE '2026-10-01'
        ) AS ev_2026
    FROM public.car_registrations_clean
    WHERE fuel = 'electric'
      AND (
          (date_reg >= DATE '2025-01-01'
           AND date_reg < DATE '2025-10-01')
          OR
          (date_reg >= DATE '2026-01-01'
           AND date_reg < DATE '2026-10-01')
      )
    GROUP BY maker, model
)
SELECT
    maker,
    model,
    ev_2025,
    ev_2026,
    ev_2026 - ev_2025 AS ev_change,
    ROUND(
        100.0 * (ev_2026 - ev_2025)
        / NULLIF(ev_2025, 0),
        2
    ) AS ev_yoy_pct
FROM model_totals
ORDER BY ev_change DESC, maker, model;


WITH model_totals AS (
    SELECT
        maker,
        model,
        COUNT(*) FILTER (
            WHERE date_reg >= DATE '2025-01-01'
              AND date_reg < DATE '2025-10-01'
        ) AS ev_2025,
        COUNT(*) FILTER (
            WHERE date_reg >= DATE '2026-01-01'
              AND date_reg < DATE '2026-10-01'
        ) AS ev_2026
    FROM public.car_registrations_clean
    WHERE fuel = 'electric'
      AND (
          (date_reg >= DATE '2025-01-01'
           AND date_reg < DATE '2025-10-01')
          OR
          (date_reg >= DATE '2026-01-01'
           AND date_reg < DATE '2026-10-01')
      )
    GROUP BY maker, model
)
-- Reconcile model totals with the national EV overview.
SELECT
    COUNT(*) AS maker_model_count,
    SUM(ev_2025) AS total_ev_2025,
    SUM(ev_2026) AS total_ev_2026,
    SUM(ev_2026 - ev_2025) AS total_ev_change,
    SUM(ev_2025) - 26928 AS difference_2025,
    SUM(ev_2026) - 53537 AS difference_2026,
    SUM(ev_2026 - ev_2025) - 26609 AS difference_change
FROM model_totals;


WITH model_totals AS (
    SELECT
        maker,
        model,
        COUNT(*) FILTER (
            WHERE date_reg >= DATE '2025-01-01'
              AND date_reg < DATE '2025-10-01'
        ) AS ev_2025,
        COUNT(*) FILTER (
            WHERE date_reg >= DATE '2026-01-01'
              AND date_reg < DATE '2026-10-01'
        ) AS ev_2026
    FROM public.car_registrations_clean
    WHERE fuel = 'electric'
      AND (
          (date_reg >= DATE '2025-01-01'
           AND date_reg < DATE '2025-10-01')
          OR
          (date_reg >= DATE '2026-01-01'
           AND date_reg < DATE '2026-10-01')
      )
    GROUP BY maker, model
)
-- Sum model-level results back to each maker.
SELECT
    maker,
    SUM(ev_2025) AS ev_2025,
    SUM(ev_2026) AS ev_2026,
    SUM(ev_2026 - ev_2025) AS ev_change
FROM model_totals
GROUP BY maker
ORDER BY ev_change DESC, maker;