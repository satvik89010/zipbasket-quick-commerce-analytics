# Data quality log

Phase 1 (Excel / Power Query). Last updated **17 Nov 2026**.

Counts in the "Open" rows were measured on the current cleaning workbook, `excel/Book1.xlsx`.

**Severity:** High = it changes a headline number (revenue, on-time %) · Medium = it breaks a join or a filter · Low = cosmetic.

| ID | Table.column | Issue | Example | Rows affected | Severity | Action | Status |
|---|---|---|---|---|---|---|---|
| DQ01 | stores.city | Same city spelled several ways | Bangalore, BLR, Bombay | 13 of 29 | High | Map to standard names (map_city) | ✅ Fixed |
| DQ02 | stores.area | Inconsistent case and spacing | HSR LAYOUT | some | Low | Take the area from store_name | ✅ Fixed |
| DQ03 | stores / riders / customers dates | Dates in 4 formats, one of them ambiguous | 2024-03-05, 05/03/2024, 05-Mar-2024, 03/25/2024 | many | Medium | Parse each format; treat ambiguous dd/mm as day first (Indian client) | ✅ Fixed |
| DQ04 | riders.vehicle_type | Spelling variants | EV vs EV Scooter | some | Medium | map_vehicle | ✅ Fixed |
| DQ05 | riders.employment_type | Spelling variants | FT vs Full-Time | some | Medium | map_employment | ✅ Fixed |
| DQ06 | riders.joining_date | Blank joining date | R0105, R0153, R0184 | 3 | Low | Keep as blank, note it | 🟡 Open (decide) |
| DQ07 | products.category | Case and "and" vs "&" variants | SNACKS and munchies | some | Medium | Standardise to 9 categories | ✅ Fixed |
| DQ08 | products.mrp | Price stored as text with currency labels | ₹45, Rs. 45, 45.00 | many | High | Strip labels, convert to number | ✅ Fixed |
| DQ09 | products (all) | Exact duplicate row | P1011 appears twice | 1 | High | Remove duplicate | 🔴 Open |
| DQ10 | products.cost_price | Missing cost price | P1006, P1018 | 2 | High | Estimate from category cost ratio, flag cost_imputed | 🔴 Open |
| DQ11 | customers.customer_id | QA test accounts | TEST… | 2 | High | Remove | ✅ Fixed |
| DQ12 | customers.phone | 5 phone formats, some too short | +91 98765 43210, 09876543210 | many | Low | Keep last 10 digits, invalid → blank | ✅ Fixed |
| DQ13 | customers.email | Upper case and invalid emails | NAME@GMAIL.COM, no @ | many | Low | Lower-case, invalid → blank | ✅ Fixed |
| DQ14 | customers.city / gender | Spelling variants and blanks | M, male; blank gender | many | Medium | map_city, map_gender, blank → Unknown | ✅ Fixed |
| DQ15 | customers (all) | Same person registered twice under 2 IDs | same name + phone | 60 people (6,060 → 6,000) | High | Build customer_id_map, keep the lower ID, move orders | 🔴 Open |
| DQ16 | customers.date_of_birth | System default date | 1900-01-01 | 59 | Medium | Set to blank, flag dob_valid | 🔴 Open |
| DQ17 | customers.date_of_birth | Customer would be too young | born 2010–2024 | 68 | Medium | Set to blank, flag dob_valid | 🔴 Open |
| DQ18 | orders (all) | Exact duplicate rows from a double load | ORD5xxxxx twice | 384 | High | Remove duplicates | ✅ Fixed |
| DQ19 | orders.customer_id | QA test orders | TEST… | 10 | High | Remove | ✅ Fixed |
| DQ20 | orders.order_status | Spelling variants | completed, canceled, cancelled - store | many | High | map_status (+ cancel_reason) | ✅ Fixed |
| DQ21 | orders.payment_method | Case variants | upi, Cash on Delivery | many | Medium | map_payment | ✅ Fixed |
| DQ22 | orders.coupon_code | Case and space variants | ZIP20, zip20, "Zip20 " | many | Medium | Upper-case and trim | ✅ Fixed |
| DQ23 | orders.*_ts | Timestamps in 3 formats | 2025-03-14 18:22:05, 14/03/2025 18:22, Mar 14 2025 06:22PM | many | High | Parse each format (dd/mm format has no seconds) | ✅ Fixed |
| DQ24 | orders.customer_rating | Out-of-range ratings | 0, 6, 10 | 89 | Medium | Set to blank | ✅ Fixed |
| DQ25 | orders.distance_km | Impossible distances | −1, 120.5, 999 | 138 | Medium | Set to blank | ✅ Fixed |
| DQ26 | orders.distance_km | Zero distance | 0 | 53 | Medium | Set to blank, flag is_valid_distance | 🔴 Open |
| DQ27 | orders.store_id | Orphan store IDs | DS999 (49), DS000 (51) | 100 | Medium | Recover from the rider's store; rest → UNKNOWN | 🔴 Open |
| DQ28 | orders.delivered_ts | Delivered before ordered (clock error) | delivered_ts < order_ts | 101 | High | Keep order, blank delivery time, flag | 🔴 Open |
| DQ29 | orders.rider_id | Delivered / returned order with no rider | blank rider_id | 93 | Low | Flag rider_missing, keep | 🔴 Open |
| DQ30 | order_items (all) | Exact duplicate rows | same order_item_id twice | 923 | High | Remove duplicates (116,338 → 115,415) | 🔴 Open |
| DQ31 | order_items.discount | 3 scales for the same value | 10, "10%", 0.1 | many | High | Convert to percent 0–20 | ✅ Fixed |
| DQ32 | order_items.product_id | Orphan product IDs | P9999 (101), P0000 (90) | 191 | Medium | Keep, flag is_valid_product | 🔴 Open |
| DQ33 | order_items.quantity | Zero or negative quantity | 0 (165), −1 (166), −2 (172) | 503 | High | Flag / exclude from revenue | 🔴 Open |
| DQ34 | order_items.unit_selling_price | Blank selling price | blank | 1,153 | High | Recalculate from mrp × (1 − discount%) | 🔴 Open |
| DQ35 | store_monthly_targets | Wide format with title rows | Jan-25 … Dec-25 columns | 29 stores | Medium | Unpivot in Power Query → targets_long.csv | 🔴 Open |

**Assumption:** slash dates where both numbers are 12 or below (for example 03/04/2024) are read as **day first**, because the client is Indian.

**Price check:** every non-blank `unit_selling_price` equals `mrp × (1 − discount% ÷ 100)` to within ₹0.01 (0 mismatches).
