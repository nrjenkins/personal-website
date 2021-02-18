---
title: Multilevel Modeling in Stan
linktitle: Pooling, No Pooling, and Partial Pooling
toc: true
type: docs
date: "2019-05-05T00:00:00+01:00"
draft: false
menu:
  stan:
    parent: Part D Multilevel Models
    weight: 50

markup: mmark

# Prev/next pager order (if `docs_section_pager` enabled in `params.toml`)
weight: 50
---

```{r include = FALSE}
# Set Global Chunk Options ----------------------------------------------------
knitr::opts_chunk$set(
  echo = TRUE,
  warning = FALSE,
  message = FALSE,
  comment = "##",
  R.options = list(width = 70)
)
```


There are a few different ways to model data that contains repeated observations for units over time, or that is nested within groups. First, we could simply pool all the data together and ignore the nested structure (pooling). Second, we could consider observations from each group as entirely independent from observations in other groups (no pooling). Finally, we could use information about the similarity of observations within groups to inform our individual estimates (partial pooling).


# Import Data

```{r}
library(arm)
library(rstanarm)
library(tidyverse)
data("radon")
```


# Pooling

Let's start with the pooling estimates. As a point of reference, we'll fit a frequentist model first.

## Frequentist Fit

```{r fig.height = 10, fig.width = 8}
# fit model
pooling.fit <- lm(formula = log_radon ~ floor, data = radon)

# print results
library(broom)
tidy(pooling.fit, conf.int = TRUE)

# calculate fitted values
radon$pooling.fit <- fitted(pooling.fit)

# plot the model results
ggplot(data = radon, aes(x = as_factor(floor), y = log_radon, group = county)) +
  geom_line(aes(y = pooling.fit), color = "black") +
  geom_point(alpha = 0.3,
             size = 3,
             position = position_jitter(width = 0.1, height = 0.2)) +
  facet_wrap(~ county) +
  ggpubr::theme_pubr()
```

## Bayesian Fit

Program the model in Stan.

```{stan output.var = "pooling.model"}
data {
  int n; // number of observations
  vector[n] log_radon;
  vector[n] vfloor;
}

parameters {
  real alpha; // intercept parameter
  real beta; // slope parameter
  real sigma; // variance parameter
}

model {
  // conditional mean
  vector[n] mu;

  // linear combination
  mu = alpha + beta * vfloor;

  // priors
  alpha ~ normal(0, 100);
  beta ~ normal(0, 100);
  sigma ~ uniform(0, 100);

  // likelihood function
  log_radon ~ normal(mu, sigma);
}

generated quantities {
  vector[n] log_lik; // calculate log-likelihood
  vector[n] y_rep; // replications from posterior predictive distribution

  for (i in 1:n) {
    // generate mpg predicted value
    real log_radon_hat = alpha + beta * vfloor[i];

    // calculate log-likelihood
    log_lik[i] = normal_lpdf(log_radon[i] | log_radon_hat, sigma);
    // normal_lpdf is the log of the normal probability density function

    // generate replication values
    y_rep[i] = normal_rng(log_radon_hat, sigma);
    // normal_rng generates random numbers from a normal distribution
  }
}
```

Now we fit this model:

```{r fig.height = 10, fig.width = 8}
library(rstan)

# prepare data for stan
library(tidybayes)
stan.data <-
  radon %>%
  rename(vfloor = floor) %>%
  dplyr::select(log_radon, vfloor) %>%
  compose_data()

# fit stan model
stan.pooling.fit <- sampling(pooling.model,
                             data = stan.data,
                             iter = 1000,
                             warmup = 500)
tidy(stan.pooling.fit, conf.int = TRUE)

stan.pooling.values <-
  stan.pooling.fit %>% # use this model fit
  spread_draws(alpha, beta, sigma) %>% # extract samples in tidy format
  median_hdci() # calculate the median HDCI

# plot the model results for the median estimates
ggplot(data = radon, aes(x = floor, y = log_radon, group = county)) +
  geom_abline(data = stan.pooling.values,
            aes(intercept = alpha, slope = beta), color = "black") +
  geom_point(alpha = 0.3,
             size = 3,
             position = position_jitter(width = 0.1, height = 0.2)) +
  facet_wrap(~ county) +
  ggpubr::theme_pubr()

# plot the model results with posterior samples
stan.pooling.samples <-
  stan.pooling.fit %>% # use this model fit
  spread_draws(alpha, beta, sigma, n = 20) # extract 20 samples in tidy format

ggplot() +
  geom_abline(data = stan.pooling.samples,
            aes(intercept = alpha, slope = beta),
            color = "black",
            alpha = 0.3) +
  geom_point(data = radon,
             aes(x = floor, y = log_radon, group = county),
             alpha = 0.3,
             size = 3,
             position = position_jitter(width = 0.1, height = 0.2)) +
  facet_wrap(~ county) +
  ggpubr::theme_pubr()
```


