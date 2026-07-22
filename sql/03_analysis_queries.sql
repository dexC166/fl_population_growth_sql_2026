-- =====================================================================
-- Florida Population Growth Analysis  |  03 - Analysis Queries
-- ---------------------------------------------------------------------
-- Run this AFTER the tables are created (01) and loaded (02).
-- Run one query at a time (highlight it and press Run / F5 in pgAdmin).
--
-- The real-world question: Florida is growing fast. WHERE is it growing,
-- and is the growth coming from BABIES (births vs deaths) or from PEOPLE
-- MOVING IN (migration)? That answer changes what counties need to plan
-- for - schools and maternity wards vs. roads, housing, and elder care.
--
-- A quick note on math I learned in Jose Portilla's SQL bootcamp:
-- if you divide two INTEGERs, Postgres throws away the decimals
-- (e.g. 5 / 2 = 2, not 2.5). To get a real percentage I multiply by
-- 100.0 (a decimal) FIRST, which makes the whole result a decimal.
-- =====================================================================


-- =====================================================================
-- WARM-UPS - basic sanity checks on the data
-- =====================================================================

-- W1. How many counties are in each table? (Florida has 67.)
SELECT COUNT(*) AS county_count FROM county_population;

-- W2. What regions exist in my lookup table? (DISTINCT = unique values)
SELECT DISTINCT region
FROM county_region
ORDER BY region;

-- W3. The biggest and smallest counties in 2025 (MAX / MIN / aggregates).
SELECT
    MAX(pop_2025) AS largest_county_pop,
    MIN(pop_2025) AS smallest_county_pop,
    SUM(pop_2025) AS florida_total_2025,
    ROUND(AVG(pop_2025)) AS average_county_pop
FROM county_population;


-- =====================================================================
-- Q1. Which counties added the MOST people from 2020 to 2025?
--     (raw headcount - this is the planning pressure on roads, water,
--      schools, housing). Concepts: ORDER BY, LIMIT.
--     Answer: Polk (+121,850), then Hillsborough, Miami-Dade, Orange.
-- =====================================================================
SELECT
    county,
    total_change_2020_2025 AS people_added
FROM county_components
ORDER BY people_added DESC
LIMIT 10;


-- =====================================================================
-- Q2. Which counties grew the FASTEST in percentage terms 2020-2025?
--     (small counties can have huge % growth). Concepts: computed
--     column, the *100.0 trick, ROUND.
--     Answer: St. Johns 27.4%, Sumter 25.2%, Osceola 24.8%, Flagler 22.0%.
-- =====================================================================
SELECT
    county,
    pop_2020,
    pop_2025,
    ROUND((pop_2025 - pop_2020) * 100.0 / pop_2020, 1) AS pct_growth_2020_2025
FROM county_population
ORDER BY pct_growth_2020_2025 DESC
LIMIT 10;


-- =====================================================================
-- Q3. THE BIG FINDING: statewide, is growth from natural change
--     (births - deaths) or from migration (people moving in)?
--     Concepts: SUM over every county, multiple aggregates.
--     Answer: natural_change = -101,089  (deaths OUTNUMBERED births!)
--             net_migration  = +1,942,163
--     So 100%+ of Florida's growth came from people MOVING IN.
-- =====================================================================
SELECT
    SUM(births)                 AS total_births,
    SUM(deaths)                 AS total_deaths,
    SUM(natural_change)         AS natural_change,
    SUM(net_migration)          AS net_migration,
    SUM(total_change_2020_2025) AS total_growth
FROM county_components;


-- =====================================================================
-- Q4. How many counties had MORE DEATHS THAN BIRTHS (natural decrease)?
--     This is the "aging Florida" story. Concepts: COUNT + WHERE,
--     then a list ordered by how steep the decline is.
--     Answer: 51 of 67 counties had more deaths than births.
-- =====================================================================
SELECT COUNT(*) AS counties_with_natural_decrease
FROM county_components
WHERE natural_change < 0;

-- The 10 counties where deaths outpaced births the most:
SELECT
    county,
    births,
    deaths,
    natural_change
FROM county_components
WHERE natural_change < 0
ORDER BY natural_change ASC
LIMIT 10;


-- =====================================================================
-- Q5. Which counties are growing ONLY because people move in -
--     they would be SHRINKING on births/deaths alone?
--     Concepts: two conditions with AND.
--     Answer: 50 counties (natural decrease but still gaining people).
-- =====================================================================
SELECT
    county,
    natural_change,
    net_migration,
    total_change_2020_2025 AS total_change
FROM county_components
WHERE natural_change < 0          -- deaths beat births
  AND total_change_2020_2025 > 0  -- but the county still grew
ORDER BY net_migration DESC;


