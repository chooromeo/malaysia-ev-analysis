-- 1. Confirm the selected database is malaysia_ev.
SELECT current_database() AS database_name;

-- 2. Expected counts from the current local CSV files:
-- 2025: 870188 rows, 2025-01-01 through 2025-12-31.
-- 2026: 640875 rows, 2026-01-01 through 2026-09-30.
SELECT
    EXTRACT(YEAR FROM date_reg)::int AS registration_year,
    MIN(date_reg) AS first_date,
    MAX(date_reg) AS last_date,
    COUNT(*) AS total_registrations
FROM public.car_registrations_raw
GROUP BY EXTRACT(YEAR FROM date_reg)
ORDER BY registration_year;

-- 3. September 2026: expected local CSV totals are 74259, 6029, 8.12.
-- These are local-file checks, not independently verified dashboard figures.
SELECT
    COUNT(*) AS total_registrations,
    COUNT(*) FILTER (WHERE fuel = 'electric') AS ev_registrations,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE fuel = 'electric')
        / NULLIF(COUNT(*), 0), 2
    ) AS ev_share_pct
FROM public.car_registrations_raw
WHERE date_reg >= DATE '2026-09-01'
  AND date_reg < DATE '2026-10-01';
