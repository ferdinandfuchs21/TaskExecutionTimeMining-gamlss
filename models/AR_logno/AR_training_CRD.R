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

AR_train <- read_csv("../../data/transformed_event_logs/AR_train.csv")
AR_test  <- read_csv("../../data/transformed_event_logs/AR_test.csv")

AR_train <- AR_train %>% rename(variable1 = `org:resource`)
AR_test  <- AR_test %>% rename(variable1 = `org:resource`)
AR_train <- AR_train %>% rename(variable2 = `concept:name`)
AR_test  <- AR_test %>% rename(variable2 = `concept:name`)
AR_train <- AR_train %>% rename(variable3 = `day_of_week`)
AR_test  <- AR_test %>% rename(variable3 = `day_of_week`)


mu_formula <- duration_seconds ~ variable1 + variable2 + variable3
sigma_formula <- ~ variable1 + variable2 + + variable3

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

AR_train <- AR_train %>% rename(`org:resource` = variable1)
AR_test  <- AR_test %>% rename(`org:resource` = variable1)
AR_train <- AR_train %>% rename(`concept:name` = variable2)
AR_test  <- AR_test %>% rename(`concept:name` = variable2)
AR_train <- AR_train %>% rename(`day_of_week` = variable3)
AR_test  <- AR_test %>% rename(`day_of_week` = variable3)

write.csv(AR_train, "../../data/predictions_logno/train_CRD.csv", row.names = FALSE)
write.csv(AR_test, "../../data/predictions_logno/test_CRD.csv", row.names = FALSE)

