# ============================================================
# Phase 2 Analysis (All-in-One)
# NHANES 2021-2023 | Smoking and Elevated Blood Pressure
# ============================================================

# --- 0. تنظیم مسیر ---
setwd("D:/nhanes-smoking-bp")

# --- 1. نصب و بارگذاری پکیج‌ها ---
if (!require("haven")) install.packages("haven")
if (!require("dplyr")) install.packages("dplyr")
if (!require("survey")) install.packages("survey")
if (!require("ggplot2")) install.packages("ggplot2")

library(haven)
library(dplyr)
library(survey)
library(ggplot2)

# --- 2. بارگذاری و ادغام داده‌ها (فاز ۱) ---
cat("--- Loading and Merging Data ---\n")
demo <- read_xpt("raw_data/DEMO_L.xpt")
bpxo <- read_xpt("raw_data/BPXO_L.xpt")
smq  <- read_xpt("raw_data/SMQ_L.xpt")

df <- demo %>%
  left_join(bpxo, by = "SEQN") %>%
  left_join(smq, by = "SEQN")

cat("N after merge:", nrow(df), "\n")

# --- 3. تعریف متغیرها ---
df <- df %>%
  mutate(
    sys_mean = rowMeans(select(., BPXOSY1, BPXOSY2, BPXOSY3), na.rm = TRUE),
    dia_mean = rowMeans(select(., BPXODI1, BPXODI2, BPXODI3), na.rm = TRUE),
    BP_HIGH = if_else(sys_mean >= 130 | dia_mean >= 80, 1, 0, missing = NA_real_),
    SMOKER = case_when(
      SMQ040 %in% c(1, 2) ~ 1,
      SMQ040 == 3 ~ 0,
      SMQ020 == 2 ~ 0,
      TRUE ~ NA_real_
    ),
    sex = factor(RIAGENDR, levels = c(1, 2), labels = c("Male", "Female"))
  )

# --- 4. جمعیت تحلیلی ---
df_adult <- df %>% filter(RIDAGEYR >= 20)
df_weight <- df_adult %>% filter(!is.na(WTMEC2YR) & WTMEC2YR > 0)
df_final <- df_weight %>% filter(!is.na(BP_HIGH), !is.na(SMOKER))

cat("Final analytic sample:", nrow(df_final), "\n\n")

# ============================================================
# شروع تحلیل‌های فاز ۲
# ============================================================
cat("========================================\n")
cat("PHASE 2 ANALYSES START HERE\n")
cat("========================================\n\n")

# --- تسک ۱ و ۲: احتمال حاشیه‌ای و مشترک ---
cat("--- Joint and Marginal Probabilities ---\n")
prob_smoker   <- mean(df_final$SMOKER == 1)
prob_high_bp  <- mean(df_final$BP_HIGH == 1)
prob_joint    <- mean(df_final$SMOKER == 1 & df_final$BP_HIGH == 1)

cat("P(Smoker) =", round(prob_smoker, 4), "\n")
cat("P(High BP) =", round(prob_high_bp, 4), "\n")
cat("P(Smoker AND High BP) =", round(prob_joint, 4), "\n\n")

# --- تسک ۳ و الف۱: احتمال شرطی ---
cat("--- Conditional Probabilities ---\n")
prob_bp_given_smoker <- prob_joint / prob_smoker
prob_bp_given_nonsmoker <- mean(df_final$SMOKER == 0 & df_final$BP_HIGH == 1) / mean(df_final$SMOKER == 0)

cat("P(High BP | Smoker) =", round(prob_bp_given_smoker, 4), "\n")
cat("P(High BP | Non-Smoker) =", round(prob_bp_given_nonsmoker, 4), "\n")

