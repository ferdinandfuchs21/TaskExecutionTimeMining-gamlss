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

PCR_train <- read_csv("../../data/PCR/transformed_event_logs/PCR_train.csv")
PCR_test  <- read_csv("../../data/PCR/transformed_event_logs/PCR_test.csv")

PCR_train <- PCR_train %>% rename(variable1 = `concept:name`)
PCR_test  <- PCR_test %>% rename(variable1 = `concept:name`)
PCR_train <- PCR_train %>% rename(variable2 = `seconds_in_day`)
PCR_test  <- PCR_test %>% rename(variable2 = `seconds_in_day`)
PCR_train <- PCR_train %>% rename(variable3 = `day_of_week`)
PCR_test  <- PCR_test %>% rename(variable3 = `day_of_week`)

mu_formula <- duration_seconds ~ variable1 + variable2 + variable3
sigma_formula <- ~ variable1 + variable2 + variable3

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

PCR_train <- PCR_train %>% rename(`concept:name` = variable1)
PCR_test  <- PCR_test %>% rename(`concept:name` = variable1)
PCR_train <- PCR_train %>% rename(`seconds_in_day` = variable2)
PCR_test  <- PCR_test %>% rename(`seconds_in_day` = variable2)
PCR_train <- PCR_train %>% rename(`day_of_week` = variable3)
PCR_test  <- PCR_test %>% rename(`day_of_week` = variable3)

write.csv(PCR_train, "../../data/PCR/predictions_logno/train_CSD.csv", row.names = FALSE)
write.csv(PCR_test, "../../data/PCR/predictions_logno/test_CSD.csv", row.names = FALSE)

