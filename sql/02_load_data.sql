-- =====================================================================
-- Florida Population Growth Analysis  |  02 - Load + Clean Data (PostgreSQL)
-- ---------------------------------------------------------------------
-- Run this AFTER 01_create_tables.sql, then run 03 / 04 for the analysis.
--
-- THE IDEA (and why it's different from a normal CSV import):
-- The BEBR workbook tabs are messy - they have a title line, a couple of
-- header lines, a "FLORIDA" statewide total, blank separator rows, and a
-- footnote. On top of that, Excel writes the big numbers with thousands
-- separators in quotes, like "298,485". Instead of cleaning all that BY
-- HAND in Excel, I leave the raw file untouched and let SQL do the work.
-- That's the real-world "load raw first, then transform" pattern (ELT):
--
--   1. Load each raw row, exactly as exported, into a "staging" table.
--   2. Use SQL to drop the junk rows and convert the text to numbers.
--   3. Insert the clean result into the real tables from 01.
--
-- This way the only Excel step is "Save As CSV" (no editing). See
-- data/README.md for exactly how to export the two raw files.
--
-- You need three CSV files in the data/ folder:
--   - fl_county_population_raw.csv    (raw export of BEBR "Table 03")
--   - fl_county_components_raw.csv    (raw export of BEBR "Table 02")
--   - fl_county_regions.csv           (clean lookup, already in this repo)
-- =====================================================================


-- =====================================================================
-- PART 1 - Create the staging tables (the "landing zone" for raw data)
-- ---------------------------------------------------------------------
-- Both BEBR exports are 9-column CSVs (the data columns we want, a blank
-- spacer column, and the "Percent of Change" columns we don't need). I
-- give each staging table nine TEXT columns so EVERY value lands as raw
-- text - including the quoted, comma-formatted numbers like "298,485".
-- Loading as text first means a stray header or footnote never breaks the
-- import; I sort the real rows from the junk in PART 3.
--
-- The regions file is already clean, so its staging table has real
-- columns. I load it first and use it as the official list of the 67
-- Florida counties - any row in the BEBR files that does NOT match a
-- real county name (titles, headers, "FLORIDA", blank rows) gets dropped
-- automatically when I join to it later.
-- =====================================================================
DROP TABLE IF EXISTS staging_population_raw;
DROP TABLE IF EXISTS staging_components_raw;
DROP TABLE IF EXISTS staging_region;

-- BEBR "Table 03" layout: county, 4 population years, spacer, 3 pct cols.
CREATE TABLE staging_population_raw (
    state_county TEXT,
    pop_2025     TEXT,
    pop_2020     TEXT,
    pop_2010     TEXT,
    pop_2000     TEXT,
    spacer       TEXT,
    pct_a        TEXT,
    pct_b        TEXT,
    pct_c        TEXT
);

-- BEBR "Table 02" layout: county, 5 change cols, spacer, 2 pct cols.
CREATE TABLE staging_components_raw (
    county         TEXT,
    total_change   TEXT,
    births         TEXT,
    deaths         TEXT,
    natural_change TEXT,
    net_migration  TEXT,
    spacer         TEXT,
    pct_a          TEXT,
    pct_b          TEXT
);

CREATE TABLE staging_region (                       -- already clean (county,region)
    county VARCHAR(40),
    region VARCHAR(20)
);


-- =====================================================================
-- PART 2 - Load the files INTO the staging tables
-- ---------------------------------------------------------------------
-- Pick ONE of the options below (A, B, or C), the same way the SQL
-- Bootcamp shows importing CSVs. Everything loads WITH (FORMAT csv):
--
--   * The regions file has a header row, so it loads with HEADER true.
--   * The two BEBR files have NO single header row (they have several
--     title/header lines), so they load with HEADER false - we keep
--     every line and throw the junk out in PART 3.
--   * FORMAT csv is what lets Postgres read a quoted value like
--     "298,485" as ONE field instead of splitting it on the comma.
--     (Save the BEBR files as "CSV UTF-8" so the import never chokes on
--     a stray special character in the footnote/header rows.)
-- =====================================================================


-- ---------------------------------------------------------------------
-- OPTION A (easiest): pgAdmin's point-and-click Import tool
-- ---------------------------------------------------------------------
--   1. Expand: Servers > (your server) > Databases > fl_population >
--      Schemas > public > Tables.
--   2. Right-click  staging_region  ->  Import/Export Data...  -> Import.
--        Filename: data/fl_county_regions.csv
--        Format: csv     Header: Yes     Delimiter: ,     Quote: "
--   3. Right-click  staging_population_raw  ->  Import/Export Data... -> Import.
--        Filename: data/fl_county_population_raw.csv
--        Format: csv     Header: No       Delimiter: ,     Quote: "
--        On the "Columns" tab, leave all nine columns selected.
--   4. Repeat step 3 for  staging_components_raw  using
--        data/fl_county_components_raw.csv .
-- ---------------------------------------------------------------------


-- ---------------------------------------------------------------------
-- OPTION B: \copy  (run these in the psql command-line tool, from the
--           project's root folder so the relative paths work)
-- ---------------------------------------------------------------------
-- \copy staging_region          (county, region) FROM 'data/fl_county_regions.csv'        WITH (FORMAT csv, HEADER true);
-- \copy staging_population_raw                    FROM 'data/fl_county_population_raw.csv' WITH (FORMAT csv, HEADER false);
-- \copy staging_components_raw                    FROM 'data/fl_county_components_raw.csv' WITH (FORMAT csv, HEADER false);


-- ---------------------------------------------------------------------
-- OPTION C: server-side COPY (edit the absolute paths, then run these)
-- ---------------------------------------------------------------------
-- COPY staging_region (county, region)
--   FROM 'C:\Users\DayleStandard\Desktop\FL_Population_Growth_SQL_2026\data\fl_county_regions.csv'
--   WITH (FORMAT csv, HEADER true);

-- COPY staging_population_raw
--   FROM 'C:\Users\DayleStandard\Desktop\FL_Population_Growth_SQL_2026\data\fl_county_population_raw.csv'
--   WITH (FORMAT csv, HEADER false);

-- COPY staging_components_raw
--   FROM 'C:\Users\DayleStandard\Desktop\FL_Population_Growth_SQL_2026\data\fl_county_components_raw.csv'
--   WITH (FORMAT csv, HEADER false);


-- =====================================================================
-- PART 3 - Clean the staging data and load the real tables
-- ---------------------------------------------------------------------
-- Run everything below AFTER the staging tables are loaded.
--
-- The two tools that do the cleaning:
--   * INNER JOIN to staging_region - only counties that exist in my
--     67-county lookup survive, so the title/header/FLORIDA/blank/footnote
--     rows are filtered out for free (their first column isn't a county).
--   * REPLACE(value, ',', '')::INTEGER - the raw numbers arrive as text
--     with thousands separators (e.g. '298,485'). REPLACE strips the
--     commas, TRIM removes stray spaces, then :: converts the text into a
--     real INTEGER so it fits the typed columns from 01. Negative values
--     like '-17,213' convert the same way.
-- =====================================================================

-- Clear the real tables first so this script is safe to re-run.
-- Delete children before the parent (the FKs point AT county_population).
DELETE FROM county_components;
DELETE FROM county_region;
DELETE FROM county_population;


-- Table 1: county_population  (county + four population columns)
INSERT INTO county_population (county, pop_2025, pop_2020, pop_2010, pop_2000)
SELECT
    TRIM(s.state_county),                               -- county name
    REPLACE(TRIM(s.pop_2025), ',', '')::INTEGER,        -- 2025
    REPLACE(TRIM(s.pop_2020), ',', '')::INTEGER,        -- 2020
    REPLACE(TRIM(s.pop_2010), ',', '')::INTEGER,        -- 2010
    REPLACE(TRIM(s.pop_2000), ',', '')::INTEGER         -- 2000
FROM staging_population_raw AS s
INNER JOIN staging_region AS r
    ON TRIM(s.state_county) = r.county;                 -- keep real counties only


-- Table 3: county_region  (the lookup is already clean - just copy it in)
INSERT INTO county_region (county, region)
SELECT county, region
FROM staging_region;


-- Table 2: county_components  (county + the five change columns)
INSERT INTO county_components
    (county, total_change_2020_2025, births, deaths, natural_change, net_migration)
SELECT
    TRIM(s.county),                                       -- county name
    REPLACE(TRIM(s.total_change), ',', '')::INTEGER,      -- total change 2020-2025
    REPLACE(TRIM(s.births), ',', '')::INTEGER,            -- births
    REPLACE(TRIM(s.deaths), ',', '')::INTEGER,            -- deaths
    REPLACE(TRIM(s.natural_change), ',', '')::INTEGER,    -- natural change (may be < 0)
    REPLACE(TRIM(s.net_migration), ',', '')::INTEGER      -- net migration (may be < 0)
FROM staging_components_raw AS s
INNER JOIN staging_region AS r
    ON TRIM(s.county) = r.county;                         -- keep real counties only


-- Staging tables have done their job - drop them to keep the schema tidy.
DROP TABLE staging_population_raw;
DROP TABLE staging_components_raw;
DROP TABLE staging_region;


-- =====================================================================
-- QUICK CHECK: did everything load? Each table should report 67 rows.
-- =====================================================================
SELECT 'county_population' AS table_name, COUNT(*) AS row_count FROM county_population
UNION ALL
SELECT 'county_region',     COUNT(*) FROM county_region
UNION ALL
SELECT 'county_components', COUNT(*) FROM county_components;
