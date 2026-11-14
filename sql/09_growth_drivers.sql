-- Compare all EV registrations, Proton, and all other makers.
SELECT
    EXTRACT(YEAR FROM date_reg)::int AS registration_year,

    COUNT(*) AS total_ev,

    COUNT(*) FILTER (
        WHERE maker = 'Proton'
    ) AS proton_ev,

    COUNT(*) FILTER (
        WHERE maker <> 'Proton'
    ) AS non_proton_ev

FROM public.car_registrations_clean

WHERE fuel = 'electric'
  AND (
      (date_reg >= DATE '2025-01-01'
       AND date_reg < DATE '2025-10-01')
      OR
      (date_reg >= DATE '2026-01-01'
       AND date_reg < DATE '2026-10-01')
  )

GROUP BY EXTRACT(YEAR FROM date_reg)
ORDER BY registration_year;


-- Compare growth across three market scopes.
WITH ev_data AS (
    SELECT
        EXTRACT(YEAR FROM date_reg)::int AS registration_year,
        maker
    FROM public.car_registrations_clean
    WHERE fuel = 'electric'
      AND (
          (date_reg >= DATE '2025-01-01'
           AND date_reg < DATE '2025-10-01')
          OR
          (date_reg >= DATE '2026-01-01'
           AND date_reg < DATE '2026-10-01')
      )
),

scope_totals AS (
    SELECT
        1 AS sort_order,
        'All EV' AS market_scope,
        COUNT(*) FILTER (
            WHERE registration_year = 2025
        ) AS ev_2025,
        COUNT(*) FILTER (
            WHERE registration_year = 2026
        ) AS ev_2026
    FROM ev_data

    UNION ALL

    SELECT
        2 AS sort_order,
        'Proton' AS market_scope,
        COUNT(*) FILTER (
            WHERE registration_year = 2025
        ) AS ev_2025,
        COUNT(*) FILTER (
            WHERE registration_year = 2026
        ) AS ev_2026
    FROM ev_data
    WHERE maker = 'Proton'

    UNION ALL

    SELECT
        3 AS sort_order,
        'Excluding Proton' AS market_scope,
        COUNT(*) FILTER (
            WHERE registration_year = 2025
        ) AS ev_2025,
        COUNT(*) FILTER (
            WHERE registration_year = 2026
        ) AS ev_2026
    FROM ev_data
    WHERE maker <> 'Proton'
)

SELECT
    market_scope,
    ev_2025,
    ev_2026,
    ev_2026 - ev_2025 AS ev_change,

    ROUND(
        100.0 * (ev_2026 - ev_2025)
        / NULLIF(ev_2025, 0),
        2
    ) AS ev_yoy_pct

FROM scope_totals
ORDER BY sort_order;


/*
Finding:
2026 年 1–9 月，EV 注册量同比增长 98.82%，净增加 26,609 辆。

Proton 净增加 18,645 辆，贡献全国净增长的 70.07%。

排除 Proton 后，其余品牌注册量从 20,716 辆增至 28,680 辆，
同比增长 38.44%，贡献全国净增长的 29.93%。

这说明增长高度集中于 Proton，但其余品牌合计仍在扩张。
这里的合计增长不代表每个品牌都增长；
排除 Proton 的分组统计也不代表“没有 Proton”的市场预测。
*/


-- Compare brand growth and changes in EV market share.
WITH brand_totals AS (
    SELECT
        maker,

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

    GROUP BY maker
),

brand_metrics AS (
    SELECT
        maker,
        ev_2025,
        ev_2026,
        ev_2026 - ev_2025 AS ev_change,

        100.0 * (ev_2026 - ev_2025)
            / NULLIF(ev_2025, 0) AS ev_yoy_pct,

        100.0 * ev_2025
            / NULLIF(SUM(ev_2025) OVER (), 0) AS share_2025_pct,

        100.0 * ev_2026
            / NULLIF(SUM(ev_2026) OVER (), 0) AS share_2026_pct,

        100.0 * (ev_2026 - ev_2025)
            / NULLIF(
                SUM(ev_2026 - ev_2025) OVER (),
                0
            ) AS net_growth_contribution_pct

    FROM brand_totals
)

SELECT
    maker,
    ev_2025,
    ev_2026,
    ev_change,
    ROUND(ev_yoy_pct, 2) AS ev_yoy_pct,
    ROUND(share_2025_pct, 2) AS share_2025_pct,
    ROUND(share_2026_pct, 2) AS share_2026_pct,
    ROUND(share_2026_pct - share_2025_pct, 2) AS share_change_pp,
    ROUND(net_growth_contribution_pct, 2) AS net_growth_contribution_pct

FROM brand_metrics
WHERE ev_change > 0 AND share_2026_pct < share_2025_pct
ORDER BY ev_change DESC, maker;


-- Decompose EV growth by model registration presence.
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
),

group_totals AS (
    SELECT
        CASE
            WHEN ev_2025 = 0 THEN '2026 only'
            WHEN ev_2026 = 0 THEN '2025 only'
            ELSE 'Both periods'
        END AS model_group,

        COUNT(*) AS maker_model_count,
        SUM(ev_2025) AS ev_2025,
        SUM(ev_2026) AS ev_2026,
        SUM(ev_2026 - ev_2025) AS ev_change

    FROM model_totals
    GROUP BY model_group
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
WHERE ev_2025 > 0
  AND ev_2026 > 0
  AND ev_2026 < ev_2025
ORDER BY ev_change ASC, maker, model
LIMIT 5;