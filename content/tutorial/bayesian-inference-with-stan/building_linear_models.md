---
title: Building Linear Models
linktitle: Building Linear Models
toc: true
type: docs
date: "2019-05-05T00:00:00+01:00"
draft: false
menu:
  stan:
    parent: Part B Linear Models
    weight: 30

markup: mmark

# Prev/next pager order (if `docs_section_pager` enabled in `params.toml`)
weight: 30
---

In this tutorial, we will learn how to estimate linear models using Stan and R. Along the way, we will review the steps in a sound Bayesian workflow. This workflow consists of: 

1. Considering the social process that generates your data. The goal of your statistical model should be to model the data generating process, so think hard about this. Exploratory analysis goes a long way towards helping you to understand this process.

2. Program your statistical model and sample from it.

3. Evaluate your model's reliability. Check for Markov chain convergence to make sure that your model has produced reliable estimates.

4. Evaluate your model's performance. How well does your model approximate the data generating process? This involves using posterior predictive checks.

5. Summarize your model's results in tabular and graphical form.

My goal is to explain the fundamentals of linear models in Stan with examples so that we aren't learning Stan programming in such an abstract environment. Let's get started!

# Import Data

We'll use the Motor Trend Car Road Tests `mtcars` data that is provided in R as our practice data set. 

```{r}
cars.data <- mtcars

library(tidyverse)
glimpse(cars.data)
```

Let's walk though what our variables are:

* `mpg`: Miles pre gallon
* `cyl`: Number of cylinders
* `disp` Displacement (cu. in.)
* `hp`: Gross horsepower
* `drat`: Rear axle ratio
* `wt`: Weight (1000 lbs)
* `qsec`: 1/4 mile time
* `vs`: Engine (0 = V-shaped, 1 = straight)
* `am`: Transmission (0 = automatic, 1 = manual)
* `gear`: Number of forward gears
* `carb`: Number of carburetors

With this informaion, let's do some quick data cleaning.

```{r}
cars.data <- 
  cars.data %>%
  rename(cylinders = cyl,
         displacement = disp,
         rear_axle_ratio = drat,
         weight = wt,
         engine_type = vs,
         trans_type = am,
         gears = gear) %>%
  mutate(engine_type = factor(engine_type, levels = c(0, 1), 
                              labels = c("V-shaped", "Straight")),
         trans_type = factor(trans_type, levels = c(0, 1),
                             labels = c("Automatic", "Manual")))

glimpse(cars.data)
```

For our research question, we will be investigating how different characteristics of a car affect it's MPG. To start with, we will test how vehicle weight affects MPG. Let's do some preliminary analysis of this question with visualizations. 

```{r}
ggplot(data = cars.data, aes(x = weight, y = mpg)) +
  geom_point()
```

As expected, there seems to be a negative relationship between these variables. Let's add in a fitted line:

```{r}
ggplot(data = cars.data, aes(x = weight, y = mpg)) +
  geom_point() +
  geom_smooth(method = "lm")
```


# Build a Model

## Models with a Single Predictor

Now we will build a model in Stan to formally estimate this relationship. Rather than creating an `r` code block, we want to create a `stan` code block. The only caviat is that we also need to add a name for our Stan model provided in the `output.var` argument. 

Here is the model that we want to estimate in Stan:

$$
\begin{aligned}
\text{mpg} &\sim \text{Normal}(\mu, \sigma) \\
\mu &= \alpha + \beta \text{weight}
\end{aligned}
$$

To start, we need to load `cmdstanr` which will allow us to interface with Stan through R.

```{r}
library(cmdstanr)
register_knitr_engine(override = FALSE) # This registers cmdstanr with knitr so that we can use
# it with R Markdown.
```

Now, program the model:

```{cmdstan output.var = "linear.model"}
data {
  int n; //number of observations in the data
  vector[n] mpg; //vector of length n for the car's MPG
  vector[n] weight; //vector of length n for the car's weight
}

parameters {
  real alpha; //the intercept parameter
  real beta_w; //slope parameter for weight
  real sigma; //model variance parameter
}

model {
  //linear predictor mu
  vector[n] mu;
  
  //write the linear equation
  mu = alpha + beta_w * weight;
  
  //likelihood function
  mpg ~ normal(mu, sigma);
}
```

Once we finish writing the model, we need to run the code block to compile it into C++ code. This will also us to sample from the model and obtain the parameter estimates. Let's do that now. 

The next step is to prepare the data for Stan. Stan can't use the same types of data that R can. For example, Stan requires lists, not data frames, and it cannot accept factors. We'll use the `tidybayes` package to make it eaiser to prepare the data. 

