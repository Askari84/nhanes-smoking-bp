# Data Source and Reconstruction

## Official Source
- **Survey:** NHANES August 2021–August 2023
- **Publisher:** National Center for Health Statistics (NCHS), CDC
- **Access:** https://wwwn.cdc.gov/nchs/nhanes/continuousnhanes/default.aspx?Cycle=2021

## Files Downloaded
| File | Description | Download date |
|---|---|---|
| `DEMO_L.xpt` | Demographic variables and sample weights | [تاریخ دانلود خودت] |
| `BPXO_L.xpt` | Blood pressure – oscillometric measurements | [تاریخ دانلود خودت] |
| `SMQ_L.xpt` | Smoking – cigarette use | [تاریخ دانلود خودت] |

## Reconstruction Steps
1. Download the three `.xpt` files from the CDC page above.
2. Place them in a local folder (not committed to GitHub; add to `.gitignore`).
3. Run `src/phase1_analysis.R`; it merges by `SEQN` and produces `data/analytic_phase1.rds`.

## Note
Raw `.xpt` files are not committed to the repository due to size. The analytic dataset can be rebuilt from the steps above.
