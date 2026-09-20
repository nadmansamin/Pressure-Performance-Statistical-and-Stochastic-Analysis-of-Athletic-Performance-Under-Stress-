# Pressure-Performance-Statistical-and-Stochastic-Analysis-of-Athletic-Performance-Under-Stress-

## 📌 Overview
This repository contains the statistical and stochastic analysis of NBA free-throw performance under clutch pressure, covering NBA Regular Season and Playoff data from the **2006–07 to 2015–16** seasons[cite: 8]. Developed as part of the **Random Signals and Processes Lab (EEE 4408)** course at the **Islamic University of Technology (IUT)**, this project evaluates whether athletes experience a significant drop in success probability ("choking") during clutch situations[cite: 8].

Each free throw is modeled as a **Bernoulli random variable**, allowing for the estimation of success probabilities, variance, Wilson confidence intervals, pooled two-proportion $z$-tests, paired $t$-tests, and a 20,000-resample player-level bootstrap analysis[cite: 8].

---

## 🛠️ Key Methodologies & Findings

- **Bernoulli Modeling:** Free throws are evaluated as discrete Bernoulli random variables ($X = 1$ for a make, $X = 0$ for a miss) to compute $E[X]$, $Var(X)$, and 95% Wilson Confidence Intervals[cite: 8].
- **Attempt-Weighted vs. Player-Level Analysis:** 
  - **Attempt-Weighted (Pooled $z$-test):** Regular season clutch shooting is slightly *higher* (+0.72 percentage points, $p = 0.0119$), heavily weighted by high-volume shooters[cite: 8].
  - **Equal-Player Weighting (Paired $t$-test):** The average player's career clutch performance drops slightly by **-1.27 percentage points** ($p = 0.0203$)[cite: 8].
- **Nonparametric Bootstrap Validation:** A 20,000-resample player bootstrap confirms a slight negative career clutch effect (95% CI: `[-2.32, -0.20]` pp)[cite: 8].
- **Sample-Size Instability:** Extreme clutch performance deviations shrink significantly as career clutch attempts increase ($\rho = -0.441$, $p < 0.0001$), demonstrating that outlier "clutch" or "choker" labels are largely artifacts of small sample sizes[cite: 8].
- **Data & Code Integration:** Implemented fully in **MATLAB** (`Pressure_Performance_Final.m`) for end-to-end data processing, arithmetic non-clutch extraction, statistical testing, and automated figure generation[cite: 8].

---

## 📋 Statistical Summary

| Analysis | Weighting | Difference | $p$-value | Conclusion[cite: 8] |
| :--- | :--- | :---: | :---: | :--- |
| **Pooled Regular Bernoulli** | Attempt-weighted | $+0.72$ pp | `0.0119` | Clutch rate is slightly higher when pooling all shots[cite: 8]. |
| **Regular Player-Season** | Equal player-season | $-1.00$ pp | `0.0090` | Statistically significant, but small drop[cite: 8]. |
| **Regular ($\ge 10$ Clutch Att.)** | Equal player-season | $-1.10$ pp | `0.0034` | Small significant drop[cite: 8]. |
| **Career Player-Level** | Equal players | $-1.27$ pp | `0.0203` | Small significant career-level drop[cite: 8]. |
| **Career Bootstrap (20k)** | Equal players | $-1.26$ pp | `0.0088` | 95% CI lies entirely below zero [`-2.32`, `-0.20`][cite: 8]. |
| **Playoff Paired $t$-test** | Equal player-season | $+1.17$ pp | `0.1918` | Not statistically significant; results are noisy[cite: 8]. |

---

## 📁 Repository Structure & Deliverables

- **`Pressure_Performance_Final_Report.pdf`:** Comprehensive final project report[cite: 8].
- **`Pressure_Performance_Final.m`:** Complete MATLAB script executing data cleaning, $z$-tests, paired $t$-tests, bootstrap resampling, and data export[cite: 8].
- **`Starter_FT_Stats_2006_2016_2.xlsx`:** Source dataset comprising 461 player-seasons across 200 unique NBA players[cite: 8].
- **`final_outputs/`:** Automated folder containing output CSV summaries and 7 publication-ready analysis plots[cite: 8].

---

## 👥 Contributors (Group WaveSync)

- **Farhan Tanvir** (230021112)[cite: 8]
- **Nadman Ibne Mamun** (230021114)[cite: 8]
- **Goolam Muktadir Hameem** (230021144)[cite: 8]

**Course Details:** Section A2, Department of EEE, Islamic University of Technology (IUT)[cite: 8]