```{r}
library(tidybayes)

model.data <- 
  cars.data %>%
  select(mpg, weight) %>%
  compose_data(.)

# sample from our model
linear.fit.1 <- linear.model$sample(data = model.data)

# summarize our model
print(linear.fit.1)
```

Let's run through the interpretation of this model:

* `alpha` For a car with a weight of zero, the expected MPG is 37.21. Obviously, a weight of zero is impossible, so we'll want to address this in our next model. 

* `beta_w` Comparing two cars who differ by 1000 pounds, the model predicts a difference of 5.33 miles per gallon. 

* `sigma` The model predicts MPG within 3.18 points. 

* `lp__` Logarithm of the (unnormalized) posterior density. This log density can be used in various ways for model evaluation and comparison.

Ok, now that we've written our model, let's make a few imporvements. First, let's center our weight variable so that we can get a more meaningful interpretation of the intercept parameter `alpha`. We can accomplish this by subtracting the mean from each observation. This will change the interpretation of the intercept to be the average MPG when weight is held constant at it's average value. 

```{r}
cars.data <- 
  cars.data %>%
  mutate(weight_c = weight - mean(weight))
```

Now that we changed the name of the variable name, we also need to change our model code to incorporate this change. While we are adjusting the code, we'll also restrict the scale parameter to be positive. This will help our model be a bit more efficient. 

```{cmdstan output.var = "linear.model"}
data {
  int n; //number of observations in the data
  vector[n] mpg; //vector of length n for the car's MPG
  vector[n] weight_c; //vector of length n for the car's weight
}

parameters {
  real alpha; //the intercept parameter
  real beta_w; //slope parameter for weight
  real<lower = 0> sigma; //variance parameter and restrict it to positive values
}

model {
  //linear predictor mu
  vector[n] mu;
  
  //write the linear equation
  mu = alpha + beta_w * weight_c;
  
  //likelihood function
  mpg ~ normal(mu, sigma);
}
```

Now prepare the data and re-estimate the model. 

```{r}
model.data <- 
  cars.data %>%
  select(mpg, weight_c) %>%
  compose_data(cars.data)

linear.fit.2 <- linear.model$sample(data = model.data)

print(linear.fit.2)
```

Let's interpret this model:

* `alpha` When a vehicle's weight is held at its average value, the expected MPG is 20.09.

* `beta_w` This estimate has the same interpretation as before. 

* `sigma` This estimate has the same interpretation as before. 

* `lp__` This estimate has a slightly lower value (in absolute value) than it did in the previous model indicating that this model performs slightly better. 

## Models with Multiple Predictors

To add more predictors, we just need to adjust out model code. Let's add in the vehicle's cylinders and horsepower. We'll also center these variables. 

```{cmdstan output.var = "linear.model"}
data {
  int n; //number of observations in the data
  vector[n] mpg; //vector of length n for the car's MPG
  vector[n] weight_c; //vector of length n for the car's weight
  vector[n] cylinders_c; ////vector of length n for the car's cylinders
  vector[n] hp_c; //vector of length n for the car's horsepower
}

parameters {
  real alpha; //the intercept parameter
  real beta_w; //slope parameter for weight
  real beta_cyl; //slope parameter for cylinder
  real beta_hp; //slope parameter for horsepower
  real<lower = 0> sigma; //variance parameter and restrict it to positive values
}

model {
  //linear predictor mu
  vector[n] mu;
  
  //write the linear equation
  mu = alpha + beta_w * weight_c + beta_cyl * cylinders_c + beta_hp * hp_c;
  
  //likelihood function
  mpg ~ normal(mu, sigma);
}
```

Prepare the data and sample from the model.

```{r}
model.data <- 
  cars.data %>%
  mutate(cylinders_c = cylinders - mean(cylinders),
         hp_c = hp - mean(hp)) %>%
  select(mpg, weight_c, cylinders_c, hp_c) %>%
  compose_data(.)

linear.fit.3 <- linear.model$sample(data = model.data)

print(linear.fit.3)
```

After adjusting for a car's cylinders and horsepower two cars that differ by 1000 pounds, the model predicts a difference of 3.18 miles per gallon. Notice that `lp__` is now even lower, suggesting that this latest model is a better fit. 


# Assesing Our Model

## Model Convergence

Now that we've built a decent model, we need to see how well it actuall preforms. First, we'll want to check that our chains have converged and are producing reliable point estimates. We can do this with a traceplot. 

```{r}
library(bayesplot)
fit.draws <- linear.fit.3$draws() # extract the posterior draws
mcmc_trace(fit.draws)
```

