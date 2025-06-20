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

BPIC2017_train <- read_csv("../../data/BPIC2017/transformed_event_logs_indexbased/BPIC2017_train.csv")
BPIC2017_test  <- read_csv("../../data/BPIC2017/transformed_event_logs_indexbased/BPIC2017_test.csv")

BPIC2017_train <- BPIC2017_train %>%
  mutate(across(where(is.character), ~ ifelse(is.na(.), "", .)))

BPIC2017_test <- BPIC2017_test %>%
  mutate(across(where(is.character), ~ ifelse(is.na(.), "", .)))


#BPIC2017_train <- BPIC2017_train %>% rename(variable1 = `org:resource_start_1`)
#BPIC2017_test  <- BPIC2017_test %>% rename(variable1 = `org:resource_start_1`)
#BPIC2017_train <- BPIC2017_train %>% rename(variable2 = `org:resource_start_2`)
#BPIC2017_test  <- BPIC2017_test %>% rename(variable2 = `org:resource_start_2`)
#BPIC2017_train <- BPIC2017_train %>% rename(variable3 = `org:resource_start_3`)
#BPIC2017_test  <- BPIC2017_test %>% rename(variable3 = `org:resource_start_3`)

BPIC2017_train <- BPIC2017_train %>% rename(variable4 = `concept:name_1`)
BPIC2017_test  <- BPIC2017_test %>% rename(variable4 = `concept:name_1`)
BPIC2017_train <- BPIC2017_train %>% rename(variable5 = `concept:name_2`)
BPIC2017_test  <- BPIC2017_test %>% rename(variable5 = `concept:name_2`)
BPIC2017_train <- BPIC2017_train %>% rename(variable6 = `concept:name_3`)
BPIC2017_test  <- BPIC2017_test %>% rename(variable6 = `concept:name_3`)


mu_formula <- duration_seconds ~ variable4 + variable5 + variable6
sigma_formula <- ~ variable4 + variable5 + variable6

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

#BPIC2017_train <- BPIC2017_train %>% rename(`org:resource_start_1` = variable1)
#BPIC2017_test  <- BPIC2017_test %>% rename(`org:resource_start_1` = variable1)
#BPIC2017_train <- BPIC2017_train %>% rename(`org:resource_start_2` = variable2)
#BPIC2017_test  <- BPIC2017_test %>% rename(`org:resource_start_2` = variable2)
#BPIC2017_train <- BPIC2017_train %>% rename(`org:resource_start_3` = variable3)
#BPIC2017_test  <- BPIC2017_test %>% rename(`org:resource_start_3` = variable3)

BPIC2017_train <- BPIC2017_train %>% rename(`concept:name_1` = variable4)
BPIC2017_test  <- BPIC2017_test %>% rename(`concept:name_1` = variable4)
BPIC2017_train <- BPIC2017_train %>% rename(`concept:name_2` = variable5)
BPIC2017_test  <- BPIC2017_test %>% rename(`concept:name_2` = variable5)
BPIC2017_train <- BPIC2017_train %>% rename(`concept:name_3` = variable6)
BPIC2017_test  <- BPIC2017_test %>% rename(`concept:name_3` = variable6)

write.csv(BPIC2017_train, "../../data/BPIC2017/predictions_logno_indexbased/train_index.csv", row.names = FALSE)
write.csv(BPIC2017_test, "../../data/BPIC2017/predictions_logno_indexbased/test_index.csv", row.names = FALSE)

