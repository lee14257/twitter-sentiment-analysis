# Author: LEE, Woochan
# Date: 2021
library(cluster)
library(factoextra)
library(tidyverse)
library(quanteda)
library(seededlda)
library(lubridate)
library(cmu.textstat)

# Multidimensional Analysis (TSLA vs MSFT)

# Create docuscope-tagged, normalized dfm appropriate for MDA
twt_year <- read_csv("PATH_TO_NORMALIZED_DATA") %>% 
  filter(ticker == 'TSLA' | ticker == 'MSFT') %>%
  mutate(
    ticker = as.factor(paste0(ticker, "_", year))
  ) %>% dplyr::select(-year, -sentiment_score, -citationhedged) %>%
  column_to_rownames("doc_id")

# Scree plot to select optimum number of factors
screeplot_mda(twt_year)

# Calculate factor loadings
twt_mda <- mda_loadings(twt_year, n_factors = 5)

# Table for factor loadings in factor1, factor2 and factor3
knitr::kable(attr(twt_mda, 'loadings'), caption = 
               "Foctor loadings for midterm corpus", booktabs = T, 
             linesep = "", digits = 2)

# Compare significance of the three factors
f1_lm <- lm(Factor1 ~ group, data = twt_mda)
names(f1_lm$coefficients) <- names(coef(f1_lm)) %>% str_remove("group")
f2_lm <- lm(Factor2 ~ group, data = twt_mda)
names(f2_lm$coefficients) <- names(coef(f2_lm)) %>% str_remove("group")
f3_lm <- lm(Factor3 ~ group, data = twt_mda)
names(f3_lm$coefficients) <- names(coef(f3_lm)) %>% str_remove("group")
f4_lm <- lm(Factor4 ~ group, data = twt_mda)
names(f4_lm$coefficients) <- names(coef(f4_lm)) %>% str_remove("group")
f5_lm <- lm(Factor5 ~ group, data = twt_mda)
names(f5_lm$coefficients) <- names(coef(f5_lm)) %>% str_remove("group")

# Output results with DF, R squared and F statistics for each factors
jtools::export_summs(f1_lm, f2_lm, f3_lm, f4_lm, f5_lm, statistics = 
                       c(DF = "df.residual", R2 = "r.squared", 
                         "F statistic" = "statistic"), model.names = 
                       c("Factor 1", "Factor 2", "Factor 3", "Factor 4", 
                         "Factor 5"), error_format = "",
                     error_pos = "same")

# Heatmap for factor 1 (chosen)
mda.biber::heatmap_mda(twt_mda, n_factor = 1)