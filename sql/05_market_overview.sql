SELECT 
    EXTRACT(YEAR FROM date_reg)::int AS registration_year,
    COUNT(*) AS total_car_registrations,
    COUNT(*) FILTER(
        WHERE fuel = 'electric'
    ) AS ev_registrations,
    ROUND(
        100.0 * COUNT(*) FILTER(WHERE fuel = 'electric') / NULLIF(COUNT(*), 0), 2   
    ) AS ev_share_pct
FROM public.car_registrations_raw
WHERE (date_reg >= DATE '2025-01-01'
       AND date_reg < DATE '2025-10-01')
   OR (date_reg >= DATE '2026-01-01'
       AND date_reg < DATE '2026-10-01')
GROUP BY EXTRACT(YEAR FROM date_reg)
ORDER BY registration_year;


WITH yearly AS(
    SELECT
        EXTRACT(YEAR FROM date_reg)::int AS registration_year,
        COUNT(*) AS total_car_registrations,
        COUNT(*) FILTER(
            WHERE fuel = 'electric'
    ) AS ev_registrations
FROM public.car_registrations_raw
WHERE (date_reg >= DATE '2025-01-01'
       AND date_reg < DATE '2025-10-01')
   OR (date_reg >= DATE '2026-01-01'
       AND date_reg < DATE '2026-10-01')
GROUP BY EXTRACT(YEAR FROM date_reg)    
)
SELECT
    current.registration_year AS comparison_year,
    previous.registration_year AS baseline_year,
    ROUND(
        100.0 * (current.total_car_registrations - previous.total_car_registrations) / NULLIF(previous.total_car_registrations, 0), 2   
    ) AS total_car_yoy_pct,
    current.ev_registrations - previous.ev_registrations AS ev_change,
    ROUND(
        100.0 * (current.ev_registrations - previous.ev_registrations) / NULLIF(previous.ev_registrations, 0), 2   
    ) AS ev_yoy_pct,
    ROUND(
        100.0 * current.ev_registrations / NULLIF(current.total_car_registrations, 0) 
        - 100.0 * previous.ev_registrations / NULLIF(previous.total_car_registrations, 0), 2
    ) AS ev_share_change_pp

FROM yearly AS current
JOIN yearly AS previous
    ON current.registration_year = previous.registration_year + 1
WHERE current.registration_year = 2026;


WITH monthly AS(
    SELECT
        EXTRACT(YEAR FROM date_reg)::int AS registration_year,
        EXTRACT(MONTH FROM date_reg)::int AS registration_month,
        COUNT(*) AS total_car_registrations,
        COUNT(*) FILTER(
            WHERE fuel = 'electric'
        ) AS ev_registrations,
        ROUND(
            100.0 * COUNT(*) FILTER(WHERE fuel = 'electric') / NULLIF(COUNT(*), 0), 2   
        ) AS ev_share_pct
    FROM public.car_registrations_raw
    WHERE (date_reg >= DATE '2025-01-01'
        AND date_reg < DATE '2025-10-01')
    OR (date_reg >= DATE '2026-01-01'
        AND date_reg < DATE '2026-10-01')
    GROUP BY EXTRACT(YEAR FROM date_reg), EXTRACT(MONTH FROM date_reg)
)
SELECT 
    current.registration_month,
    previous.ev_registrations AS ev_2025,
    current.ev_registrations AS ev_2026,
    current.ev_registrations - previous.ev_registrations AS ev_change,
    ROUND(
        100.0 * (current.ev_registrations - previous.ev_registrations) / NULLIF(previous.ev_registrations, 0), 2   
    ) AS ev_yoy_pct

FROM monthly AS current
JOIN monthly AS previous
    ON current.registration_year = previous.registration_year + 1
    AND current.registration_month = previous.registration_month
WHERE current.registration_year = 2026
ORDER BY current.registration_month;