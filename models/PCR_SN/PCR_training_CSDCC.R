library(gamlss)
library(readr)
library(dplyr)
library(ggplot2)
library(Metrics)
library(knitr)
library(gamlss.dist)
library(scoringRules)
library(stats)

distribution_family <- SN1()

PCR_train <- read_csv("../../data/PCR/transformed_event_logs/PCR_train.csv")
PCR_test  <- read_csv("../../data/PCR/transformed_event_logs/PCR_test.csv")

PCR_train <- PCR_train %>% rename(variable1 = `concept:name`)
PCR_test  <- PCR_test %>% rename(variable1 = `concept:name`)
PCR_train <- PCR_train %>% rename(variable2 = `seconds_in_day`)
PCR_test  <- PCR_test %>% rename(variable2 = `seconds_in_day`)
PCR_train <- PCR_train %>% rename(variable3 = `day_of_week`)
PCR_test  <- PCR_test %>% rename(variable3 = `day_of_week`)

PCR_train <- PCR_train %>% rename(variable4 = `timeout`)
PCR_test  <- PCR_test %>% rename(variable4 = `timeout`)
PCR_train <- PCR_train %>% rename(variable5 = `Wait for plate validation`)
PCR_test  <- PCR_test %>% rename(variable5 = `Wait for plate validation`)
PCR_train <- PCR_train %>% rename(variable6 = `Match patient data`)
PCR_test  <- PCR_test %>% rename(variable6 = `Match patient data`)
PCR_train <- PCR_train %>% rename(variable7 = `Receive sample state`)
PCR_test  <- PCR_test %>% rename(variable7 = `Receive sample state`)
PCR_train <- PCR_train %>% rename(variable8 = `Callback timeout`)
PCR_test  <- PCR_test %>% rename(variable8 = `Callback timeout`)
PCR_train <- PCR_train %>% rename(variable9 = `Export to EMS`)
PCR_test  <- PCR_test %>% rename(variable9 = `Export to EMS`)
PCR_train <- PCR_train %>% rename(variable10 = `Export result`)
PCR_test  <- PCR_test %>% rename(variable10 = `Export result`)
PCR_train <- PCR_train %>% rename(variable11 = `Send notification`)
PCR_test  <- PCR_test %>% rename(variable11 = `Send notification`)

mu_formula <- duration_seconds ~ variable1 + variable2 + variable3 + variable4 + variable5 + variable6 + variable7 + variable8 + variable9 + variable10 + variable11
sigma_formula <- ~ 1
nu_formula <- ~ 1


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
    pred_nu = predict(model_gamlss, what = "nu", type = "response")  
  )

PCR_test <- PCR_test %>%
  mutate(
    pred_mu = predict(model_gamlss, what = "mu", type = "response", newdata = PCR_test),
    pred_sigma = predict(model_gamlss, what = "sigma", type = "response", newdata = PCR_test)
    pred_nu = predict(model_gamlss, what = "nu", type = "response")  
  )

PCR_train <- PCR_train %>% rename(`concept:name` = variable1)
PCR_test  <- PCR_test %>% rename(`concept:name` = variable1)
PCR_train <- PCR_train %>% rename(`seconds_in_day` = variable2)
PCR_test  <- PCR_test %>% rename(`seconds_in_day` = variable2)
PCR_train <- PCR_train %>% rename(`day_of_week` = variable3)
PCR_test  <- PCR_test %>% rename(`day_of_week` = variable3)

PCR_train <- PCR_train %>% rename(`timeout` = variable4)
PCR_test  <- PCR_test %>% rename(`timeout` = variable4)
PCR_train <- PCR_train %>% rename(`Wait for plate validation` = variable5)
PCR_test  <- PCR_test %>% rename(`Wait for plate validation` = variable5)
PCR_train <- PCR_train %>% rename(`Match patient data` = variable6)
PCR_test  <- PCR_test %>% rename(`Match patient data` = variable6)
PCR_train <- PCR_train %>% rename(`Receive sample state` = variable7)
PCR_test  <- PCR_test %>% rename(`Receive sample state` = variable7)
PCR_train <- PCR_train %>% rename(`Callback timeout` = variable8)
PCR_test  <- PCR_test %>% rename(`Callback timeout` = variable8)
PCR_train <- PCR_train %>% rename(`Export to EMS` = variable9)
PCR_test  <- PCR_test %>% rename(`Export to EMS` = variable9)
PCR_train <- PCR_train %>% rename(`Export result` = variable10)
PCR_test  <- PCR_test %>% rename(`Export result` = variable10)
PCR_train <- PCR_train %>% rename(`Send notification` = variable11)
PCR_test  <- PCR_test %>% rename(`Send notification` = variable11)

write.csv(PCR_train, "../../data/PCR/predictions_SN/train_CSDCC.csv", row.names = FALSE)
write.csv(PCR_test, "../../data/PCR/predictions_SN/test_CSDCC.csv", row.names = FALSE)

