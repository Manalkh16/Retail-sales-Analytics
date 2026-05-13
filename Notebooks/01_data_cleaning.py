"""
=============================================================================
 Retail Sales Intelligence & Customer Analytics System
 Notebook 1 — Data Cleaning, Validation & Feature Engineering
=============================================================================
 Author  : Manal Khandelwal
 Dataset : UCI Online Retail II (Dec 2009 – Dec 2011)
 Source  : https://archive.ics.uci.edu/dataset/502/online+retail+ii

 Inputs
 ──────
   Data/online_retail_II.xlsx

 Outputs
 ───────
   Data/online_retail_clean.csv   — 824K cleaned transactions + 15 features
   Data/customer_summary.csv      — 5,878 customers with RFM scores & segments
   Data/data_quality_report.txt   — audit trail of every cleaning decision

 Run
 ───
   python Notebooks/01_data_cleaning.py
=============================================================================
"""

# ── standard library ──────────────────────────────────────────────────
import os
import sys
import warnings
from datetime import datetime
from pathlib import Path

# ── third-party ───────────────────────────────────────────────────────
import pandas as pd
import numpy as np

warnings.filterwarnings("ignore")

# ── project paths (run from repo root) ───────────────────────────────
ROOT         = Path(__file__).resolve().parent.parent
DATA_DIR     = ROOT / "Data"
RAW_FILE     = DATA_DIR / "online_retail_II.xlsx"
CLEAN_OUT    = DATA_DIR / "online_retail_clean.csv"
CUST_OUT     = DATA_DIR / "customer_summary.csv"
REPORT_OUT   = DATA_DIR / "data_quality_report.txt"

DATA_DIR.mkdir(exist_ok=True)


# ─────────────────────────────────────────────────────────────────────
# UTILITIES
# ─────────────────────────────────────────────────────────────────────
class AuditLog:
    """Accumulates cleaning decisions and writes them to a text report."""

    def __init__(self):
        self._lines = []
        self._start = datetime.now()

    def log(self, step: str, rows_before: int, rows_after: int, note: str = ""):
        removed = rows_before - rows_after
        pct     = removed / rows_before * 100 if rows_before else 0
        line    = (
            f"  [{step:<35}]  "
            f"removed {removed:>7,} rows  ({pct:5.1f}%)  "
            f"→ {rows_after:>7,} remaining"
            + (f"  // {note}" if note else "")
        )
        self._lines.append(line)
        print(line)

    def write(self, path: Path) -> None:
        header = (
            "=" * 78 + "\n"
            " DATA QUALITY REPORT — Retail Sales Intelligence System\n"
            f" Generated: {self._start.strftime('%Y-%m-%d %H:%M:%S')}\n"
            "=" * 78 + "\n\n"
            "Cleaning Log\n"
            "────────────\n"
        )
        with open(path, "w") as f:
            f.write(header + "\n".join(self._lines) + "\n")
        print(f"\n  Audit log → {path}")


# ─────────────────────────────────────────────────────────────────────
# STEP 1: LOAD
# ─────────────────────────────────────────────────────────────────────
def load_raw(filepath: Path) -> pd.DataFrame:
    """
    Concatenate both annual sheets from the Online Retail II workbook.

    Customer ID is read as string to preserve any leading zeros that
    would be silently dropped by pandas' default int coercion.
    """
    print("\n── Step 1: Load ─────────────────────────────────────────")
    if not filepath.exists():
        sys.exit(
            f"\n[ERROR] Raw file not found at {filepath}\n"
            "Download it from: https://archive.ics.uci.edu/dataset/502/online+retail+ii\n"
            "Place it in the Data/ folder and re-run.\n"
        )

    sheets = {}
    for sheet in ("Year 2009-2010", "Year 2010-2011"):
        sheets[sheet] = pd.read_excel(
            filepath, sheet_name=sheet, dtype={"Customer ID": str}
        )
        print(f"  {sheet}: {len(sheets[sheet]):>9,} rows")

    df = pd.concat(sheets.values(), ignore_index=True)
    print(f"  Combined total: {len(df):>9,} rows  ×  {df.shape[1]} columns")
    return df


