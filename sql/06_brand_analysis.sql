-- Review EV maker names across both comparison periods.
SELECT
    maker,
    COUNT(*) AS ev_registrations
FROM public.car_registrations_raw
WHERE fuel = 'electric'
  AND (
      (date_reg >= DATE '2025-01-01'
       AND date_reg < DATE '2025-10-01')
      OR
      (date_reg >= DATE '2026-01-01'
       AND date_reg < DATE '2026-10-01')
  )
GROUP BY maker
ORDER BY ev_registrations DESC, maker;


-- Find maker names that differ only by case or surrounding spaces.
SELECT
    LOWER(TRIM(maker)) AS maker_normalized,
    ARRAY_AGG(DISTINCT maker ORDER BY maker) AS original_names,
    COUNT(*) AS ev_registrations
FROM public.car_registrations_raw
WHERE fuel = 'electric'
  AND (
      (date_reg >= DATE '2025-01-01'
       AND date_reg < DATE '2025-10-01')
      OR
      (date_reg >= DATE '2026-01-01'
       AND date_reg < DATE '2026-10-01')
  )
GROUP BY LOWER(TRIM(maker))
HAVING COUNT(DISTINCT maker) > 1
ORDER BY ev_registrations DESC;


-- Compare EV registrations using standardized maker names.
WITH ev_data AS (
    SELECT
        EXTRACT(YEAR FROM date_reg)::int AS registration_year,
        maker AS maker_clean 
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
brand_totals AS (
    SELECT
        maker_clean,
        COUNT(*) FILTER (
            WHERE registration_year = 2025
        ) AS ev_2025,
        COUNT(*) FILTER (
            WHERE registration_year = 2026
        ) AS ev_2026
    FROM ev_data
    GROUP BY maker_clean
)
SELECT
    maker_clean,
    ev_2025,
    ev_2026,
    ev_2026 - ev_2025 AS ev_change,
    ROUND(
        100.0 * (ev_2026 - ev_2025)
        / NULLIF(ev_2025, 0),
        2
    ) AS ev_yoy_pct,
    ROUND(
        100.0 * (ev_2026 - ev_2025) 
        / NULLIF(SUM(ev_2026 - ev_2025) OVER(), 0),
        2
    ) AS net_growth_contribution_pct
FROM brand_totals
ORDER BY ev_change DESC, maker_clean;