# No Pooling

Now lets move to the no pooling estimates. These are sometimes referred to as "fixed-effects" by economists because you control for grouped data structures by including indicator variables to the grouping units. To give you a reference point, we'll fit this model in a frequentist framework first.  

## Frequentist Fit

```{r fig.height = 10, fig.width = 8}
# fit the model without an intercept to include all 85 counties
no.pooling.fit <- lm(formula = log_radon ~ floor + as_factor(county) - 1,
                     data = radon)

# print results
tidy(no.pooling.fit, conf.int = TRUE)

# calculate fitted values
radon$no.pooling.fit <- fitted(no.pooling.fit)

# plot the model results
ggplot(data = radon, aes(x = as_factor(floor), y = log_radon, group = county)) +
  geom_line(aes(y = pooling.fit), color = "black") +
  geom_line(aes(y = no.pooling.fit), color = "red") + # add no pooling estimates
  geom_point(alpha = 0.3,
             size = 3,
             position = position_jitter(width = 0.1, height = 0.2)) +
  facet_wrap(~ county) +
  ggpubr::theme_pubr()
```

## Bayesian Fit

Program the model in Stan.

```{stan output.var = "no.pooling.model"}
data {
  int n; // number of observations
  int n_county; // number of counties
  vector[n] log_radon;
  vector[n] vfloor;
  int<lower = 0, upper = n_county> county[n];  
}

parameters {
  vector[n_county] alpha; // vector of county intercepts
  real beta; // slope parameter
  real<lower = 0> sigma; // variance parameter
}

model {
  // conditional mean
  vector[n] mu;

  // linear combination
  mu = alpha[county] + beta * vfloor;

  // priors
  alpha ~ normal(0, 100);
  beta ~ normal(0, 100);
  sigma ~ uniform(0, 100);

  // likelihood function
  log_radon ~ normal(mu, sigma);
}

generated quantities {
  vector[n] log_lik; // calculate log-likelihood
  vector[n] y_rep; // replications from posterior predictive distribution

  for (i in 1:n) {
    // generate mpg predicted value
    real log_radon_hat = alpha[county[i]] + beta * vfloor[i];

    // calculate log-likelihood
    log_lik[i] = normal_lpdf(log_radon[i] | log_radon_hat, sigma);
    // normal_lpdf is the log of the normal probability density function

    // generate replication values
    y_rep[i] = normal_rng(log_radon_hat, sigma);
    // normal_rng generates random numbers from a normal distribution
  }
}
```

Now we fit this model:

