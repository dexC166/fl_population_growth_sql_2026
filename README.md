# Florida Population Growth Analysis (SQL)

**Where Florida is growing, how fast, and what's actually driving it - births or people moving in - county by county, using SQL.**

I built this as a portfolio project using **PostgreSQL**, real population data from the **UF Bureau of Economic and Business Research (BEBR)** (my alma mater), and a question I care about as a Florida resident: my state is the fastest-growing in the country, so _where_ is everyone going, and _why_?

**Source code:** [github.com/dexC166/fl_population_growth_sql_2026](https://github.com/dexC166/fl_population_growth_sql_2026)

---

## The Headline (Plain English)

Between the 2020 Census and April 2025, **Florida added about 1.84 million people** - it grew **8.5%** in five years. But here's the part most people miss:

> Statewide, **more Floridians died than were born** during those five years (1,197,162 deaths vs. 1,096,073 births - a _natural decrease_ of about 101,000). So **essentially 100% of Florida's growth came from people moving in**, not from new babies.

That single fact reshapes how Florida should plan. A state that grows from **births** needs maternity wards, pediatricians, and elementary schools. A state that grows from **migration** - especially older movers - needs roads, housing, water, and elder care instead. This project uses SQL to show exactly which counties are in which situation.

### Two terms used throughout

| Term               | What it means (plain English)                                                        |
| ------------------ | ------------------------------------------------------------------------------------ |
| **Natural change** | Births **minus** deaths. Positive = more babies than deaths. Negative = the reverse. |
| **Net migration**  | People who **moved in** minus people who **moved out**.                              |

A county's total population change is just **natural change + net migration**. Throughout this project, the surprise is how often natural change is _negative_ and migration is doing all the work.

---

## Why This Project Is Useful

Florida's growth isn't evenly spread, and it isn't coming from where people assume. The raw numbers exist in a BEBR spreadsheet, but they sit in 18 tabs that most people never open. This project turns two of those tabs into clear answers about **where** growth is concentrated and **what's driving it** - the kind of thing a county planner, reporter, or resident can actually act on.

**Who can benefit from it:**

- **City and county planners** - see whether to plan for young families (births) or for in-movers and retirees (migration), and which counties are about to feel the most pressure.
- **Local journalists and residents** - get a plain-English picture of how fast their county is growing and why.
- **Housing and infrastructure advocates** - back up funding requests with county-level numbers.
- **Students and analysts** - reuse the schema and queries as a template for any state's population data.

**Community impact:** I live in **Manatee County**, which grew **16.8%** in five years - and like 49 other Florida counties, it is growing **only because people are moving in** (it had more deaths than births). Knowing that is the difference between a county planning for the wrong future and the right one. Anyone can re-run these queries on a fresh BEBR download to keep the picture current.

---

## The 10 Questions This Project Answers

Every number below is produced **live** by a query in [`sql/03_analysis_queries.sql`](sql/03_analysis_queries.sql) - nothing is typed in by hand. (Q-numbers match the comments in that file.)

#### 1. Which counties added the most people (raw headcount) from 2020-2025?

Answer:

**Polk led, then the big metros** - these are the counties feeling the most pressure on roads, schools, and water _in absolute terms_.

- Polk: **+121,850**
- Hillsborough: **+115,875**
- Miami-Dade: **+113,160**
- Orange: **+106,137**

#### 2. Which counties grew the fastest in percentage terms?

Answer:

**Fast-growing suburbs and retirement areas led the pack** - small bases, big percent jumps.

- St. Johns: **27.4%**
- Sumter: **25.2%** (home of The Villages)
- Osceola: **24.8%**
- Flagler: **22.0%**
- Walton: **20.2%**

#### 3. Is Florida's growth coming from births or migration? _(the big one)_

Answer:

**Migration - completely.** It didn't just lead the growth; it covered a natural _loss_ and still added ~1.84 million on top.

- Natural change (births − deaths): **−101,089** - deaths actually beat births
- Net migration (people moving in): **+1,942,163**

#### 4. How many counties had more deaths than births?

Answer:

**Most of the state - Florida is aging.** In these counties the only thing keeping population from falling is new arrivals.

- Counties with a natural decrease: **51 of 67**
- Counties with more births than deaths: **16 of 67**

#### 5. Which counties would be shrinking without migration?

Answer:

**50 counties are growing on migration alone** - they'd be shrinking on births vs. deaths by themselves.

- Natural decrease _but still grew_: **50 counties**
- A clear example: **Manatee** (more deaths than births, but still gaining people)

#### 6. How does growth compare across Florida's regions?

Answer:

**The Orlando area added the most people; the Northeast grew the fastest.**

- Most people added: **Central (greater Orlando), +461,411**
- Fastest-growing region: **Northeast, +12.9%**
- Slowest, despite being the most populous: **Southeast (Miami/Fort Lauderdale/Palm Beach), 3.7%**

#### 7. Which regions have an average county growth rate above 10%?

Answer:

**Four regions clear the 10% bar.**

- Northeast: **14.8%**
- Central: **13.2%**
- East Central: **10.8%**
- Central West: **10.5%**

#### 8. How do all 67 counties sort into growth tiers?

Answer:

**A `CASE` statement sorts every county into four tiers.**

- Booming (15%+): **15 counties**
- Growing (5-15%): **28 counties**
- Slow (0-5%): **23 counties**
- Declining (below 0%): **1 county** - Bradford, the only one that lost population

#### 9. Which counties beat the statewide growth rate?

Answer:

**28 counties beat Florida's overall pace.**

- Counties above the statewide rate: **28 of 67**
- The benchmark they beat: **8.5%** (calculated with a subquery, so it's never hard-coded)

#### 10. What's each county's growth rank?

Answer:

**A self-join ranks every county by percent growth** - handy for placing any county against the rest of the state.

- #1: **St. Johns**
- #2: **Sumter**
- #3: **Osceola**

---

## Skills Demonstrated

| Concept (from the SQL Bootcamp)              | Where I used it                                                             |
| -------------------------------------------- | --------------------------------------------------------------------------- |
| **CREATE TABLE / constraints**               | `PRIMARY KEY`, `FOREIGN KEY`, `NOT NULL`, `CHECK` in `01_create_tables.sql` |
| **Importing CSVs**                           | pgAdmin Import + `\copy` + server-side `COPY` in `02_load_data.sql`         |
| **Staging tables + data cleaning (ELT)**     | Load raw BEBR exports, then clean in SQL in `02_load_data.sql`              |
| **String + cast functions**                  | `REPLACE`, `TRIM`, `::INTEGER` to strip separators + cast in `02_load_data.sql` |
| **SELECT / WHERE / ORDER BY / LIMIT**        | Every query; top-10 lists, filtered county lists                            |
| **DISTINCT / COUNT / MIN / MAX / SUM / AVG** | Warm-up checks and the statewide totals                                     |
| **Computed columns + ROUND + decimals**      | Percent-growth math (and the integer-division gotcha)                       |
| **GROUP BY / HAVING**                        | Regional roll-ups and the "regions above 10%" filter                        |
| **INNER JOIN / LEFT JOIN (3 tables)**        | Joining population + components + region                                    |
| **Self-join**                                | Ranking counties by growth (Q10)                                            |
| **Subqueries**                               | Comparing each county to the statewide rate (Q9)                            |
| **CASE**                                     | Growth tiers (Q8) and the "growth story" label                              |
| **UNION ALL**                                | Fastest + shrinking counties in one result                                  |
| **VIEWS**                                    | `county_growth_summary` in `04_create_views.sql`                            |

---

## Project Structure

```
FL_Population_Growth_SQL_2026/
├── data/
│   ├── fl_county_regions.csv             # county -> region lookup (included)
│   ├── fl_county_population_raw.csv      # raw export of BEBR Table 03 (you make this)
│   ├── fl_county_components_raw.csv      # raw export of BEBR Table 02 (you make this)
│   └── README.md                         # step-by-step download + export guide
├── sql/
│   ├── 01_create_tables.sql              # schema (run first)
│   ├── 02_load_data.sql                  # load raw exports into staging, then clean in SQL
│   ├── 03_analysis_queries.sql           # the 10 questions
│   └── 04_create_views.sql               # reusable summary view
└── README.md
```

---

## Quick Start

You need **PostgreSQL** and **pgAdmin** (both installed together; this is the same setup from the SQL Bootcamp).

1. **Get the data.** Follow [`data/README.md`](data/README.md) to download the BEBR
   Excel file and **Save As CSV** two of its tabs into `fl_county_population_raw.csv`
   and `fl_county_components_raw.csv` - no manual cleanup; the SQL does that.
   (`fl_county_regions.csv` is already here.)
2. **Create a database** in pgAdmin called `fl_population`.
3. **Run the scripts in order** in the Query Tool:
   ```
   sql/01_create_tables.sql      -- build the tables
   sql/02_load_data.sql          -- load the raw exports into staging, then clean in SQL
   sql/03_analysis_queries.sql   -- run the 10 questions one at a time
   sql/04_create_views.sql       -- build + use the summary view
   ```
4. The check at the bottom of `02_load_data.sql` should report **67 rows** in each table.

---

## Sample Results

**Growth by region, 2020-2025** (from Q6):

| Region        | Population 2025 | People added | Growth rate |
| ------------- | --------------- | ------------ | ----------- |
| Central       | 4,413,376       | 461,411      | 11.7%       |
| Central West  | 4,358,273       | 349,282      | 8.7%        |
| Southeast     | 6,449,330       | 228,123      | 3.7%        |
| Northeast     | 1,942,891       | 221,665      | 12.9%       |
| Southwest     | 1,746,386       | 171,038      | 10.9%       |
| East Central  | 1,401,268       | 147,211      | 11.7%       |
| North Central | 1,407,953       | 139,271      | 11.0%       |
| Northwest     | 1,659,784       | 123,073      | 8.0%        |

**Statewide, 2020-2025:** population grew from **21,538,187** to **23,379,261** (**+1,841,074**, or **8.5%**) - with a natural change of **-101,089** and net migration of **+1,942,163**.

**My home area (Central West region), sorted by growth** (from the `county_growth_summary` view):

| County       | Population 2025 | People added | Growth | What's driving it          |
| ------------ | --------------- | ------------ | ------ | -------------------------- |
| Manatee      | 466,845         | 67,135       | 16.8%  | Growth from migration only |
| Pasco        | 648,369         | 86,478       | 15.4%  | Growth from migration only |
| Sarasota     | 487,640         | 53,634       | 12.4%  | Growth from migration only |
| Hernando     | 212,849         | 18,334       | 9.4%   | Growth from migration only |
| Hillsborough | 1,575,637       | 115,875      | 7.9%   | Growth from both           |
| Pinellas     | 966,933         | 7,826        | 0.8%   | Growth from migration only |

---

## Limitations

The honest fine print:

- **Estimates, not a census.** The 2025 figures are BEBR's official estimates; 2000/2010/2020 are Census counts. Estimates carry some uncertainty, especially for small counties.
- **Five-year window.** Components of change (births, deaths, migration) cover 2020-2025 combined, not year by year.
- **Regions are my own grouping.** `fl_county_regions.csv` is a hand-built convenience lookup; Florida's regional lines vary by who's drawing them (see `data/README.md`).
- **Descriptive, not causal.** This shows _where_ and _what kind_ of growth, not _why_ people are choosing specific counties.
- **Counties only.** BEBR also publishes city-level data; this project stays at the county level to keep the joins clean.

---

## Data Source

University of Florida, **Bureau of Economic and Business Research (BEBR)** - _Florida Estimates of Population 2025_ (released December 2025). Population for 2000/2010/2020 are U.S. Census Bureau counts; 2025 figures are BEBR's official April 1, 2025 estimates.

- Program page: [bebr.ufl.edu/population](https://bebr.ufl.edu/population/)
- This release: [bebr.ufl.edu/florida-estimates-of-population-2025](https://bebr.ufl.edu/florida-estimates-of-population-2025/)

Full download-and-prep instructions are in [`data/README.md`](data/README.md).

---

## Author

**Dayle Cortes** - UF Alum, Manatee County, FL