cat("\nBy Sex:\n")
for (s in c("Male", "Female")) {
  sub <- df_final[df_final$sex == s, ]
  p_s <- mean(sub$SMOKER == 1)
  p_j <- mean(sub$SMOKER == 1 & sub$BP_HIGH == 1)
  p_bp_s <- ifelse(p_s > 0, p_j / p_s, NA)
  p_bp_ns <- mean(sub$SMOKER == 0 & sub$BP_HIGH == 1) / mean(sub$SMOKER == 0)
  cat(s, ": P(BP|Smoker) =", round(p_bp_s, 4), "| P(BP|Non-Smoker) =", round(p_bp_ns, 4), "\n")
}

# --- تسک ۴: استقلال ---
cat("\n--- Independence Check ---\n")
cat("P(Smoker) * P(High BP) =", round(prob_smoker * prob_high_bp, 4), "\n")
cat("Actual P(Smoker AND High BP) =", round(prob_joint, 4), "\n\n")

# --- تسک ۵ و الف۲: دوجمله‌ای ---
cat("--- Binomial Distribution (n=10) ---\n")
for (k in 0:10) {
  cat("P(X =", k, ") =", round(dbinom(k, 10, prob_high_bp), 4), "\n")
}

# --- تسک ۶ و الف۳: نرمال و هیستوگرام ---
cat("\n--- Normal Distribution (Systolic BP) ---\n")
mean_sys <- mean(df_final$sys_mean, na.rm = TRUE)
sd_sys   <- sd(df_final$sys_mean, na.rm = TRUE)
cat("Mean:", round(mean_sys, 2), "| SD:", round(sd_sys, 2), "\n")

dir.create("figures", showWarnings = FALSE)
p_hist <- ggplot(df_final, aes(x = sys_mean)) +
  geom_histogram(aes(y = after_stat(density)), bins = 30, fill = "steelblue", color = "black", alpha = 0.7) +
  stat_function(fun = dnorm, args = list(mean = mean_sys, sd = sd_sys), color = "red", linewidth = 1.2) +
  labs(title = "Distribution of Systolic Blood Pressure", x = "Systolic BP (mmHg)", y = "Density") +
  theme_minimal()
ggsave("figures/phase2_sys_bp_hist.png", p_hist, width = 6, height = 4)

# --- تسک ۷: امید ریاضی و واریانس ---
cat("\n--- Expectation and Variance ---\n")
cat("E[BP_HIGH] =", round(mean(df_final$BP_HIGH), 4), "\n")
cat("Var[BP_HIGH] =", round(var(df_final$BP_HIGH), 4), "\n\n")

# --- تسک ۸: کوواریانس ---
cat("--- Covariance ---\n")
cat("Cov(SMOKER, BP_HIGH) =", round(cov(df_final$SMOKER, df_final$BP_HIGH, use = "complete.obs"), 6), "\n")

p_scatter <- ggplot(df_final, aes(x = RIDAGEYR, y = sys_mean)) +
  geom_point(alpha = 0.2, color = "darkblue") +
  geom_smooth(method = "lm", color = "red", se = FALSE) +
  labs(title = "Systolic BP vs Age", x = "Age (years)", y = "Systolic BP (mmHg)") +
  theme_minimal()
ggsave("figures/phase2_scatter_age_bp.png", p_scatter, width = 6, height = 4)

# --- تسک ۹ و الف۴: بیز و وزن‌دار ---
cat("\n--- Bayes and Weighted Estimates ---\n")
cat("P(Smoker | High BP) =", round((prob_bp_given_smoker * prob_smoker) / prob_high_bp, 4), "\n")

design <- svydesign(ids = ~SDMVPSU, strata = ~SDMVSTRA, weights = ~WTMEC2YR, data = df_final, nest = TRUE)
cat("Weighted P(High BP) =", round(coef(svymean(~BP_HIGH, design, na.rm = TRUE)), 4), "\n")

cat("\n========================================\n")
cat("PHASE 2 COMPLETE.\n")
cat("Figures saved to figures/\n")
cat("========================================\n")