```{r fig.height = 10, fig.width = 8}
# prepare data for stan
stan.data <-
  radon %>%
  rename(vfloor = floor) %>%
  dplyr::select(log_radon, vfloor, county) %>%
  compose_data()

# fit stan model
stan.no.pooling.fit <- sampling(no.pooling.model,
                                data = stan.data,
                                iter = 1000,
                                warmup = 500)
tidy(stan.no.pooling.fit, conf.int = TRUE)

stan.nopool.values <-
  stan.no.pooling.fit %>% # use this model fit
  recover_types(radon) %>% # this matches indexes to original factor levels
  spread_draws(alpha[county], beta, sigma) %>% # extract samples in tidy format
  median_hdci() # calculate the median HDCI

# plot the model results for the median estimates
ggplot(data = radon, aes(x = floor, y = log_radon, group = county)) +
  geom_abline(data = stan.pooling.values,
            aes(intercept = alpha, slope = beta), color = "black") +
  # add the new estimates in red
  geom_abline(data = stan.nopool.values,
            aes(intercept = alpha, slope = beta), color = "red") +
  geom_point(alpha = 0.3,
             size = 3,
             position = position_jitter(width = 0.1, height = 0.2)) +
  facet_wrap(~ county) +
  scale_color_manual(values = c("No Pooling", "Pooling")) +
  ggpubr::theme_pubr()

# plot the model results with posterior samples
stan.nopooling.samples <-
  stan.no.pooling.fit %>% # use this model fit
  recover_types(radon) %>%
  spread_draws(alpha[county], beta, sigma, n = 20) # extract 20 samples in tidy format

ggplot() +
  geom_abline(data = stan.pooling.samples,
            aes(intercept = alpha, slope = beta),
            color = "black",
            alpha = 0.3) +
  geom_abline(data = stan.nopooling.samples,
            aes(intercept = alpha, slope = beta),
            color = "red",
            alpha = 0.3) +
  geom_point(data = radon,
             aes(x = floor, y = log_radon, group = county),
             alpha = 0.3,
             size = 3,
             position = position_jitter(width = 0.1, height = 0.2)) +
  facet_wrap(~ county) +
  ggpubr::theme_pubr()
```


# Partial Pooling

Now lets use a partial pooling model to estimate the relationship between a floor measurement and log radon level. As opposed to no pooling models, which essentially estimate a separate regression for each group, partial pooling models use information about the variance between groups get produce more accurate estimates for units within groups. So, for example, in counties were there are only 2 observations the partial pooling model will pull the floor estimates towards the mean of the full sample. This leads to less over fitting and more accurate predictions. Partial pooling models are more commonly known as multilevel or hierarchical models.

## Frequentist Fit

Let's fit the partial pooling model in a frequentist framework:

```{r fig.height = 10, fig.width = 8}
library(lme4)
library(broom.mixed)

# fit the model
partial.pooling.fit <- lmer(formula = log_radon ~ floor + (1 | county),
                            data = radon)

# print results
tidy(partial.pooling.fit, conf.int = TRUE)

# calculate fitted values
radon$partial.pooling.fit <- fitted(partial.pooling.fit)

# plot the model results
ggplot(data = radon, aes(x = as_factor(floor), y = log_radon, group = county)) +
  geom_line(aes(y = pooling.fit), color = "black") +
  geom_line(aes(y = no.pooling.fit), color = "red") + # add no pooling estimates
  geom_line(aes(y = partial.pooling.fit), color = "blue") + # add partial pooling estimates
  geom_point(alpha = 0.3,
             size = 3,
             position = position_jitter(width = 0.1, height = 0.2)) +
  facet_wrap(~ county) +
  ggpubr::theme_pubr()
```

## Bayesian Fit

Program the model in Stan.

```{stan output.var = "partial.pooling.model"}
data {
  int n; // number of observations
  int n_county; // number of counties
  vector[n] log_radon;
  vector[n] vfloor;
  int<lower = 0, upper = n_county> county[n];  
}

parameters {
  vector[n_county] alpha; // vector of county intercepts
  real beta; // slope parameter
  real<lower = 0> sigma_a; // variance of counties
  real<lower = 0> sigma_y; // model residual variance
  real mu_a; // mean of counties
}

model {
  // conditional mean
  vector[n] mu;

  // linear combination
  mu = alpha[county] + beta * vfloor;

  // priors
  beta ~ normal(0, 1);

  // hyper-priors
  mu_a ~ normal(0, 1);
  sigma_a ~ cauchy(0, 2.5);
  sigma_y ~ cauchy(0, 2.5);

  // level-2 likelihood
  alpha ~ normal(mu_a, sigma_a);

  // level-1 likelihood
  log_radon ~ normal(mu, sigma_y);
}

generated quantities {
  vector[n] log_lik; // calculate log-likelihood
  vector[n] y_rep; // replications from posterior predictive distribution

  for (i in 1:n) {
    // generate mpg predicted value
    real log_radon_hat = alpha[county[i]] + beta * vfloor[i];

    // calculate log-likelihood
    log_lik[i] = normal_lpdf(log_radon[i] | log_radon_hat, sigma_y);
    // normal_lpdf is the log of the normal probability density function

    // generate replication values
    y_rep[i] = normal_rng(log_radon_hat, sigma_y);
    // normal_rng generates random numbers from a normal distribution
  }
}
```