# ─────────────────────────────────────────────────────────────────────
# STEP 2: RAW PROFILE (printed before any changes)
# ─────────────────────────────────────────────────────────────────────
def profile_raw(df: pd.DataFrame) -> None:
    """Print a structured data quality snapshot of the raw frame."""
    print("\n── Step 2: Raw Data Profile ─────────────────────────────")
    print(f"  Shape              : {df.shape}")
    print(f"  Memory             : {df.memory_usage(deep=True).sum() / 1e6:.1f} MB")
    print(f"  Date range         : {df['InvoiceDate'].min()} → {df['InvoiceDate'].max()}")
    print(f"  Unique invoices    : {df['Invoice'].nunique():,}")
    print(f"  Unique customers   : {df['Customer ID'].nunique():,}")
    print(f"  Unique countries   : {df['Country'].nunique():,}")
    print(f"  Cancellations (C-) : {df['Invoice'].astype(str).str.startswith('C').sum():,}")
    print()

    print("  Missing values:")
    missing = df.isnull().sum()
    for col, cnt in missing[missing > 0].items():
        print(f"    {col:<20} : {cnt:>7,}  ({cnt/len(df)*100:.1f}%)")

    print()
    print("  Numeric anomalies:")
    print(f"    Negative Quantity  : {(df['Quantity'] < 0).sum():,}")
    print(f"    Zero/Neg Price     : {(df['Price'] <= 0).sum():,}")
    print(f"    Exact duplicates   : {df.duplicated().sum():,}")


# ─────────────────────────────────────────────────────────────────────
# STEP 3: CLEAN
# ─────────────────────────────────────────────────────────────────────
def clean(df: pd.DataFrame, audit: AuditLog) -> pd.DataFrame:
    """
    Apply seven sequential cleaning steps, logging each to the audit trail.

    Steps
    ─────
    1. Standardise column names → snake_case
    2. Parse InvoiceDate to datetime
    3. Remove cancellations (Invoice prefix 'C')
    4. Drop rows missing Customer ID
    5. Remove invalid Quantity (≤ 0) and Price (≤ 0)
    6. Drop exact duplicate rows
    7. Normalise text fields (strip whitespace, title-case Description)

    Business justification is embedded in each log entry so the audit
    trail is self-documenting for any stakeholder review.
    """
    print("\n── Step 3: Cleaning ─────────────────────────────────────")

    # 3.1  Standardise column names
    df.columns = (
        df.columns
          .str.strip()
          .str.lower()
          .str.replace(" ", "_", regex=False)
          .str.replace(r"[^a-z0-9_]", "", regex=True)
    )

    # 3.2  Parse dates
    df["invoicedate"] = pd.to_datetime(df["invoicedate"], errors="coerce")
    n_bad_dates = df["invoicedate"].isna().sum()
    if n_bad_dates:
        before = len(df)
        df = df.dropna(subset=["invoicedate"])
        audit.log("Unparseable InvoiceDate", before, len(df), "coerce→NaT then drop")

    # 3.3  Cancellations
    before = len(df)
    mask_cancel = df["invoice"].astype(str).str.startswith("C")
    df = df[~mask_cancel].copy()
    audit.log("Cancellation invoices (C-*)", before, len(df),
              "Not revenue events; excluded from sales analysis")

    # 3.4  Missing Customer ID
    before = len(df)
    df = df.dropna(subset=["customer_id"])
    audit.log("Missing Customer ID", before, len(df),
              "No customer → no RFM segmentation or CLV calculation possible")

    # 3.5  Invalid Quantity
    before = len(df)
    df = df[df["quantity"] > 0].copy()
    audit.log("Non-positive Quantity", before, len(df),
              "Returns/adjustments; not forward sales")

    # 3.6  Invalid Price
    before = len(df)
    df = df[df["price"] > 0].copy()
    audit.log("Zero or negative Price", before, len(df),
              "Free samples / pricing errors; distort margin analysis")

    # 3.7  Exact duplicates
    before = len(df)
    df = df.drop_duplicates()
    audit.log("Exact duplicate rows", before, len(df),
              "System duplication artefacts")

    # 3.8  Normalise text
    df["customer_id"]  = df["customer_id"].astype(str).str.strip()
    df["stockcode"]    = df["stockcode"].astype(str).str.strip().str.upper()
    df["description"]  = df["description"].astype(str).str.strip().str.title()
    df["country"]      = df["country"].astype(str).str.strip()

    print(f"\n  ✓ Final clean rows: {len(df):,}")
    return df.reset_index(drop=True)


