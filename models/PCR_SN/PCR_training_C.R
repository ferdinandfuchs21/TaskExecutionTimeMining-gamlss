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

mu_formula <- duration_seconds ~ variable1
sigma_formula <- ~ 1
nu_formula <- ~ 1

model_gamlss <- gamlss(
  mu_formula,
  sigma_formula,
  data = PCR_train,
  family = distribution_family,
  n.cyc = 100,
  trace = TRUE
)

PCR_train <- PCR_train %>%
  mutate(
    pred_mu = predict(model_gamlss, what = "mu", type = "response"),
    pred_sigma = predict(model_gamlss, what = "sigma", type = "response"),
    pred_nu = predict(model_gamlss, what = "nu", type = "response")  
  )

PCR_test <- PCR_test %>%
  mutate(
    pred_mu = predict(model_gamlss, what = "mu", type = "response", newdata = PCR_test),
    pred_sigma = predict(model_gamlss, what = "sigma", type = "response", newdata = PCR_test),
    pred_nu = predict(model_gamlss, what = "nu", type = "response", newdata = PCR_test)  
  )

PCR_train <- PCR_train %>% rename(`concept:name` = variable1)
PCR_test  <- PCR_test %>% rename(`concept:name` = variable1)

write.csv(PCR_train, "../../data/PCR/predictions_SN/train_C.csv", row.names = FALSE)
write.csv(PCR_test, "../../data/PCR/predictions_SN/test_C.csv", row.names = FALSE)