Now we fit this model:

```{r fig.height = 10, fig.width = 8}
# prepare data for stan
stan.data <-
  radon %>%
  rename(vfloor = floor) %>%
  dplyr::select(log_radon, vfloor, county) %>%
  compose_data()

# fit stan model
stan.partial.pooling.fit <- sampling(partial.pooling.model,
                                     data = stan.data,
                                     iter = 1000,
                                     warmup = 500)
tidy(stan.partial.pooling.fit, conf.int = TRUE)

stan.partialpool.values <-
  stan.partial.pooling.fit %>% # use this model fit
  recover_types(radon) %>% # this matches indexes to original factor levels
  spread_draws(alpha[county], beta, sigma_a, sigma_y) %>% # extract samples in tidy format
  median_hdci() # calculate the median HDCI

# plot the model results for the median estimates
ggplot(data = radon, aes(x = floor, y = log_radon, group = county)) +
  geom_abline(data = stan.pooling.values,
            aes(intercept = alpha, slope = beta), color = "black") +
  # no pooling estimates in red
  geom_abline(data = stan.nopool.values,
            aes(intercept = alpha, slope = beta), color = "red") +
  # partial pooling estimates in blue
  geom_abline(data = stan.partialpool.values,
            aes(intercept = alpha, slope = beta), color = "blue") +
  geom_point(alpha = 0.3,
             size = 3,
             position = position_jitter(width = 0.1, height = 0.2)) +
  facet_wrap(~ county) +
  scale_color_manual(values = c("No Pooling", "Pooling")) +
  ggpubr::theme_pubr()

# plot the model results with posterior samples
stan.partialpool.samples <-
  stan.partial.pooling.fit %>% # use this model fit
  recover_types(radon) %>%
  spread_draws(alpha[county], beta, sigma_a, sigma_y, n = 20) # extract 20 samples in tidy format

ggplot() +
  geom_abline(data = stan.pooling.samples,
            aes(intercept = alpha, slope = beta),
            color = "black",
            alpha = 0.3) +
  geom_abline(data = stan.nopooling.samples,
            aes(intercept = alpha, slope = beta),
            color = "red",
            alpha = 0.3) +
  geom_abline(data = stan.partialpool.samples,
            aes(intercept = alpha, slope = beta),
            color = "blue",
            alpha = 0.3) +
  geom_point(data = radon,
             aes(x = floor, y = log_radon, group = county),
             alpha = 0.3,
             size = 3,
             position = position_jitter(width = 0.1, height = 0.2)) +
  facet_wrap(~ county) +
  ggpubr::theme_pubr()
```

# Adding Group-level Predictors

Partial pooling also allow us to include group-level predictor variables which can dramatically improve the model's predictions. Let's add a group-level predictor to the model. For a group-level predictor, let's add a measure of the county's uranium level.

## Frequentist Fit

In frequentist, we can fit this model as follows:

```{r fig.height = 10, fig.width = 8}
# fit model
partial.pooling.fit.02 <- lmer(formula = log_radon ~ floor + log_uranium + (1 | county),
                               data = radon)

# print model results
tidy(partial.pooling.fit.02, conf.int = TRUE)

# calculate fitted values
radon$partial.pooling.fit.02 <- fitted(partial.pooling.fit.02)

# plot the model results
ggplot(data = radon, aes(x = as_factor(floor), y = log_radon, group = county)) +
  geom_line(aes(y = pooling.fit), color = "black") +
  geom_line(aes(y = no.pooling.fit), color = "red") + # add no pooling estimates
  # partial pooling with group-level predictor in dashed purple
  geom_line(aes(y = partial.pooling.fit.02), color = "purple", lty = 2) +
  # partial pooling without group-level predictors in blue
  geom_line(aes(y = partial.pooling.fit), color = "blue") + # add partial pooling estimates
  geom_point(alpha = 0.3,
             size = 3,
             position = position_jitter(width = 0.1, height = 0.2)) +
  facet_wrap(~ county) +
  ggpubr::theme_pubr()
```

## Bayesian Fit

To program this model in Stan, we'll use the transformed parameters block to create a conditional mean equation for the level 2 model.

