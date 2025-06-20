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
AR_train <- AR_train %>% rename(variable4 = `seconds_in_day`)
AR_test  <- AR_test %>% rename(variable4 = `seconds_in_day`)

AR_train <- AR_train %>% rename(variable5 = `Clark`)
AR_test  <- AR_test %>% rename(variable5 = `Clark`)
AR_train <- AR_train %>% rename(variable6 = `Jane`)
AR_test  <- AR_test %>% rename(variable6 = `Jane`)
AR_train <- AR_train %>% rename(variable7 = `Joe`)
AR_test  <- AR_test %>% rename(variable7 = `Joe`)
AR_train <- AR_train %>% rename(variable8 = `Karsten`)
AR_test  <- AR_test %>% rename(variable8 = `Karsten`)


mu_formula <- duration_seconds ~ variable1 + variable2 + variable3 + variable4 + variable5 + variable6 + variable7 + variable8
sigma_formula <- ~ variable1 + variable2 + + variable3 + variable4 + variable5 + variable6 + variable7 + variable8

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
AR_train <- AR_train %>% rename(`seconds_in_day` = variable4)
AR_test  <- AR_test %>% rename(`seconds_in_day` = variable4)

AR_train <- AR_train %>% rename(`Clark` = variable5)
AR_test  <- AR_test %>% rename(`Clark` = variable5)
AR_train <- AR_train %>% rename(`Jane` = variable6)
AR_test  <- AR_test %>% rename(`Jane` = variable6)
AR_train <- AR_train %>% rename(`Joe` = variable7)
AR_test  <- AR_test %>% rename(`Joe` = variable7)
AR_train <- AR_train %>% rename(`Karsten` = variable8)
AR_test  <- AR_test %>% rename(`Karsten` = variable8)

write.csv(AR_train, "../../data/predictions_logno/train_CRDSCC.csv", row.names = FALSE)
write.csv(AR_test, "../../data/predictions_logno/test_CRDSCC.csv", row.names = FALSE)

