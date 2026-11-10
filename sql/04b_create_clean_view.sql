-- Centralize confirmed maker-name corrections.
-- Preserve every raw record and retain the original maker value.
CREATE OR REPLACE VIEW public.car_registrations_clean AS
SELECT
    date_reg,
    type,
    maker AS maker_raw,
    CASE
        WHEN maker IN ('iCaur', 'Icaur') THEN 'iCaur'
        WHEN maker IN ('Jac', 'JAC') THEN 'JAC'
        ELSE maker
    END AS maker,
    CASE
        WHEN maker = 'Honda' AND model = 'E Advance '
            THEN 'E Advance'
        ELSE model
    END AS model,
    colour,
    fuel,
    state,
    model AS model_raw 
FROM public.car_registrations_raw;

-- Confirm that the cleaning view preserves the row count.
SELECT
    (SELECT COUNT(*)
     FROM public.car_registrations_raw) AS raw_rows,

    (SELECT COUNT(*)
     FROM public.car_registrations_clean) AS clean_rows,

    (SELECT COUNT(*)
     FROM public.car_registrations_clean)
    -
    (SELECT COUNT(*)
     FROM public.car_registrations_raw) AS row_difference;

-- Validate comparison-period totals after cleaning.
SELECT
    EXTRACT(YEAR FROM date_reg)::int AS registration_year,
    COUNT(*) AS total_car_registrations,
    COUNT(*) FILTER (
        WHERE fuel = 'electric'
    ) AS ev_registrations
FROM public.car_registrations_clean
WHERE (date_reg >= DATE '2025-01-01'
       AND date_reg < DATE '2025-10-01')
   OR (date_reg >= DATE '2026-01-01'
       AND date_reg < DATE '2026-10-01')
GROUP BY EXTRACT(YEAR FROM date_reg)
ORDER BY registration_year;


-- Compare raw and standardized EV maker labels.
SELECT
    COUNT(DISTINCT maker_raw) AS raw_maker_count,
    COUNT(DISTINCT maker) AS clean_maker_count
FROM public.car_registrations_clean
WHERE fuel = 'electric'
  AND (
      (date_reg >= DATE '2025-01-01'
       AND date_reg < DATE '2025-10-01')
      OR
      (date_reg >= DATE '2026-01-01'
       AND date_reg < DATE '2026-10-01')
  );

