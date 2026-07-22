# Data

This folder holds the data the SQL scripts load. Three CSV files in total:

| File                           | What it is                                  | Where it comes from                      |
| ------------------------------ | ------------------------------------------- | ---------------------------------------- |
| `fl_county_population_raw.csv` | BEBR `Table 03` saved as CSV, **uncleaned** | **You export it** from the BEBR download |
| `fl_county_components_raw.csv` | BEBR `Table 02` saved as CSV, **uncleaned** | **You export it** from the BEBR download |
| `fl_county_regions.csv`        | County → Florida region lookup              | Already included in this repo            |

The two files you export both come from **one** Excel download from UF BEBR.

**The important part:** you do **not** clean these files by hand. You just
open the workbook, pick a tab, and use **Save As → CSV** - no deleting rows,
no deleting columns, no editing headers. All of the cleaning (dropping the
title/header/`FLORIDA`/blank/footnote rows, throwing away the columns we don't
need, and converting text to numbers) happens later in SQL, in
[`../sql/02_load_data.sql`](../sql/02_load_data.sql). That keeps the raw
`estimates_2025.xlsx` completely untouched and makes the whole cleanup
**reproducible** - anyone can re-run the SQL on a fresh export.

> **Why is there an Excel step at all?** PostgreSQL can't read `.xlsx` files
> directly, so there always has to be one tiny "save the tab as CSV" step to
> hand it something it can import. Using **Save As** writes a brand-new file
> and never modifies the workbook you downloaded.

The whole thing takes about 2 minutes.

---

## Step 1 - Download the BEBR Excel file

1. Open the BEBR Population program page: [bebr.ufl.edu/population](https://bebr.ufl.edu/population/)
2. Click **Population** (left menu)
3. Click the **Recent Data** link - it takes you to the release page.
   (Direct page: [bebr.ufl.edu/florida-estimates-of-population-2025](https://bebr.ufl.edu/florida-estimates-of-population-2025/))
4. Click the **`estimates_2025.xlsx`** link to download the workbook.
5. Save it into this `data/` folder. (You can delete it later - we only need it to make the two CSVs.)

The workbook has 18 tabs (`Table 01` … `Table 18`). We only use two of them:

| Sheet      | What it has                                                                       | Export it as                   |
| ---------- | --------------------------------------------------------------------------------- | ------------------------------ |
| `Table 03` | Population by county for 2000, 2010, 2020, 2025                                   | `fl_county_population_raw.csv` |
| `Table 02` | Components of change for 2020 to 2025 (births, deaths, natural change, migration) | `fl_county_components_raw.csv` |

---

## Step 2 - Export `fl_county_population_raw.csv` (from `Table 03`)

1. Open the workbook and click the **`Table 03`** tab.
2. **File → Save As**, and choose **CSV UTF-8 (Comma delimited) (\*.csv)**.
   (Plain "CSV (Comma delimited)" also works; UTF-8 is just the safest choice
   so the import never trips over a special character in the footnote.)
3. Name it **`fl_county_population_raw.csv`** and save it in this `data/` folder.
4. If Excel warns that only the active sheet will be saved, click **OK** - that's
   exactly what we want (just `Table 03`). It tells Excel to intentionally discard the other tabs and only export your active sheet into the new file.

That's it. **Don't delete or edit anything** - the file keeps its title row,
header rows, the `FLORIDA` total, the blank separator rows, the extra columns,
and the footnote. The SQL in `../sql/02_load_data.sql` strips all of that out.

---

## Step 3 - Export `fl_county_components_raw.csv` (from `Table 02`)

Exactly the same process, on the other tab:

1. Click the **`Table 02`** tab.
2. **File → Save As → CSV UTF-8 (Comma delimited) (\*.csv)**.
3. Name it **`fl_county_components_raw.csv`** and save it in this `data/` folder.
4. Click **OK** on the "active sheet only" warning.

Again, **no manual cleanup** - leave the file as Excel exports it.

> **Tip:** if you reopened or edited the workbook, just make sure you exported
> the right tab (`Table 03` → population, `Table 02` → components). You don't
> need to check the rows - the SQL only keeps lines that match one of the 67
> real county names, so any leftover header or total line is ignored.

---

## About `fl_county_regions.csv` (already included)

This file is **not** a BEBR download. The BEBR tables list counties but not which
part of the state they're in, so this lookup puts each of the 67 counties into
one of eight broad Florida regions (Northwest, North Central, Northeast,
Central, Central East, Central West, Southwest, Southeast). It lets the SQL
`GROUP BY region` to compare different parts of the state.

**Where the regions come from:** the assignments are derived from
[VISIT FLORIDA](https://www.visitflorida.com/places-to-go/) (the state's
official tourism agency), which divides Florida into these exact eight
regions. VISIT FLORIDA maps _cities_ rather than counties, so I turned their
city list into a county list with one simple rule:

1. **A county gets the region of its VISIT FLORIDA cities.** For example,
   Tampa is listed under Central West, so Hillsborough County is Central West;
   Tallahassee is listed under North Central, so Leon County is North Central.
   59 of the 67 counties have at least one city on VISIT FLORIDA's map, and
   in every one of those counties all of its listed cities agree on the
   region, so there was no judgment call to make.
2. **The 8 rural counties with no city on the map** (Baker, Bradford, Calhoun,
   Gilchrist, Lafayette, Liberty, Union, Washington) get the region shared by
   the **majority of their neighboring counties** from step 1. Example:
   Washington County borders Bay, Holmes, Jackson, and Walton - all Northwest -
   so it's Northwest.

Anyone can re-derive this file from the VISIT FLORIDA page with those two
rules and get the same 67 assignments - nothing in it is my personal
preference. Note that this is still just one convention (Florida law, for
example, defines
[ten Regional Planning Councils](https://www.flsenate.gov/Laws/Statutes/2025/0186.512)
with different lines), and it only affects the _regional_ roll-ups (queries
Q6/Q7 and the `region` column in the summary view) - every county-level
number comes straight from BEBR. If you prefer different lines, just edit
this file and re-run `02_load_data.sql`. It's two columns - `county` and
`region` - and the county names match the BEBR spelling exactly (e.g.
`St. Johns`, `Miami-Dade`, `DeSoto`) so the join lines up.

---

## Data source

University of Florida, **Bureau of Economic and Business Research (BEBR)** -
_Florida Estimates of Population 2025_ (released December 2025).
Population counts for 2000/2010/2020 are U.S. Census Bureau counts; the 2025
figures are BEBR's official April 1, 2025 estimates.

- Program page: <https://bebr.ufl.edu/population/>
- This release: <https://bebr.ufl.edu/florida-estimates-of-population-2025/>