-- =====================================================================
-- Q6. How does growth compare across Florida's regions?
--     Concepts: INNER JOIN across all THREE tables, GROUP BY.
--     Answer: Central (Orlando area) added the most people (+508,475);
--             Southwest grew fastest as a region (12.6%, a hair ahead
--             of Central's 12.6%).
-- =====================================================================
SELECT
    r.region,
    COUNT(*)                            AS county_count,
    SUM(p.pop_2025)                     AS pop_2025,
    SUM(c.total_change_2020_2025)       AS people_added,
    ROUND(SUM(p.pop_2025 - p.pop_2020) * 100.0 / SUM(p.pop_2020), 1)
                                        AS region_growth_rate
FROM county_population AS p
INNER JOIN county_region    AS r ON p.county = r.county
INNER JOIN county_components AS c ON p.county = c.county
GROUP BY r.region
ORDER BY people_added DESC;


-- =====================================================================
-- Q7. Which regions have an AVERAGE county growth rate above 10%?
--     Concepts: GROUP BY + HAVING (a filter on a group's aggregate).
--     Answer: Central (13.4%), Southwest (12.7%), Northeast (11.4%).
-- =====================================================================
SELECT
    r.region,
    ROUND(AVG((p.pop_2025 - p.pop_2020) * 100.0 / p.pop_2020), 1)
        AS avg_county_growth_rate
FROM county_population AS p
INNER JOIN county_region AS r ON p.county = r.county
GROUP BY r.region
HAVING AVG((p.pop_2025 - p.pop_2020) * 100.0 / p.pop_2020) > 10
ORDER BY avg_county_growth_rate DESC;


-- =====================================================================
-- Q8. Sort every county into a growth "tier" and count how many fall
--     in each. Concepts: CASE (if/else in SQL), GROUP BY the label.
--     Answer: Booming 15, Growing 28, Slow 23, Declining 1 (Bradford).
-- =====================================================================
SELECT
    CASE
        WHEN (pop_2025 - pop_2020) * 100.0 / pop_2020 >= 15 THEN '1. Booming (15%+)'
        WHEN (pop_2025 - pop_2020) * 100.0 / pop_2020 >= 5  THEN '2. Growing (5-15%)'
        WHEN (pop_2025 - pop_2020) * 100.0 / pop_2020 >= 0  THEN '3. Slow (0-5%)'
        ELSE '4. Declining (below 0%)'
    END AS growth_tier,
    COUNT(*) AS county_count
FROM county_population
GROUP BY growth_tier
ORDER BY growth_tier;


-- =====================================================================
-- Q9. Which counties grew FASTER than Florida as a whole (8.5%)?
--     Concepts: a SUBQUERY that calculates the statewide rate, used
--     inside the WHERE clause so I don't hard-code the 8.5%.
--     Answer: 28 counties beat the statewide rate.
-- =====================================================================
SELECT
    county,
    ROUND((pop_2025 - pop_2020) * 100.0 / pop_2020, 1) AS pct_growth
FROM county_population
WHERE (pop_2025 - pop_2020) * 100.0 / pop_2020 >
      (
        SELECT (SUM(pop_2025) - SUM(pop_2020)) * 100.0 / SUM(pop_2020)
        FROM county_population
      )
ORDER BY pct_growth DESC;


-- =====================================================================
-- Q10. Rank counties by % growth using a SELF-JOIN.
--      Idea: a county's rank = (how many counties grew faster) + 1.
--      I join the table to itself: for each county "a", count every
--      county "b" with a higher growth rate. LEFT JOIN keeps the #1
--      county (which has nobody above it). Concepts: self-join,
--      LEFT JOIN, COUNT, GROUP BY.
--      Answer: #1 St. Johns, #2 Sumter, #3 Osceola...
-- =====================================================================
SELECT
    a.county,
    ROUND((a.pop_2025 - a.pop_2020) * 100.0 / a.pop_2020, 1) AS pct_growth,
    COUNT(b.county) + 1 AS growth_rank
FROM county_population AS a
LEFT JOIN county_population AS b
    ON (b.pop_2025 - b.pop_2020) * 100.0 / b.pop_2020
     > (a.pop_2025 - a.pop_2020) * 100.0 / a.pop_2020
GROUP BY a.county, a.pop_2025, a.pop_2020
ORDER BY growth_rank
LIMIT 10;


-- =====================================================================
-- BONUS. Fastest-growing and shrinking counties in ONE result set.
--        Concepts: UNION ALL (stack two queries on top of each other).
-- =====================================================================
(
    SELECT
        county,
        ROUND((pop_2025 - pop_2020) * 100.0 / pop_2020, 1) AS pct_growth,
        'Fastest growing' AS list
    FROM county_population
    ORDER BY pct_growth DESC
    LIMIT 5
)
UNION ALL
(
    SELECT
        county,
        ROUND((pop_2025 - pop_2020) * 100.0 / pop_2020, 1) AS pct_growth,
        'Slowest / shrinking' AS list
    FROM county_population
    ORDER BY pct_growth ASC
    LIMIT 5
)
ORDER BY pct_growth DESC;