The fuzy caterpiller appearance indicates that the chains are mixing well and have converged to a common distribution. We can also assess the Rhat values for each parameter. As a rule of thumb, Rhat values less than 1.05 indicate good convergence. The `bayesplot` package makes these calculations easy.

```{r}
rhats <- rhat(linear.fit.3)
mcmc_rhat(rhats)
```

## Effective Sample Size

The effective sample size estimates the number of independent draws from the posterior distribution of a given estimate. This metric is important because Markov chains can have autocorrelation wich will lead to biased parameter estimates. With the `bayesplot` package we can visualize the ratio of the effective sample size to the total number of samples - the larger the ratio the better. The rule of thumb here is to worry about ratios less than 0.1. 

```{r}
eff.ratio <- neff_ratio(linear.fit.3)
eff.ratio

mcmc_neff(eff.ratio)
```

We can also check the autocorrelation in the chains with `bayesplot`. To use the `mcmc_acf` function, we'll need to extract the posterior draws from the model.

```{r}
mcmc_acf(fit.draws)
```

Here, we are looking to see how quickly the autocorrelation drops to zero. 

## Posterior Predictive Checks

One of the most powerful tools of Bayesian inference is to conduct posterior predictive checks. This check is designed to see how well our model can generate data that matches observed data. If we built a good model, it should be able to generate new observations that very closely resemble the observed data. 

In order to perform posterior predictive checks, we will need to add in some code to our model. Specifically we need to calculate replications of our outcome variable. We can do this using the `generated quantities` section.

```{cmdstan output.var = "linear.model"}
data {
  int n; //number of observations in the data
  vector[n] mpg; //vector of length n for the car's MPG
  vector[n] weight_c; //vector of length n for the car's weight
  vector[n] cylinders_c; ////vector of length n for the car's cylinders
  vector[n] hp_c; //vector of length n for the car's horsepower
}

parameters {
  real alpha; //the intercept parameter
  real beta_w; //slope parameter for weight
  real beta_cyl; //slope parameter for cylinder
  real beta_hp; //slope parameter for horsepower
  real<lower = 0> sigma; //variance parameter and restrict it to positive values
}

model {
  //linear predictor mu
  vector[n] mu;
  
  //write the linear equation
  mu = alpha + beta_w * weight_c + beta_cyl * cylinders_c + beta_hp * hp_c;
  
  //likelihood function
  mpg ~ normal(mu, sigma);
}

generated quantities {
  //replications for the posterior predictive distribution
  real y_rep[n] = normal_rng(alpha + beta_w * weight_c + beta_cyl * 
    cylinders_c + beta_hp * hp_c, sigma);
}
```

In the code block above, `normal_rng` is the Stan function to generate observations from a normal distribution. So, `y_rep` generates new data points from a normal distribution using the linear model we built `mu` and a variance `sigma`. Now let's re-estimate the model:

```{r}
linear.fit.3 <- linear.model$sample(data = model.data)

print(linear.fit.3)
```

In our model output, we now have a replicated y value for every row of data. We can use these values to plot the replicated data against the observed data. 

```{r}
y <- cars.data$mpg

# convert the cmdstanr fit to an rstan object
library(rstan)
stanfit <- read_stan_csv(linear.fit.3$output_files())

# extract the fitted values
y.rep <- extract(stanfit)[["y_rep"]]

ppc_dens_overlay(y = cars.data$mpg, yrep = y.rep[1:100, ])
```

The closer the replicated values (`yrep`) get to the observed values (y) the more accurate the model. Here it looks like we could probably do a bit better, though the lose fit is likely due to the small sample size (which adds more uncertainty). 


# Improving the Model with Better Priors

To improve this model, let's use more informative priors. Priors allow us to incorporate our background knowledge on the question into the model to produce more realistic estimates. For our question here, we probably don't expect the weight of a vehicle to change its MPG more that a dozen or so miles per gallon. Unfortunately, becuase we didn't specify priors in the previous models, it defaulted to using flat priors which essentially place an equal probably on all possible coefficient values - not very realistic. Let's fix that. 

To get a better sense of what priors to use, it's a good idea to use prior predictive checks, which are a lot like posterior predictive checks only they don't include any data. The goal is to select priors that put some probably over all plausable vales. 

```{r}
# expectations for the effect of weight on MPG
sample.weight <- rnorm(1000, mean = 0, sd = 100)
plot(density(sample.weight))

# expectations for the average mpg
sample.intercept <- rnorm(1000, mean = 0, sd = 100)
plot(density(sample.intercept))

# expectations for model variance
sample.sigma <- runif(1000, min = 0, max = 100)
plot(density(sample.weight))

# prior predictive simulation for mpg given the priors
prior_mpg <- rnorm(1000, sample.weight + sample.intercept, sample.sigma)
plot(density(prior_mpg))
```

