-- =====================================================================
-- Florida Population Growth Analysis  |  01 - Create Tables (PostgreSQL)
-- ---------------------------------------------------------------------
-- Run this FIRST. It builds the three tables that hold the BEBR data.
-- Then run 02_load_data.sql to fill them, then 03 / 04 for the analysis.
--
-- Let's design the tables first, give each one a PRIMARY KEY,
-- and use FOREIGN KEYs so the data stays consistent.
-- =====================================================================

-- Drop old copies first so I can re-run this whole script any time.
-- Order matters: drop the tables that POINT TO county_population before
-- county_population itself (you cannot drop a table another one references).
DROP TABLE IF EXISTS county_components;
DROP TABLE IF EXISTS county_region;
DROP TABLE IF EXISTS county_population;


-- ---------------------------------------------------------------------
-- TABLE 1: county_population
-- One row per Florida county. Population at four points in time.
-- Source: BEBR "Florida Estimates of Population 2025", Table 3.
-- ---------------------------------------------------------------------
CREATE TABLE county_population (
    county    VARCHAR(40) PRIMARY KEY,     -- e.g. 'Manatee' (the key I join on)
    pop_2025  INTEGER NOT NULL,            -- 2025 estimate (April 1)
    pop_2020  INTEGER NOT NULL,            -- 2020 Census
    pop_2010  INTEGER NOT NULL,            -- 2010 Census
    pop_2000  INTEGER NOT NULL,            -- 2000 Census
    CONSTRAINT pop_2025_nonneg CHECK (pop_2025 >= 0)
);


-- ---------------------------------------------------------------------
-- TABLE 2: county_components
-- One row per county. WHY the population changed from 2020 to 2025.
-- natural_change = births - deaths, so it CAN be negative.
-- net_migration  = people who moved in minus people who moved out.
-- Source: BEBR "Florida Estimates of Population 2025", Table 2.
-- ---------------------------------------------------------------------
CREATE TABLE county_components (
    county                 VARCHAR(40) PRIMARY KEY
                           REFERENCES county_population(county),  -- FK -> Table 1
    total_change_2020_2025 INTEGER NOT NULL,   -- total people gained/lost
    births                 INTEGER NOT NULL,
    deaths                 INTEGER NOT NULL,
    natural_change         INTEGER NOT NULL,   -- births - deaths (may be < 0)
    net_migration          INTEGER NOT NULL    -- may be < 0
);


-- ---------------------------------------------------------------------
-- TABLE 3: county_region
-- A small lookup that puts each county in one of VISIT FLORIDA's eight
-- regions, derived from their city map (see data/README.md). This is
-- NOT a BEBR download. It lets me GROUP BY region and compare parts
-- of the state.
-- ---------------------------------------------------------------------
CREATE TABLE county_region (
    county  VARCHAR(40) PRIMARY KEY
            REFERENCES county_population(county),   -- FK -> Table 1
    region  VARCHAR(20) NOT NULL
);
