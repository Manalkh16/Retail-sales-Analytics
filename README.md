# 🛍️ Retail Sales Intelligence & Customer Analytics System

> 🚀 **Designed to simulate a real-world Data Analyst role — from raw data to business decisions.**
> End-to-end retail analytics across 824K transactions — from messy Excel to executive Power BI dashboard to £400K in identified revenue opportunities.

[![Python](https://img.shields.io/badge/Python-3.11-3776AB?style=flat&logo=python&logoColor=white)](https://python.org)
[![SQL](https://img.shields.io/badge/SQL-PostgreSQL_14-336791?style=flat&logo=postgresql&logoColor=white)](https://postgresql.org)
[![Power BI](https://img.shields.io/badge/Power_BI-Dashboard-F2C811?style=flat&logo=powerbi&logoColor=black)](https://powerbi.microsoft.com)
[![ML](https://img.shields.io/badge/ML-K--Means_RFM-9C27B0?style=flat&logo=scikit-learn&logoColor=white)](https://scikit-learn.org)
[![Dataset](https://img.shields.io/badge/Dataset-UCI_Online_Retail_II-00897B?style=flat)](https://archive.ics.uci.edu/dataset/502/online+retail+ii)
[![Author](https://img.shields.io/badge/Author-Manal%20Khandelwal-E94560?style=flat)](https://www.linkedin.com/in/manal16/)

---

## 📊 Dashboard Preview

> Built in Power BI Desktop. Slicers on Year, Quarter, and Country enable full self-service analysis for non-technical stakeholders.

### Full Dashboard View
![Dashboard Overview](dashboard/dashboard_overview.png)

### KPI Summary — Revenue · Orders · Customers · AOV
![KPI Section](dashboard/kpi_section.png)

### Revenue Trend & Customer Segment Breakdown
![Revenue Chart](dashboard/revenue_trend_chart.png)

> 📁 All 10 chart PNGs → `/outputs/` &nbsp;|&nbsp; 📥 Power BI file → `dashboard/retail_dashboard.pbix`

---

## ⚡ TL;DR

| | |
|--|--|
| 📦 **Dataset** | 824K cleaned transactions · 38 countries · 2 years (UCI Online Retail II) |
| 🔍 **Key Result** | £400K+ revenue opportunity identified from existing customers — zero new acquisition needed |
| 🛠️ **Tools** | Python (Pandas, Scikit-learn) · PostgreSQL · Power BI · K-Means Clustering |
| 📁 **Deliverables** | 17 SQL queries · 10 charts · RFM segmentation · Revenue forecast · Executive dashboard |

---

## 📌 Project Overview

**Problem:** A UK-based online gift retailer has two years of transaction data and no structured intelligence system — total revenue is tracked, but no one knows which customers are about to churn, which SKUs are silently destroying margin, or which international market is poised to triple in size.

**Approach:** End-to-end analytics pipeline covering data cleaning (Python/Pandas), 17 SQL business queries, 10 EDA visualisations, RFM segmentation, K-Means clustering, revenue forecasting, and a Power BI executive dashboard.

**Outcome:** £400K+ in near-term revenue opportunities surfaced — purely from existing customers and catalogue — with specific, costed recommendations for each finding.

---

## 🎯 Why This Project Matters

Retail companies sit on enormous transaction datasets but rarely extract the strategic intelligence buried inside them. Most businesses can tell you total revenue. Very few can tell you **which customers are about to churn**, **which products to protect at all costs**, or **which market is 3× more profitable per customer than the home market**.

This project answers those questions — the kind asked in board meetings, not just data team standups. It solves three problems every retail analytics team faces:

- **Revenue blind spots:** Knowing November was good is not enough. This project quantifies *why* — which SKUs, which customer cohorts, and which geographies drove the spike — and whether it's repeatable.
- **Customer treatment without segmentation:** Sending the same email to a Champion and a churning customer is expensive and ineffective. This project builds a full RFM segmentation framework so every customer gets the right message.
- **Data without decisions:** Insights that don't connect to a business action are noise. Every finding ends with a specific, costed recommendation.

---

## ❓ Key Business Questions Answered

These are the questions a Head of Retail, CMO, or Commercial Director would actually ask:

1. **Which 20% of customers generate 70%+ of our revenue — and are we at risk of losing them?**
2. **We have nearly 6,000 customers. Which ones haven't bought in 90+ days, and what's the revenue at stake?**
3. **Our Q4 spike is real — but is it the same products and customers each year, or are we flying blind?**
4. **Netherlands is growing fast. Is it big enough to justify a dedicated sales resource?**
5. **We're running email campaigns. Are we sending at the right time, or wasting budget on low-intent windows?**
6. **We have 4,000+ SKUs. How many have never had a repeat buyer?**
7. **What does our Month-2 retention look like? Are we acquiring customers or just renting them?**
8. **If we had to forecast next quarter's revenue, what would the number be — and how confident should we be?**

---

## 🚀 Business Impact Summary

| # | Finding | Revenue / Operational Impact |
|---|---------|------------------------------|
| 1 | 892 "At Risk" customers (90–180 days inactive) with £1.2M combined lifetime value | Win-back campaign at 20% conversion = **£240K recoverable revenue** |
| 2 | Top 20% of customers drive 71.4% of total revenue — no loyalty programme exists | Champions at risk of natural attrition with **zero retention mechanism** |
| 3 | Netherlands grew 61% YoY but receives no differentiated commercial attention | Localised pricing + account manager could **2× the current £285K market** |
| 4 | 847 SKUs with zero repeat purchases across the entire 2-year period | Range rationalisation frees **~15–20% of warehouse space** at negligible revenue cost |
| 5 | Peak trading window Thu 10:00–14:00 shows 12% higher AOV than daily average | Realigning email timing = **est. £60K uplift** on a £500K annual email budget |
| 6 | Month-2 customer retention below 35% across all cohorts | 10-point retention improvement = **£85K incremental annualised revenue** |

---

## 🧰 Tools & Technologies

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Data Cleaning | Python 3.11, Pandas 2.0 | Handle 1M+ rows, engineer RFM features |
| SQL Analysis | PostgreSQL 14 | 17 business queries with window functions & CTEs |
| Visualisation | Matplotlib, Seaborn | 10 chart outputs with annotated business insights |
| Machine Learning | Scikit-learn (K-Means) | 4-cluster RFM customer segmentation |
| Forecasting | NumPy (linear trend) | 3-month revenue forecast with prediction intervals |
| Dashboard | Power BI Desktop | Executive self-service dashboard |
| Version Control | Git / GitHub | Full project version history |

---

## 📊 Dataset

| Property | Detail |
|----------|--------|
| Name | UCI Online Retail II |
| Source | [UCI ML Repository](https://archive.ics.uci.edu/dataset/502/online+retail+ii) |
| Period | Dec 2009 – Dec 2011 |
| Raw Rows | ~1,067,371 invoice lines |
| Clean Rows | ~824,000 (after removing cancellations, nulls, invalid records) |
| Countries | 38 |
| Unique Customers | 5,878 |
| Unique SKUs | ~4,000 |

> 📥 Dataset too large for GitHub — download instructions in [`data/README.md`](data/README.md)

---

## 💡 Key Insights

Each insight follows a business-first format: **Finding → Impact → Action.**

**1. Q4 generates 35–40% of annual revenue in just 12 weeks**
*Impact:* A stock-out during October–November has 3× the P&L impact of one in Q1.
*Action:* Build safety stock at 3× average weekly demand for top 10 SKUs by 1 September each year.

**2. Top 20% of customers account for 71.4% of revenue — with no structured loyalty programme**
*Impact:* Natural annual churn of even 5% of Champions costs an estimated £200K in annual revenue.
*Action:* Launch a tiered loyalty scheme with exclusive early access and free shipping at £150+ AOV.

**3. 892 customers inactive for 90–180 days hold £1.2M in lifetime value**
*Impact:* These are not lost customers — they are lapsed customers, and lapsed customers respond to the right offer.
*Action:* Deploy a 3-email win-back sequence with a 15% discount; 20% reactivation rate = £240K recovered.

**4. Netherlands grew 61% YoY but receives no differentiated market treatment**
*Impact:* At current trajectory, Netherlands becomes a £500K+ market within 24 months — but only with active support.
*Action:* Assign a dedicated account manager, localise top-10 listings into Dutch, test Netherlands-specific pricing.

**5. 847 SKUs (21% of catalogue) have zero repeat purchases in two years**
*Impact:* These SKUs consume storage, complicate fulfilment, and create decision fatigue in the product team.
*Action:* Apply a 12-month sunset rule: any SKU with <5 units sold and zero repeat buyers is discontinued.

**6. Month-2 customer retention is below 35% across every cohort**
*Impact:* The business is acquiring customers it then fails to keep — a classic leaky-bucket problem.
*Action:* Implement Day-7 and Day-30 personalised email sequences. Target: raise Month-2 retention to 45%.

---

## 📚 Key Learnings

- **Advanced SQL patterns:** Window functions (`RANK`, `LAG`, `NTILE`, running totals), multi-step CTEs, cohort analysis, and self-joins for churn detection — mirroring complexity expected in Data Analyst technical interviews.

- **Data cleaning at scale:** Removing 243K invalid rows without losing analytical validity requires deliberate decisions, not just `.dropna()`. Each step is documented with a business justification.

- **Customer segmentation that drives decisions:** RFM scoring and K-Means clustering are only useful if output segments map to distinct commercial actions. This project links each cluster to a specific marketing treatment.

- **Dashboard design as communication:** A Power BI dashboard is not a data dump — it is an argument. Structured to answer three questions in sequence: how are we doing, where and when, and who and what.

- **Business storytelling with data:** The difference between an analyst who gets hired and one who doesn't is rarely technical skill — it's translating a number into a decision. Every insight follows Finding → Impact → Action.

- **End-to-end workflow ownership:** Raw Excel → cleaned CSV → SQL → Python EDA → Power BI → written case study. The complete analyst workflow in one project.

---

## 📂 Folder Structure

```
Retail-Analytics-Project/
│
├── data/
│   ├── README.md                      ← Dataset download instructions
│   ├── online_retail_clean.csv        ← 824K rows after cleaning + feature engineering
│   ├── customer_summary.csv           ← 5,878 customers with RFM scores + segments
│   └── customer_clusters.csv          ← Customer summary + K-Means cluster assignments
│
├── sql/
│   └── retail_analysis.sql            ← 17 annotated business SQL queries
│
├── notebooks/
│   ├── 01_data_cleaning.py            ← Modular cleaning & feature engineering
│   ├── 02_eda_visualisation.py        ← 7 EDA charts with business insights
│   └── 03_advanced_analysis.py        ← Revenue forecast + K-Means clustering
│
├── dashboard/
│   ├── retail_dashboard.pbix          ← Power BI dashboard file
│   ├── dashboard_overview.png         ← Full dashboard screenshot
│   ├── kpi_section.png                ← KPI cards zoom
│   └── revenue_trend_chart.png        ← Revenue trend visual
│
├── outputs/
│   ├── 01_monthly_revenue.png
│   ├── 02_top_products.png
│   ├── 03_country_revenue.png
│   ├── 04_day_of_week.png
│   ├── 05_rfm_segments.png
│   ├── 06_hourly_heatmap.png
│   ├── 07_clv_scatter.png
│   ├── 08_revenue_forecast.png
│   ├── 09_elbow_curve.png
│   └── 10_cluster_scatter.png
│
├── docs/
│   └── case_study.md                  ← Full written case study (recruiter-ready)
│
└── README.md
```

---

## 🚀 How to Run

### 1. Clone the repo
```bash
git clone https://github.com/Manalkh16/Retail-Analytics-Project.git
cd Retail-Analytics-Project
```

### 2. Install dependencies
```bash
pip install pandas numpy matplotlib seaborn scikit-learn openpyxl
```

### 3. Download the dataset
Download `online_retail_II.xlsx` from the [UCI ML Repository](https://archive.ics.uci.edu/dataset/502/online+retail+ii) and place it in the `data/` folder. See [`data/README.md`](data/README.md) for full instructions.

### 4. Run the full pipeline
```bash
python notebooks/01_data_cleaning.py       # Clean data + feature engineering → data/
python notebooks/02_eda_visualisation.py   # Generate 7 EDA charts → outputs/
python notebooks/03_advanced_analysis.py   # Revenue forecast + clustering → outputs/ + data/
```

### 5. SQL Analysis
```sql
-- Load into PostgreSQL
COPY retail_sales FROM 'data/online_retail_clean.csv' CSV HEADER;
-- Run all 17 annotated queries
\i sql/retail_analysis.sql
```

### 6. Power BI Dashboard
Open `dashboard/retail_dashboard.pbix` → update data source path to `data/online_retail_clean.csv` → click Refresh.

---

## 📝 Resume Bullet Points

> **Bullet 1 — End-to-end scope**
> Built an end-to-end retail analytics system processing 824K+ transactions across 38 countries, identifying £400K+ in near-term revenue recovery opportunities through RFM segmentation, cohort retention analysis, and K-Means clustering (Python, SQL, Power BI).

> **Bullet 2 — SQL depth**
> Authored 17 production-grade SQL queries using window functions, CTEs, and cohort analysis to identify that the top 20% of customers drive 71.4% of revenue and 892 at-risk customers hold £1.2M in dormant lifetime value.

> **Bullet 3 — Python pipeline**
> Designed a modular Python data pipeline (Pandas) processing 1M+ raw invoice records, engineering 10 analytical features (RFM scores, temporal decomposition, customer segments) and reducing invalid rows by 22%.

> **Bullet 4 — Business communication**
> Delivered a self-service Power BI executive dashboard enabling commercial and marketing teams to independently analyse revenue trends, customer segments, and product performance — eliminating ad-hoc analyst requests for standard reporting.

---

## 👩‍💻 Author

**Manal Khandelwal** | Data Analyst & Computer Science Graduate (AI/ML)
📍 Jaipur, India

[![LinkedIn](https://img.shields.io/badge/LinkedIn-manal16-0A66C2?style=flat&logo=linkedin)](https://www.linkedin.com/in/manal16/)
[![GitHub](https://img.shields.io/badge/GitHub-Manalkh16-181717?style=flat&logo=github)](https://github.com/Manalkh16)

*B.Tech Computer Science (AI/ML) — Manipal University Jaipur*
*Data Science Intern @ InternPro · Data Analyst Intern @ OnGraph Technologies*

---

*If this project was useful to you, a ⭐ on the repo goes a long way. If you're a recruiter or hiring manager and want to discuss the methodology, [LinkedIn](https://www.linkedin.com/in/manal16/) is the fastest way to reach me.*