```{stan output.var = "partial.pooling.model.02"}
data {
  int n; // number of observations
  int n_county; // number of counties
  vector[n] log_radon;
  vector[n] vfloor;
  vector[n] log_uranium;
  int<lower = 0, upper = n_county> county[n];  
}

parameters {
  vector[n_county] alpha; // vector of county intercepts
  real b_floor; // slope parameter
  real b_uranium;
  real<lower = 0> sigma_a; // variance of counties
  real<lower = 0> sigma_y; // model residual variance
  real mu_a; // mean of counties
}

model {
  // conditional mean
  vector[n] mu;

  // linear combination
  mu = alpha[county] + b_floor * vfloor + b_uranium * log_uranium;

  // priors
  b_floor ~ normal(0, 100);
  b_uranium ~ normal(0, 100);

  // hyper-priors
  mu_a ~ normal(0, 10);
  sigma_a ~ cauchy(0, 2.5);
  sigma_y ~ cauchy(0, 2.5);

  // level-2 likelihood
  alpha ~ normal(mu_a, sigma_a);

  // level-1 likelihood
  log_radon ~ normal(mu, sigma_y);
}

generated quantities {
  vector[n] log_lik; // calculate log-likelihood
  vector[n] y_rep; // replications from posterior predictive distribution

  for (i in 1:n) {
    // generate mpg predicted value
    real log_radon_hat = alpha[county[i]] + b_floor * vfloor[i] + b_uranium * log_uranium[i];

    // calculate log-likelihood
    log_lik[i] = normal_lpdf(log_radon[i] | log_radon_hat, sigma_y);
    // normal_lpdf is the log of the normal probability density function

    // generate replication values
    y_rep[i] = normal_rng(log_radon_hat, sigma_y);
    // normal_rng generates random numbers from a normal distribution
  }
}
```

Now we fit this model:

```{r fig.height = 10, fig.width = 8}
# prepare data for stan
stan.data <-
  radon %>%
  rename(vfloor = floor) %>%
  dplyr::select(log_radon, vfloor, county, log_uranium) %>%
  compose_data()

# fit stan model
stan.partial.pooling.model.02 <- sampling(partial.pooling.model.02,
                                          data = stan.data,
                                          iter = 1000,
                                          warmup = 500)
tidy(stan.partial.pooling.model.02, conf.int = TRUE)

stan.partialpool.02.values <-
  stan.partial.pooling.model.02 %>% # use this model fit
  recover_types(radon) %>% # this matches indexes to original factor levels
  spread_draws(alpha[county], b_floor, b_uranium, sigma_a, sigma_y) %>% # extract samples in tidy format
  median_hdci() # calculate the median HDCI

# plot the model results for the median estimates
ggplot(data = radon, aes(x = floor, y = log_radon, group = county)) +
  geom_abline(data = stan.pooling.values,
            aes(intercept = alpha, slope = beta), color = "black") +
  # no pooling estimates in red
  geom_abline(data = stan.nopool.values,
            aes(intercept = alpha, slope = beta), color = "red") +
  # partial pooling estimates in blue
  geom_abline(data = stan.partialpool.values,
            aes(intercept = alpha, slope = beta), color = "blue") +
  geom_abline(data = stan.partialpool.02.values,
            aes(intercept = alpha, slope = b_floor), color = "purple", lty = 2) +
  geom_point(alpha = 0.3,
             size = 3,
             position = position_jitter(width = 0.1, height = 0.2)) +
  facet_wrap(~ county) +
  scale_color_manual(values = c("No Pooling", "Pooling")) +
  ggpubr::theme_pubr()

# plot the model results with posterior samples
stan.partialpool.02.samples <-
  stan.partial.pooling.model.02 %>% # use this model fit
  recover_types(radon) %>%
  spread_draws(alpha[county], b_floor, b_uranium, sigma_a, sigma_y, n = 20) # extract 20 samples in tidy format

ggplot() +
  geom_abline(data = stan.pooling.samples,
            aes(intercept = alpha, slope = beta),
            color = "black",
            alpha = 0.3) +
  geom_abline(data = stan.nopooling.samples,
            aes(intercept = alpha, slope = beta),
            color = "red",
            alpha = 0.3) +
  geom_abline(data = stan.partialpool.samples,
            aes(intercept = alpha, slope = beta),
            color = "blue",
            alpha = 0.3) +
  geom_abline(data = stan.partialpool.02.samples,
            aes(intercept = alpha, slope = b_floor),
            color = "purple",
            lty = 2,
            alpha = 0.3) +
  geom_point(data = radon,
             aes(x = floor, y = log_radon, group = county),
             alpha = 0.3,
             size = 3,
             position = position_jitter(width = 0.1, height = 0.2)) +
  facet_wrap(~ county) +
  ggpubr::theme_pubr()
```