# ─────────────────────────────────────────────────────────────────────
# STEP 4: FEATURE ENGINEERING
# ─────────────────────────────────────────────────────────────────────
def engineer_features(df: pd.DataFrame) -> pd.DataFrame:
    """
    Derive 15 analytics-ready columns from the cleaned transaction data.

    Financial
    ─────────
    total_price    : quantity × price  (line-level revenue; named to match
                     the original UCI column convention)
    revenue        : alias for total_price (used in all downstream queries)

    Temporal
    ────────
    year, month, quarter, week, day_of_week, hour
    month_name     : abbreviated month label ('Jan' … 'Dec')
    is_weekend     : True for Saturday and Sunday
    day_name       : full day name ('Monday' … 'Sunday')

    Geographic
    ──────────
    country_clean  : normalised country name (maps legacy codes)

    Order-level
    ───────────
    order_id       : string alias for invoice (clarity in GROUP BY)
    """
    print("\n── Step 4: Feature Engineering ─────────────────────────")

    # Financial
    df["total_price"] = (df["quantity"] * df["price"]).round(2)
    df["revenue"]     = df["total_price"]   # convenience alias

    # Temporal
    dt = df["invoicedate"].dt
    df["year"]        = dt.year
    df["month"]       = dt.month
    df["month_name"]  = dt.strftime("%b")
    df["quarter"]     = dt.quarter.map({1: "Q1", 2: "Q2", 3: "Q3", 4: "Q4"})
    df["week"]        = dt.isocalendar().week.astype(int)
    df["day_of_week"] = dt.dayofweek          # 0 = Monday … 6 = Sunday
    df["day_name"]    = dt.strftime("%A")
    df["is_weekend"]  = df["day_of_week"].isin([5, 6])
    df["hour"]        = dt.hour

    # Geographic
    country_map = {
        "EIRE":          "Ireland",
        "RSA":           "South Africa",
        "USA":           "United States",
        "Channel Islands": "Channel Islands",
    }
    df["country_clean"] = df["country"].replace(country_map)

    # Order alias
    df["order_id"] = df["invoice"].astype(str)

    new_cols = ["total_price","revenue","year","month","month_name","quarter",
                "week","day_of_week","day_name","is_weekend","hour",
                "country_clean","order_id"]
    print(f"  ✓ {len(new_cols)} new columns added: {new_cols}")
    return df


# ─────────────────────────────────────────────────────────────────────
# STEP 5: VALIDATION
# ─────────────────────────────────────────────────────────────────────
def validate(df: pd.DataFrame) -> None:
    """
    Post-cleaning assertions.  Raises AssertionError immediately if
    any invariant is violated so downstream scripts never run on bad data.
    """
    print("\n── Step 5: Validation ───────────────────────────────────")
    checks = {
        "No missing customer_id"  : df["customer_id"].notna().all(),
        "No zero/neg revenue"     : (df["revenue"] > 0).all(),
        "No cancellation invoices": ~df["invoice"].astype(str).str.startswith("C").any(),
        "No negative quantity"    : (df["quantity"] > 0).all(),
        "InvoiceDate is datetime" : pd.api.types.is_datetime64_any_dtype(df["invoicedate"]),
        "revenue = qty × price"   : (
            (df["total_price"] - df["quantity"] * df["price"]).abs().max() < 0.01
        ),
    }
    all_pass = True
    for check, result in checks.items():
        status = "✓" if result else "✗ FAILED"
        print(f"  {status}  {check}")
        if not result:
            all_pass = False

    if not all_pass:
        raise AssertionError("Validation failed — review cleaning logic before proceeding.")
    print("\n  All validation checks passed.\n")


