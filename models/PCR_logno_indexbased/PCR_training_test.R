library(gamlss)
library(readr)
library(dplyr)
library(ggplot2)
library(Metrics)
library(knitr)
library(gamlss.dist)
library(scoringRules)
library(stats)

distribution_family <- LOGNO()

PCR_train <- read_csv("../../data/PCR/transformed_event_logs_indexbased/PCR_train.csv")
PCR_test  <- read_csv("../../data/PCR/transformed_event_logs_indexbased/PCR_test.csv")

PCR_train <- PCR_train %>%
  mutate(across(where(is.character), ~ ifelse(is.na(.), "", .)))

PCR_test <- PCR_test %>%
  mutate(across(where(is.character), ~ ifelse(is.na(.), "", .)))


PCR_train <- PCR_train %>% rename(variable5 = `concept:name_1`)
PCR_test  <- PCR_test %>% rename(variable5 = `concept:name_1`)
PCR_train <- PCR_train %>% rename(variable6 = `concept:name_2`)
PCR_test  <- PCR_test %>% rename(variable6 = `concept:name_2`)
PCR_train <- PCR_train %>% rename(variable7 = `concept:name_3`)
PCR_test  <- PCR_test %>% rename(variable7 = `concept:name_3`)


mu_formula <- duration_seconds ~ variable5 + variable6 + variable7 
sigma_formula <- ~variable5 + variable6 + variable7

known_levels_5 <- unique(PCR_train$variable5)
known_levels_6 <- unique(PCR_train$variable6)
known_levels_7 <- unique(PCR_train$variable7)

PCR_test <- PCR_test %>%
  filter(
    variable5 %in% known_levels_5,
    variable6 %in% known_levels_6,
    variable7 %in% known_levels_7
  )

model_gamlss <- gamlss(
  mu_formula,
  sigma_formula,
  data = PCR_train,
  family = distribution_family,
  n.cyc = 500,
  trace = TRUE
)

PCR_train <- PCR_train %>%
  mutate(
    pred_mu = predict(model_gamlss, what = "mu", type = "response"),
    pred_sigma = predict(model_gamlss, what = "sigma", type = "response")
  )

PCR_test <- PCR_test %>%
  mutate(
    pred_mu = predict(model_gamlss, what = "mu", type = "response", newdata = PCR_test),
    pred_sigma = predict(model_gamlss, what = "sigma", type = "response", newdata = PCR_test)
  )

PCR_train <- PCR_train %>% rename(`concept:name_1` = variable5)
PCR_test  <- PCR_test %>% rename(`concept:name_1` = variable5)
PCR_train <- PCR_train %>% rename(`concept:name_2` = variable6)
PCR_test  <- PCR_test %>% rename(`concept:name_2` = variable6)
PCR_train <- PCR_train %>% rename(`concept:name_3` = variable7)
PCR_test  <- PCR_test %>% rename(`concept:name_3` = variable7)


write.csv(PCR_train, "../../data/PCR/predictions_logno_indexbased/PCR_train.csv", row.names = FALSE)
write.csv(PCR_test, "../../data/PCR/predictions_logno_indexbased/PCR_test.csv", row.names = FALSE)