These priors suggest that the effect of weight on MPG coulb be anywhere from -400 to 400 points. Definitely not realistic - and these are already more informative priors than any frequentist analysis! Similarly, the expected MPG of a vehicle given these priors is anywhere from -400 to 400. 

Let's bring these in a bit. 

```{r}
# expectations for the effect of weight on MPG
sample.weight <- rnorm(1000, mean = -10, sd = 5)
plot(density(sample.weight))

# expectations for the average mpg
sample.intercept <- rnorm(1000, mean = 20, sd = 5)
plot(density(sample.intercept))

# expectations for model variance
sample.sigma <- runif(1000, min = 0, max = 10)
plot(density(sample.sigma))

# prior predictive simulation for mpg given the priors
prior_mpg <- rnorm(1000, sample.weight + sample.intercept, sample.sigma)
plot(density(prior_mpg))
```

We could probably do better, but these look a lot better. Now the expected effect of weight on MPG is negative and and majority of the mass is concentrated between -15 and -5. Similarly, the expected MPG given these priors is between -10 and 20. 

Now let's build a new model with these priors and sample from it. 

```{cmdstan output.var = "linear.model"}
data {
  int n; //number of observations in the data
  vector[n] mpg; //vector of length n for the car's MPG
  vector[n] weight_c; //vector of length n for the car's weight
  vector[n] cylinders_c; ////vector of length n for the car's cylinders
  vector[n] hp_c; //vector of length n for the car's horsepower
}

parameters {
  real alpha; //the intercept parameter
  real beta_w; //slope parameter for weight
  real beta_cyl; //slope parameter for cylinder
  real beta_hp; //slope parameter for horsepower
  real<lower = 0> sigma; //variance parameter and restrict it to positive values
}

model {
  //linear predictor mu
  vector[n] mu;
  
  //write the linear equation
  mu = alpha + beta_w * weight_c + beta_cyl * cylinders_c + beta_hp * hp_c;
  
  //prior expectations
  alpha ~ normal(20, 5);
  beta_w ~ normal(-10, 5);
  beta_cyl ~ normal(0, 5); //we'll include my uncertain priors here
  beta_hp ~ normal(0, 5); //we'll include my uncertain priors here
  sigma ~ uniform(0, 10);
  
  //likelihood function
  mpg ~ normal(mu, sigma);
}

generated quantities {
  //replications for the posterior predictive distribution
  real y_rep[n] = normal_rng(alpha + beta_w * weight_c + beta_cyl * 
  cylinders_c + beta_hp * hp_c, sigma);
}
```

Now sample:

```{r}
linear.fit.4 <- linear.model$sample(data = model.data)
print(linear.fit.4)
```

After estimating the model with more informative priors, the `lp__` is now a little bit lower. We can compare the prior distribution to the posterior distribution to see how "powerful" our priors are.

```{r}
linear.fit.4 <- read_stan_csv(linear.fit.4$output_files())
posterior <- as.data.frame(linear.fit.4)

library(tidyverse)
ggplot() +
  geom_density(aes(x = sample.weight)) +
  geom_density(aes(x = posterior$beta_w), color = "blue")
```

Here we can see that even with more "informative priors" they are still very weak compared to the data. 

# Summarize the Model

With our final model in hand, we can visualizations of our model's results.

## Coeficient Plot

```{r}
stan_plot(linear.fit.4, 
          pars = c("alpha", "beta_w", "beta_cyl", "beta_hp", "sigma"))
```

## Fitted Regression Line

Here we can plot the fitted regression line 

```{r}
# Fitted Line
ggplot(data = cars.data, aes(x = weight_c, y = mpg)) +
  geom_point() +
  stat_function(fun = function(x) mean(posterior$alpha) + mean(posterior$beta_w) * x)

# Fitted Line with Uncertainty ------------------------------------------------
fit.plot <- 
  ggplot(data = cars.data, aes(x = weight_c, y = mpg)) +
  geom_point()

# select a random sample of 100 draws from the posterior distribution
sims <-
  posterior %>%
  mutate(n = row_number()) %>%
  sample_n(size = 100)

# add these draws to the plot
lines <- 
  purrr::map(1:100, function(i) stat_function(fun = function(x) sims[i, 1] + sims[i, 2] * x, 
             size = 0.08, color = "gray"))
fit.plot <- fit.plot + lines

# add the mean line to the plot
fit.plot <- 
  fit.plot +
  stat_function(fun = function(x) mean(posterior$alpha) + mean(posterior$beta_w) * x)

fit.plot
```

