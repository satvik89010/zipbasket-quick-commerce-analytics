# ZipBasket Quick-Commerce Analytics

End-to-end analysis of a 10-minute grocery delivery business: 32K orders, 29 dark stores, 6 cities. **Excel → SQL (PostgreSQL) → Tableau**.

> 🔧 **Status: in progress.** Phase 1 (Excel cleaning) has started. See the [progress log](#progress-log) below.

## Business problem

ZipBasket (a fictional company) runs 29 dark stores across Bengaluru, Mumbai, Delhi, Hyderabad, Pune and Chennai, and promises delivery in 10 or 15 minutes. Order volume grew all through 2025, but leadership has three worries:

- **Speed.** Are we keeping the 10-minute promise? Which stores, hours and conditions break it?
- **Profit.** Are discounts, free delivery and coupons eating the margin? Which categories and coupons actually make money?
- **Customers.** Do customers come back after their first order? Do late deliveries lead to bad ratings and churn?

## Data

Raw operating data for Jan–Dec 2025 was exported from four different systems, so it is deliberately messy.

| Table | Raw rows | Grain (one row =) |
|---|---|---|
| orders | 32,394 | one order |
| order_items | 116,348 | one product line in an order |
| customers | 6,062 | one customer account |
| products | 56 | one product (SKU) |
| stores | 29 | one dark store |
| riders | 224 | one delivery rider |
| store_monthly_targets_2025 | 29 | one store, with 12 month columns |

`orders` is the centre of the model. Each order belongs to one customer, one store and one rider, and has one or more order_items. Each item points to one product.

## Project plan

| Phase | Tool | What | Status |
|---|---|---|---|
| 1 | Excel / Power Query | Profile the raw files, log every issue, build a first clean version | 🟡 In progress |
| 2 | PostgreSQL | raw → staging → mart layers, star schema, data-quality tests | ⬜ Not started |
| 3 | SQL | 30 business questions in 3 tiers (cohorts, RFM, market basket and more) | ⬜ Not started |
| 4 | Tableau Public | 3-page dashboard: overview, delivery operations, customers and profit | ⬜ Not started |
| 5 | GitHub | README, insights, recommendations | 🟡 Ongoing |

## Progress log

### 16–17 Nov 2026: Phase 1, Excel cleaning (Days 1–2)

Loaded the six CSV files into one workbook ([`excel/Book1.xlsx`](excel/Book1.xlsx)) and cleaned them one table at a time.

**Done**

- **All tables:** trimmed spaces and set proper data types. Dates and timestamps are now real Excel dates, and prices, quantities and fees are numbers.
- **stores (29 rows):** standardised city names (Bangalore / BLR → Bengaluru, Bombay → Mumbai and so on) to 6 cities: Bengaluru 6, Mumbai 6, Delhi 5, Hyderabad 4, Pune 4, Chennai 4. Fixed area names and parsed `opened_on`, which came in 4 date formats.
- **riders (224 rows):** standardised vehicle type (EV → EV Scooter) and employment type (FT → Full-Time). Parsed `joining_date`.
- **products (56 rows):** standardised `category` to 9 categories and converted `mrp` from "₹45" / "Rs. 45" / "45.00" to numbers.
- **customers (6,060 rows):** removed 2 TEST accounts, reduced phone numbers to 10 digits, lower-cased emails and blanked invalid ones, and mapped city and gender to standard values. Parsed `signup_date` and `date_of_birth`.
- **orders (32,000 rows):** removed 384 exact duplicate rows and 10 TEST orders (32,394 → 32,000, all order_ids unique). Standardised `order_status` (Delivered 28,893 · Cancelled 2,461 · Returned 646), `payment_method` and `coupon_code`. Parsed all three timestamps from 3 formats, set out-of-range ratings (0, 6, 10) to blank, and blanked impossible distances (−1, 120.5, 999 km).
- **order_items:** converted `discount` from 10 / "10%" / 0.1 to one scale (0, 5, 10, 15, 20). Checked that every selling price equals `mrp × (1 − discount%)`: 0 mismatches.

**Still open (next session)**

- products: remove the duplicate P1011 row, and estimate and flag the 2 missing cost prices (P1006, P1018).
- customers: merge the 60 people who registered twice (6,060 → 6,000), and blank the 59 `1900-01-01` birth dates and the 68 that are too recent.
- orders: recover the 100 orders with store DS999 / DS000 through the rider's store, move duplicate customers' orders onto the master account, flag 101 orders delivered before they were ordered, the 93 delivered orders with no rider and the 53 with 0 km distance, and add the analysis columns.
- order_items: remove the 923 exact duplicate rows (116,338 → 115,415), flag the 191 lines with unknown products (P9999 / P0000) and the 503 with quantity ≤ 0, and review the 1,153 blank prices.
- targets: unpivot the 12 month columns with Power Query into `targets_long.csv`.

The full issue list, with what was fixed and what is still open, is in [`docs/data_quality_log.md`](docs/data_quality_log.md).

## Repository structure

```
zipbasket-quick-commerce-analytics/
├── data/
│   ├── raw/          # the 7 client files, never edited
│   └── clean/        # exports of the cleaned tables
├── excel/            # Phase 1 cleaning workbook
├── sql/              # Phase 2–3 scripts, run 01 → 10 in order
├── tableau/          # Phase 4 dashboard
├── docs/             # data dictionary, quality log, ERD, screenshots
└── README.md
```

## Tools

Excel (Power Query, XLOOKUP, PivotTables) · PostgreSQL · Tableau Public · Git and GitHub

## About me

**Satvik Mansotra**, entry-level Data Analyst, Gurugram · mansotrasatvik@gmail.com · [GitHub](https://github.com/satvik89010)
