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


-- Review vehicle types within both comparison periods.
SELECT
    EXTRACT(YEAR FROM date_reg)::int AS registration_year,
    type,
    COUNT(*) AS total_registrations,
    COUNT(*) FILTER (
        WHERE fuel = 'electric'
    ) AS ev_registrations
FROM public.car_registrations_raw
WHERE (date_reg >= DATE '2025-01-01'
       AND date_reg < DATE '2025-10-01')
   OR (date_reg >= DATE '2026-01-01'
       AND date_reg < DATE '2026-10-01')
GROUP BY
    EXTRACT(YEAR FROM date_reg),
    type
ORDER BY type, registration_year;


-- Find surrounding whitespace, repeated spaces or control characters.
SELECT
    maker,
    model,
    COUNT(*) AS registrations
FROM public.car_registrations_raw
WHERE maker ~ '(^[[:space:]])|([[:space:]]$)|([[:space:]]{2,})|([[:cntrl:]])'
   OR model ~ '(^[[:space:]])|([[:space:]]$)|([[:space:]]{2,})|([[:cntrl:]])'
GROUP BY maker, model
ORDER BY registrations DESC, maker, model;


-- Review name variants and fuel combinations for models with EV records.
WITH model_records AS (
    SELECT
        LOWER(TRIM(maker)) AS maker_key,
        LOWER(TRIM(model)) AS model_key,
        maker,
        model,
        fuel
    FROM public.car_registrations_raw
    WHERE (date_reg >= DATE '2025-01-01'
           AND date_reg < DATE '2025-10-01')
       OR (date_reg >= DATE '2026-01-01'
           AND date_reg < DATE '2026-10-01')
)
SELECT
    maker_key,
    model_key,
    ARRAY_AGG(DISTINCT maker ORDER BY maker) AS maker_names,
    ARRAY_AGG(DISTINCT model ORDER BY model) AS model_names,
    ARRAY_AGG(DISTINCT fuel ORDER BY fuel) AS fuel_types,
    COUNT(*) AS total_registrations,
    COUNT(*) FILTER (
        WHERE fuel = 'electric'
    ) AS ev_registrations,
    COUNT(*) FILTER (
        WHERE fuel = 'petrol'
    ) AS petrol_registrations,
    COUNT(*) FILTER (
        WHERE fuel = 'hybrid_petrol'
    ) AS hybrid_petrol_registrations
FROM model_records
GROUP BY maker_key, model_key
HAVING COUNT(*) FILTER (WHERE fuel = 'electric') > 0
   AND (
       COUNT(DISTINCT maker) > 1
       OR COUNT(DISTINCT model) > 1
       OR COUNT(DISTINCT fuel) > 1
   )
ORDER BY ev_registrations DESC, maker_key, model_key;

