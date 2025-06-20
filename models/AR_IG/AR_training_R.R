library(gamlss)
library(readr)
library(dplyr)
library(ggplot2)
library(Metrics)
library(knitr)
library(gamlss.dist)
library(scoringRules)
library(stats)

distribution_family <- IG()

AR_train <- read_csv("../../data/transformed_event_logs/AR_train.csv")
AR_test  <- read_csv("../../data/transformed_event_logs/AR_test.csv")

AR_train <- AR_train %>% rename(variable1 = `org:resource`)
AR_test  <- AR_test %>% rename(variable1 = `org:resource`)

mu_formula <- duration_seconds ~ variable1
sigma_formula <- ~ variable1

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

write.csv(AR_train, "../../data/predictions_inversegaussian/train_R.csv", row.names = FALSE)
write.csv(AR_test, "../../data/predictions_inversegaussian/test_R.csv", row.names = FALSE)