# Varying Slope Model

There's no reason that we need to estimate the same slope for every county, and partial pooling models allow us to let the slopes parameters vary between counties. Let's estimate a final model where we let the effect of `floor` vary between counties.

## Frequentist Fit

```{r fig.height = 10, fig.width = 8}
# fit model
partial.pooling.fit.03 <- lmer(formula = log_radon ~ floor + log_uranium +
                                 (1 + floor | county),
                               data = radon)

# print model results
tidy(partial.pooling.fit.03, conf.int = TRUE)

# calculate fitted values
radon$partial.pooling.fit.03 <- fitted(partial.pooling.fit.03)

# plot the model results
ggplot(data = radon, aes(x = as_factor(floor), y = log_radon, group = county)) +
  geom_line(aes(y = pooling.fit), color = "black") +
  geom_line(aes(y = no.pooling.fit), color = "red") + # add no pooling estimates
  # partial pooling with group-level predictor in dashed purple
  geom_line(aes(y = partial.pooling.fit.02), color = "purple", lty = 2) +
  # partial pooling without group-level predictors in blue
  geom_line(aes(y = partial.pooling.fit), color = "blue") + # add partial pooling estimates
  geom_line(aes(y = partial.pooling.fit.03), color = "green") +
  geom_point(alpha = 0.3,
             size = 3,
             position = position_jitter(width = 0.1, height = 0.2)) +
  facet_wrap(~ county) +
  ggpubr::theme_pubr()
```

## Bayesian Fit

To program this model in Stan, we'll need to include the variance covariance matrix for the varying intercept and slope parameters.

```{stan output.var = "partial.pooling.model.03"}
data {
  int n; // number of observations
  int n_county; // number of counties
  int<lower = 0, upper = n_county> county[n];

  // level 1 variables
  vector[n] log_radon;
  int vfloor[n];

  // level 2 variables
  real log_uranium[n];
}

parameters {
  vector[n_county] b_floor;
  vector[n_county] a_county;
  real b_uranium;
  real a;
  real b;
  vector<lower=0>[2] sigma_county;
  real<lower=0> sigma;
  corr_matrix[2] Rho;
}

model {
  // contidional mean
  vector[n] mu;

  // varying slopes and varying intercepts component
  {
  // vector for intercept mean and slope mean
  vector[2] YY[n_county];
  vector[2] MU;
  MU = [a , b]';
  for (j in 1:n_county) YY[j] = [a_county[j], b_floor[j]]';
    YY ~ multi_normal(MU , quad_form_diag(Rho , sigma_county));
  }

  // linear model
  for (i in 1:n) {
    mu[i] = a_county[county[i]] + b_floor[county[i]] * vfloor[i] + b_uranium * log_uranium[i];
  }

  // priors
  sigma ~ exponential(3);
  b_uranium ~ normal(0 , 100);

  // hyper-priors
  Rho ~ lkj_corr(1);
  sigma_county ~ exponential(3);
  b ~ normal(0 , 100);
  a ~ normal(0 , 100);

  // likelihood
  log_radon ~ normal(mu , sigma);
}

generated quantities {
  vector[n] log_lik; // calculate log-likelihood
  vector[n] y_rep; // replications from posterior predictive distribution

  for (i in 1:n) {
    // generate mpg predicted value
    real log_radon_hat = a_county[county[i]] + b_floor[county[i]] * vfloor[i] + b_uranium * log_uranium[i];

    // calculate log-likelihood
    log_lik[i] = normal_lpdf(log_radon[i] | log_radon_hat, sigma);
    // normal_lpdf is the log of the normal probability density function

    // generate replication values
    y_rep[i] = normal_rng(log_radon_hat, sigma);
    // normal_rng generates random numbers from a normal distribution
  }
}
```