# ─────────────────────────────────────────────────────────────────────
# STEP 6: CUSTOMER SUMMARY WITH RFM SCORING
# ─────────────────────────────────────────────────────────────────────
def build_customer_summary(df: pd.DataFrame) -> pd.DataFrame:
    """
    Aggregate to one row per customer and attach RFM scores and segment labels.

    RFM Methodology
    ───────────────
    Snapshot date  = latest InvoiceDate + 1 day (avoids zero recency)
    Recency        = days since last purchase (lower = more recent = better)
    Frequency      = distinct invoice count
    Monetary       = total lifetime revenue

    Scoring        Quintile-based (1–5 per dimension).
                   Recency inverted: 5 = most recent.
                   Ties in Frequency / Monetary broken by rank(method='first').

    RFM Score      R + F + M   range 3–15

    Segments
    ────────
    Champions          : 13–15   (buy often, recently, high spend)
    Loyal Customers    : 10–12
    Potential Loyalists:  7–9
    At Risk            :  5–6    (previously valuable, now inactive)
    Lost               :  3–4    (low score on all dimensions)
    """
    print("── Step 6: Customer Summary & RFM Scoring ───────────────")
    snapshot = df["invoicedate"].max() + pd.Timedelta(days=1)

    cust = (
        df.groupby("customer_id")
          .agg(
              total_revenue    = ("revenue",     "sum"),
              total_orders     = ("order_id",    "nunique"),
              total_items      = ("quantity",    "sum"),
              total_price      = ("total_price", "sum"),
              first_purchase   = ("invoicedate", "min"),
              last_purchase    = ("invoicedate", "max"),
              country          = ("country_clean", "first"),
          )
          .reset_index()
    )

    cust["avg_order_value"]    = (cust["total_revenue"] / cust["total_orders"]).round(2)
    cust["avg_items_per_order"]= (cust["total_items"]   / cust["total_orders"]).round(1)
    cust["recency_days"]       = (snapshot - cust["last_purchase"]).dt.days
    cust["tenure_days"]        = (cust["last_purchase"] - cust["first_purchase"]).dt.days

    # RFM quintile scores
    cust["r_score"] = pd.qcut(
        cust["recency_days"], q=5, labels=[5, 4, 3, 2, 1], duplicates="drop"
    ).astype(int)
    cust["f_score"] = pd.qcut(
        cust["total_orders"].rank(method="first"), q=5, labels=[1, 2, 3, 4, 5]
    ).astype(int)
    cust["m_score"] = pd.qcut(
        cust["total_revenue"].rank(method="first"), q=5, labels=[1, 2, 3, 4, 5]
    ).astype(int)

    cust["rfm_score"] = cust["r_score"] + cust["f_score"] + cust["m_score"]

    def _segment(score: int) -> str:
        if score >= 13: return "Champions"
        if score >= 10: return "Loyal Customers"
        if score >= 7:  return "Potential Loyalists"
        if score >= 5:  return "At Risk"
        return "Lost"

    cust["segment"] = cust["rfm_score"].apply(_segment)

    # Summary
    print(f"  ✓ Customers built : {len(cust):,}")
    print(f"  Snapshot date     : {snapshot.date()}")
    print()
    print("  Segment distribution:")
    dist = cust["segment"].value_counts()
    for seg, cnt in dist.items():
        rev = cust.loc[cust["segment"] == seg, "total_revenue"].sum()
        print(f"    {seg:<22} : {cnt:>5,} customers  |  "
              f"£{rev:>10,.0f} lifetime revenue")

    return cust


# ─────────────────────────────────────────────────────────────────────
# STEP 7: SAVE
# ─────────────────────────────────────────────────────────────────────
def save_outputs(df_clean: pd.DataFrame, df_cust: pd.DataFrame) -> None:
    print("\n── Step 7: Save Outputs ─────────────────────────────────")
    df_clean.to_csv(CLEAN_OUT, index=False)
    df_cust.to_csv(CUST_OUT,   index=False)
    print(f"  ✓ {CLEAN_OUT.name:<35} {df_clean.shape[0]:>8,} rows  × {df_clean.shape[1]} cols"
          f"  ({CLEAN_OUT.stat().st_size / 1e6:.1f} MB)")
    print(f"  ✓ {CUST_OUT.name:<35} {df_cust.shape[0]:>8,} rows  × {df_cust.shape[1]} cols")


# ─────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("=" * 60)
    print(" Retail Sales Intelligence — Module 1: Data Cleaning")
    print("=" * 60)

    audit = AuditLog()

    df_raw   = load_raw(RAW_FILE)
    profile_raw(df_raw)
    df_clean = clean(df_raw, audit)
    df_clean = engineer_features(df_clean)
    validate(df_clean)
    df_cust  = build_customer_summary(df_clean)
    save_outputs(df_clean, df_cust)
    audit.write(REPORT_OUT)

    print("\n" + "=" * 60)
    print(" ✅  Module 1 complete.")
    print("     Next: python Notebooks/02_eda_visualisation.py")
    print("=" * 60)
