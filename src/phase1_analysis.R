# ============================================================
# Phase 1 Analysis: NHANES 2021-2023
# Question: Smoking and elevated blood pressure in adults 20+
# ============================================================

library(haven)
library(dplyr)
library(survey)
library(ggplot2)

# --- 1. Load raw files ---
demo <- read_xpt("raw_data/DEMO_L.xpt")
bpxo <- read_xpt("raw_data/BPXO_L.xpt")
smq  <- read_xpt("raw_data/SMQ_L.xpt")

# --- 2. Merge (A1) ---
cat("N in DEMO_L:", nrow(demo), "\n")
cat("N in BPXO_L:", nrow(bpxo), "\n")
cat("N in SMQ_L:", nrow(smq), "\n")

df <- demo %>%
  left_join(bpxo, by = "SEQN") %>%
  left_join(smq, by = "SEQN")

cat("N after merge:", nrow(df), "\n")
cat("Unique SEQN after merge:", n_distinct(df$SEQN), "\n")

# --- 3. Define variables ---
df <- df %>%
  mutate(
    # Mean BP (average of available readings)
    sys_mean = rowMeans(select(., BPXOSY1, BPXOSY2, BPXOSY3), na.rm = TRUE),
    dia_mean = rowMeans(select(., BPXODI1, BPXODI2, BPXODI3), na.rm = TRUE),
    
    # Outcome: elevated BP
    BP_HIGH = if_else(sys_mean >= 130 | dia_mean >= 80, 1, 0, missing = NA_real_),
    
    # Exposure: current smoker
    SMOKER = case_when(
      SMQ040 %in% c(1, 2) ~ 1,   # every day or some days
      SMQ040 == 3 ~ 0,            # not at all
      SMQ020 == 2 ~ 0,            # never smoked 100 cigarettes
      TRUE ~ NA_real_
    ),
    
    # Age group for descriptive comparison
    age_group = case_when(
      RIDAGEYR >= 20 & RIDAGEYR <= 39 ~ "20-39",
      RIDAGEYR >= 40 & RIDAGEYR <= 59 ~ "40-59",
      RIDAGEYR >= 60 ~ "60+",
      TRUE ~ NA_character_
    ),
    
    sex = factor(RIAGENDR, levels = c(1, 2), labels = c("Male", "Female"))
  )

# --- 4. Analytic population (A4) ---
cat("\n--- Exclusion flow (A4) ---\n")
cat("Start (after merge):", nrow(df), "\n")

df_adult <- df %>% filter(RIDAGEYR >= 20)
cat("After age >= 20:", nrow(df_adult), "\n")

df_weight <- df_adult %>% filter(!is.na(WTMEC2YR) & WTMEC2YR > 0)
cat("After valid WTMEC2YR:", nrow(df_weight), "\n")

df_final <- df_weight %>% filter(!is.na(BP_HIGH), !is.na(SMOKER))
cat("After non-missing BP_HIGH and SMOKER:", nrow(df_final), "\n")

# --- 5. A2: Explain weights ---
cat("\n--- A2: Weight variables ---\n")
cat("WTMEC2YR = Full sample 2-year MEC exam weight.\n")
cat("Used because the outcome (blood pressure) comes from the MEC exam.\n")
cat("When combining interview (SMQ) and exam (BPXO) data, CDC guidelines say use the weight with the lowest probability of selection — here, MEC weight.\n")

# --- 6. A3: Crude vs weighted ---
# Crude proportion of elevated BP
crude_bp <- mean(df_final$BP_HIGH, na.rm = TRUE)
cat("\n--- A3: Crude vs weighted ---\n")
cat("Crude proportion with elevated BP:", round(crude_bp, 4), "\n")

# Weighted proportion
design <- svydesign(ids = ~SDMVPSU, strata = ~SDMVSTRA,
                    weights = ~WTMEC2YR, data = df_final, nest = TRUE)

weighted_bp <- svymean(~BP_HIGH, design, na.rm = TRUE)
cat("Weighted proportion with elevated BP:", round(coef(weighted_bp), 4), "\n")

# Crude vs weighted by smoking group
cat("\nCrude BP_HIGH by SMOKER:\n")
print(df_final %>% group_by(SMOKER) %>% summarise(
  n = n(),
  crude_prop = mean(BP_HIGH)
))

cat("\nWeighted BP_HIGH by SMOKER:\n")
print(svyby(~BP_HIGH, ~SMOKER, design, svymean, na.rm = TRUE))

# --- 7. Descriptive comparison (Phase 1 requirement) ---
cat("\n--- Descriptive comparison: BP_HIGH by SMOKER ---\n")
# Table: n and crude proportion by smoking status and sex
desc_table <- df_final %>%
  group_by(SMOKER, sex) %>%
  summarise(n = n(), crude_bp = mean(BP_HIGH), .groups = "drop")
print(desc_table)

# --- 8. Figures ---
dir.create("figures", showWarnings = FALSE)

# Boxplot of systolic BP by smoking status
p1 <- ggplot(df_final, aes(x = factor(SMOKER, labels = c("Non-smoker", "Current smoker")),
                           y = sys_mean, fill = factor(SMOKER))) +
  geom_boxplot() +
  labs(title = "Systolic blood pressure by smoking status",
       x = "Smoking status", y = "Mean systolic BP (mmHg)") +
  theme_minimal() +
  theme(legend.position = "none")
ggsave("figures/phase1_sys_bp_by_smoking.png", p1, width = 6, height = 4)

# Bar chart: crude vs weighted proportion
prop_df <- data.frame(
  type = c("Crude", "Weighted"),
  prop = c(crude_bp, coef(weighted_bp))
)
p2 <- ggplot(prop_df, aes(x = type, y = prop, fill = type)) +
  geom_col(width = 0.5) +
  labs(title = "Proportion with elevated BP: crude vs weighted",
       x = "", y = "Proportion") +
  theme_minimal() +
  theme(legend.position = "none")
ggsave("figures/phase1_crude_vs_weighted.png", p2, width = 5, height = 4)

cat("\nFigures saved to figures/.\n")
