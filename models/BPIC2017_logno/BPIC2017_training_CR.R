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

BPIC2017_train <- read_csv("../../data/BPIC2017/transformed_event_logs/BPIC2017_train.csv")
BPIC2017_test  <- read_csv("../../data/BPIC2017/transformed_event_logs/BPIC2017_test.csv")

BPIC2017_train <- BPIC2017_train %>% rename(variable1 = `concept:name`)
BPIC2017_test  <- BPIC2017_test %>% rename(variable1 = `concept:name`)
BPIC2017_train <- BPIC2017_train %>% rename(variable2 = `org:resource_start`)
BPIC2017_test  <- BPIC2017_test %>% rename(variable2 = `org:resource_start`)

mu_formula <- duration_seconds ~ variable1 + variable2
sigma_formula <- ~ variable1 + variable2

model_gamlss <- gamlss(
  mu_formula,
  sigma_formula,
  data = BPIC2017_train,
  family = distribution_family,
  n.cyc = 500,
  trace = TRUE
)

BPIC2017_train <- BPIC2017_train %>%
  mutate(
    pred_mu = predict(model_gamlss, what = "mu", type = "response"),
    pred_sigma = predict(model_gamlss, what = "sigma", type = "response")
  )

BPIC2017_test <- BPIC2017_test %>%
  mutate(
    pred_mu = predict(model_gamlss, what = "mu", type = "response", newdata = BPIC2017_test),
    pred_sigma = predict(model_gamlss, what = "sigma", type = "response", newdata = BPIC2017_test)
  )

BPIC2017_train <- BPIC2017_train %>% rename(`concept:name` = variable1)
BPIC2017_test  <- BPIC2017_test %>% rename(`concept:name` = variable1)
BPIC2017_train <- BPIC2017_train %>% rename(`org:resource_start` = variable2)
BPIC2017_test  <- BPIC2017_test %>% rename(`org:resource_start` = variable2)

write.csv(BPIC2017_train, "../../data/BPIC2017/predictions_logno/train_CR.csv", row.names = FALSE)
write.csv(BPIC2017_test, "../../data/BPIC2017/predictions_logno/test_CR.csv", row.names = FALSE)

