-- Compare each maker's share of EV registrations.
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
brand_shares AS (
    SELECT
        maker,
        ev_2025,
        ev_2026,
        100.0 * ev_2025
            / NULLIF(SUM(ev_2025) OVER (), 0) AS share_2025,
        100.0 * ev_2026
            / NULLIF(SUM(ev_2026) OVER (), 0) AS share_2026
    FROM brand_totals
)
SELECT
    maker,
    ev_2025,
    ev_2026,
    ROUND(share_2025, 2) AS ev_market_share_2025_pct,
    ROUND(share_2026, 2) AS ev_market_share_2026_pct,
    ROUND(
        share_2026 - share_2025,
        2
    ) AS share_change_pp
FROM brand_shares
ORDER BY share_2026 DESC, maker;


