library(gamlss)
library(readr)
library(dplyr)
library(ggplot2)
library(Metrics)
library(knitr)
library(gamlss.dist)
library(scoringRules)
library(stats)

BPIC2017_train <- read_csv("../../data/BPIC2017/transformed_event_logs/BPIC2017_train.csv")
BPIC2017_test  <- read_csv("../../data/BPIC2017/transformed_event_logs/BPIC2017_test.csv")

input_vars <- list(
  var1 = "concept:name",
  var2 = "org:resource_start",
  var3 = "seconds_in_day",
  var4 = "day_of_week",
  var5 = "W_Validate_application",
  var6 = "W_Call_after_offers",
  var7 = "W_Call_incomplete_files",
  var8 = "W_Handle_leads",
  var9 = "W_Complete_application",
  var10 = "W_Assess_potential_fraud",
  var11 = "W_Shortened_completion_"
)
distribution_family <- LOGNO()


rename_for_model <- function(df, var_list) {
  df %>%
    rename(
      variable1 = !!sym(var_list$var1),
      variable2 = !!sym(var_list$var2),
      variable3 = !!sym(var_list$var3),
      variable4 = !!sym(var_list$var4),
      variable5 = !!sym(var_list$var5),
      variable6 = !!sym(var_list$var6),
      variable7 = !!sym(var_list$var7),
      variable8 = !!sym(var_list$var8),
      variable9 = !!sym(var_list$var9),
      variable10 = !!sym(var_list$var10),
      variable11 = !!sym(var_list$var11)
    )
}

BPIC2017_train <- rename_for_model(BPIC2017_train, input_vars)
BPIC2017_test  <- rename_for_model(BPIC2017_test, input_vars)


mu_formula <- duration_seconds ~ variable1 + variable2 + variable3 + variable4 + variable5 + variable6 + variable7 + variable8 + variable9 + variable10 + variable11
sigma_formula <- ~ variable1 + variable2 + variable3 + variable4 + variable5 + variable6 + variable7 + variable8 + variable9 + variable10 + variable11

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

rename_back <- function(df, var_list) {
  df %>%
    rename(
      !!var_list$var1 := variable1,
      !!var_list$var2 := variable2,
      !!var_list$var3 := variable3,
      !!var_list$var4 := variable4,
      !!var_list$var5 := variable5,
      !!var_list$var6 := variable6,
      !!var_list$var7 := variable7,
      !!var_list$var8 := variable8,
      !!var_list$var9 := variable9,
      !!var_list$var10 := variable10,
      !!var_list$var11 := variable11
    )
}

BPIC2017_train <- rename_back(BPIC2017_train, input_vars)
BPIC2017_test  <- rename_back(BPIC2017_test, input_vars)

write.csv(BPIC2017_train, "../../data/BPIC2017/predictions_logno/train_CRDSCC.csv", row.names = FALSE)
write.csv(BPIC2017_test, "../../data/BPIC2017/predictions_logno/test_CRDSCC.csv", row.names = FALSE)
