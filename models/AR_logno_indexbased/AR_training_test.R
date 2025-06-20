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

AR_train <- read_csv("../../data/transformed_event_logs_indexbased/AR_train.csv")
AR_test  <- read_csv("../../data/transformed_event_logs_indexbased/AR_test.csv")

AR_train <- AR_train %>%
  mutate(across(where(is.character), ~ ifelse(is.na(.), "", .)))

AR_test <- AR_test %>%
  mutate(across(where(is.character), ~ ifelse(is.na(.), "", .)))


AR_train <- AR_train %>% rename(variable5 = `org:resource_1`)
AR_test  <- AR_test %>% rename(variable5 = `org:resource_1`)
AR_train <- AR_train %>% rename(variable6 = `org:resource_2`)
AR_test  <- AR_test %>% rename(variable6 = `org:resource_2`)
AR_train <- AR_train %>% rename(variable7 = `org:resource_3`)
AR_test  <- AR_test %>% rename(variable7 = `org:resource_3`)



mu_formula <- duration_seconds ~ variable5 + variable6 + variable7 
sigma_formula <- ~variable5 + variable6 + variable7

model_gamlss <- gamlss(
  mu_formula,
  sigma_formula,
  data = AR_train,
  family = distribution_family,
  n.cyc = 500,
  trace = TRUE
)

AR_train <- AR_train %>%
  mutate(
    pred_mu = predict(model_gamlss, what = "mu", type = "response"),
    pred_sigma = predict(model_gamlss, what = "sigma", type = "response")
  )

AR_test <- AR_test %>%
  mutate(
    pred_mu = predict(model_gamlss, what = "mu", type = "response", newdata = AR_test),
    pred_sigma = predict(model_gamlss, what = "sigma", type = "response", newdata = AR_test)
  )

AR_train <- AR_train %>% rename(`org:resource_1` = variable5)
AR_test  <- AR_test %>% rename(`org:resource_1` = variable5)
AR_train <- AR_train %>% rename(`org:resource_2` = variable6)
AR_test  <- AR_test %>% rename(`org:resource_2` = variable6)
AR_train <- AR_train %>% rename(`org:resource_3` = variable7)
AR_test  <- AR_test %>% rename(`org:resource_3` = variable7)


write.csv(AR_train, "../../data/predictions_logno_indexbased/train_test.csv", row.names = FALSE)
write.csv(AR_test, "../../data/predictions_logno_indexbased/test_test.csv", row.names = FALSE)

