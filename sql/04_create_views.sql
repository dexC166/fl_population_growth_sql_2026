-- =====================================================================
-- Florida Population Growth Analysis  |  04 - Create Views
-- ---------------------------------------------------------------------
-- A VIEW is a saved query I can treat like a table. Instead of writing
-- the same 3-table JOIN over and over, I build it once here and then
-- run simple SELECTs against it. Run this after 01 and 02.
-- =====================================================================

DROP VIEW IF EXISTS county_growth_summary;

CREATE VIEW county_growth_summary AS
SELECT
    p.county,
    r.region,
    p.pop_2020,
    p.pop_2025,
    c.total_change_2020_2025 AS people_added,
    ROUND((p.pop_2025 - p.pop_2020) * 100.0 / p.pop_2020, 1) AS pct_growth,
    c.births,
    c.deaths,
    c.natural_change,
    c.net_migration,
    -- Plain-English label for the "story" behind each county's growth:
    CASE
        WHEN c.natural_change < 0 AND c.total_change_2020_2025 > 0
            THEN 'Growth from migration only'
        WHEN c.natural_change >= 0 AND c.net_migration >= 0
            THEN 'Growth from both'
        WHEN c.total_change_2020_2025 < 0
            THEN 'Losing population'
        ELSE 'Mixed'
    END AS growth_story
FROM county_population AS p
INNER JOIN county_region    AS r ON p.county = r.county
INNER JOIN county_components AS c ON p.county = c.county;


-- ---------------------------------------------------------------------
-- Now the view makes questions short and readable. A few examples:
-- ---------------------------------------------------------------------

-- All the counties that are only growing because people move in,
-- biggest first. (This is the headline story, in one easy query.)
SELECT region, county, pct_growth, growth_story
FROM county_growth_summary
WHERE growth_story = 'Growth from migration only'
ORDER BY pct_growth DESC;

-- How many counties fall into each "growth story"?
SELECT growth_story, COUNT(*) AS county_count
FROM county_growth_summary
GROUP BY growth_story
ORDER BY county_count DESC;

-- My home base: Manatee County and its Southwest neighbors.
SELECT county, pop_2025, people_added, pct_growth, growth_story
FROM county_growth_summary
WHERE region = 'Southwest'
ORDER BY pct_growth DESC;
