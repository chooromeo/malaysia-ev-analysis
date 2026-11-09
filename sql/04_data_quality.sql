SELECT current_database() AS database_name;

-- Check that every month in both comparison periods has records.
SELECT
    DATE_TRUNC('month', date_reg)::date AS month_start,
    MIN(date_reg) AS first_registration_date,
    MAX(date_reg) AS last_registration_date,
    COUNT(*) AS registrations
FROM public.car_registrations_raw
WHERE (date_reg >= DATE '2025-01-01'
       AND date_reg < DATE '2025-10-01')
   OR (date_reg >= DATE '2026-01-01'
       AND date_reg < DATE '2026-10-01')
GROUP BY DATE_TRUNC('month', date_reg)::date
ORDER BY month_start;

-- Check the full raw table so date filters do not hide missing dates.
SELECT
    EXTRACT(YEAR FROM date_reg)::int AS registration_year,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE date_reg IS NULL
    ) AS missing_date,
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(fuel), '') IS NULL
    ) AS missing_fuel,
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(maker), '') IS NULL
    ) AS missing_maker,
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(model), '') IS NULL
    ) AS missing_model
FROM public.car_registrations_raw
GROUP BY EXTRACT(YEAR FROM date_reg)
ORDER BY registration_year NULLS LAST;

SELECT
    fuel,
    COUNT(*) AS registrations
FROM public.car_registrations_raw
GROUP BY fuel
ORDER BY registrations DESC;

SELECT
    fuel,
    LENGTH(fuel) AS character_count,
    COUNT(*) AS registrations
FROM public.car_registrations_raw
WHERE fuel <> TRIM(fuel)
   OR fuel <> LOWER(fuel)
GROUP BY fuel
ORDER BY registrations DESC;