Now we fit this model:

```{r fig.height = 10, fig.width = 8}
# prepare data for stan
stan.data <-
  radon %>%
  rename(vfloor = floor) %>%
  dplyr::select(log_radon, vfloor, county, log_uranium) %>%
  compose_data()

# fit stan model
stan.partial.pooling.model.03 <- sampling(partial.pooling.model.03,
                                          data = stan.data)
tidy(stan.partial.pooling.model.03, conf.int = TRUE)

stan.partialpool.03.values <-
  stan.partial.pooling.model.03 %>% # use this model fit
  recover_types(radon) %>% # this matches indexes to original factor levels
  spread_draws(a_county[county], b_floor[county], b_uranium, sigma_county[], sigma) %>% # extract samples in tidy format
  median_hdci() # calculate the median HDCI

# plot the model results for the median estimates
ggplot(data = radon, aes(x = floor, y = log_radon, group = county)) +
  geom_abline(data = stan.pooling.values,
            aes(intercept = alpha, slope = beta), color = "black") +
  # no pooling estimates in red
  geom_abline(data = stan.nopool.values,
            aes(intercept = alpha, slope = beta), color = "red") +
  # partial pooling estimates in blue
  geom_abline(data = stan.partialpool.values,
            aes(intercept = alpha, slope = beta), color = "blue") +
  geom_abline(data = stan.partialpool.02.values,
            aes(intercept = a, slope = b_floor), color = "purple", lty = 2) +
  geom_abline(data = stan.partialpool.03.values,
            aes(intercept = a_county, slope = b_floor), color = "green") +
  geom_point(alpha = 0.3,
             size = 3,
             position = position_jitter(width = 0.1, height = 0.2)) +
  facet_wrap(~ county) +
  scale_color_manual(values = c("No Pooling", "Pooling")) +
  ggpubr::theme_pubr()

# plot the model results with posterior samples
stan.partialpool.03.samples <-
  stan.partial.pooling.model.03 %>% # use this model fit
  recover_types(radon) %>%
  spread_draws(a_county[county], b_floor[county], b_uranium, sigma_county[], sigma, n = 20) # extract 20 samples in tidy format

ggplot() +
  geom_abline(data = stan.pooling.samples,
            aes(intercept = alpha, slope = beta),
            color = "black",
            alpha = 0.3) +
  geom_abline(data = stan.nopooling.samples,
            aes(intercept = alpha, slope = beta),
            color = "red",
            alpha = 0.3) +
  geom_abline(data = stan.partialpool.samples,
            aes(intercept = alpha, slope = beta),
            color = "blue",
            alpha = 0.3) +
  geom_abline(data = stan.partialpool.02.samples,
            aes(intercept = a, slope = b_floor),
            color = "purple",
            lty = 2,
            alpha = 0.3) +
  geom_abline(data = stan.partialpool.03.samples,
            aes(intercept = a_county, slope = b_floor),
            color = "green",
            alpha = 0.3) +
  geom_point(data = radon,
             aes(x = floor, y = log_radon, group = county),
             alpha = 0.3,
             size = 3,
             position = position_jitter(width = 0.1, height = 0.2)) +
  facet_wrap(~ county) +
  ggpubr::theme_pubr()
```

# Model Comparison

Now we can compute the widely applicable information criterion (WAIC) to determine which has the best fit to the data:

```{r}
library(rethinking)

compare(stan.pooling.fit, stan.no.pooling.fit, stan.partial.pooling.fit,
        stan.partial.pooling.model.02, stan.partial.pooling.model.03)
plot(compare(stan.pooling.fit, stan.no.pooling.fit, stan.partial.pooling.fit,
             stan.partial.pooling.model.02, stan.partial.pooling.model.03))
```

These results show that the `stan.partial.pooling.model.02`, which is the varying intercept with a group-level predictor, has the lowest WAIC. In other words, this model provides the best out-of-sample predictions. The varying intercept, varying slope model is very closely behind with and increase in WAIC of only 3.2 points. The plot shows that although the varying intercept model with a group-level predictor has the best out-of-sample performance (open dots), it does not have the best in-sample performance (solid dots). The no-pooling model has the best in-sample performance, but this model also has the largest degree of over fitting.
