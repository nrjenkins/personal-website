---
title: "A guide to generalize linear models"
linktitle: An Introduction to Generalized Linear Models
toc: true
type: docs
date: "2019-05-05T00:00:00+01:00"
draft: false
menu:
  glms:
    parent: Workshop Overview
    weight: 20

markup: mmark

# Prev/next pager order (if `docs_section_pager` enabled in `params.toml`)
weight: 20
---

This tutorial will walk you through how to use some of the most common generalized linear model and explain what problems they help solve and why. Before going through this code, I suggest that you take some time to review the presentation slides that I put together [here]().

# Environment Prep

Before we get started, we need to load the `tidyverse` package. 

```{r}
#install.packages("tidyverse")
library(tidyverse)
```


# Modeling Titanic Survival Data

Let's start learning how to use GLMs with data on Titanic survival rates. This dataset is available in R and is called `Titanic`. Let's get it loaded:

```{r}
data("Titanic")
```

This code loads the data as an array, but we can convert it to a data frame like this:

```{r}
titanic.data <- as.data.frame(Titanic)
```

We want to know if the passenger class predicts an individual's survival rate. So, our predictor of interest is `Class` and the outcome is an indicator variable (0-1) for whether or not an individual survived. What kind of model should we use? We have a data generation process that produces discrete positive values that are either 0 or 1.

1. What likelihood should we use?
2. What link function should we use?

## Binomial Regression

### Logit Link Function

```{r One-Event Binomial}
logit.fit1 <- glm(Survived ~ Class,
                  family = binomial(link = "logit"),
                  data = titanic.data)
summary(logit.fit1)
```

The model ran, but the results look suspicious. Z-scores of 0? P-values of 1? Let's inspect the data to see if we can figure out the problem.

```{r}
View(titanic.data)
```

This data is aggregated! Remember how we wrote of the equation for the binomial regression?

$$
\begin{aligned}
  y_i &\sim \text{Binomial}(1, p_i) \\
  \text{logit}(p_i) &= \alpha + \beta \times x
\end{aligned}
$$

The $1$ governs the number of trials for each event. Usually, we just set this value equal to $1$ because each row of our data is one event (e.g. the person voted or they didn't). For the aggregated data, we need to set the number of trials for each event. We do this with the `Freq` variable. The easiest way to do this with our code is to set the `weight =` argument equal to `Freq`:

```{r Aggregated Binomial}
logit.fit2 <- glm(Survived ~ Class,
                  family = binomial(link = "logit"),
                  data = titanic.data,
                  weights = Freq)
summary(logit.fit2)
```

Now that looks a lot better. 

### Binomial Practice

Now you practice. Run the code block below to disaggregate the `Titanic` data: 

```{r Disaggregate Titanic Data}
titanic.data.2 <- 
  titanic.data %>% 
  mutate(New_Response = map(Freq, ~ rep_len(1, .x))) %>% 
  unnest(cols = c(New_Response)) %>% 
  select(-Freq, -New_Response)
```

With the data disaggregated, try answering the following questions:

1. Run a standard logistic regression model with the disaggregated data (binomial likelihood function, logit link function).

```{r}

```

2. Run a probit regression with the disaggregated data (binomial likelihood function, probit link function).

```{r}

```

# Modeling Airport Passenger Traffic

In this example, we are going to build a model of airport passengers to see if the COVID lock downs imposed in March of 2020 affected the number of travelers. Let's load in the data and do some prep. 

```{r}
# load the data
tsa.data <- read_csv("https://raw.githubusercontent.com/mikelor/TsaThroughput/main/data/processed/tsa/throughput/TsaThroughput.LAX.csv")

#
#install.packages("janitor")
#install.packages("lubridate")
tsa.data <- 
  tsa.data %>% 
  # fix the variable names
  janitor::clean_names() %>% 
  # create an indicator for March 2020
  mutate(month = lubridate::month(date),
         year = lubridate::year(date),
         month_year = str_c(month, year, sep = "-"),
         month_year = lubridate::my(month_year),
         lockdown = ifelse(month_year == "2020-03-01", 1, 0))
```

How should we model this data? We want to know if the COVID lock down in March of 2020 had an effect on the number of air travelers. So, our data generating process will be positive between 0 and $-\infty$ (theoretically) and discrete. 

1. What distribution describes a process like this?
2. What link function should we use?

## Poisson Regression

Now we're ready to model passenger traffic. The outcome will be `lax_tbit_main_checkpoint` and the predictor will be `lockdown`. We'll use a Poisson likelihood function and a log link function. 

```{r}
poisson.fit1 <- glm(lax_tbit_main_checkpoint ~ lockdown,
                    family = poisson(link = "log"),
                    data = tsa.data)
summary(poisson.fit1)
```

### Doesn't everyone use Negative-Binomial instead of Poisson?

Usually, where we see someone using a count model, they use a negative binomial regression instead of a Poisson regression. Well, it turns out that the negative Binomial model doesn't involve a Binomial distribution. It's much more accurate to call it a Gamma-Poisson model. Why Gamma-Poisson and why do we use it? One limitation of the Poisson distribution is that it assumes that the mean is equal to the variance. When this isn't the case, we have either over, or under, dispersion. This is where the Gamma-Poisson model helps. 

Instead of assuming the mean and variance are equal, the Gamma-Poisson model has an additional parameter that allows each observation to have its own rate (it lets the mean differ from the variance). And, the rate parameter follows a gamma distribution because the gamma distribution is a positive continuous distribution defined between (0 and $\infty$). Let's run it.

```{r}
#install.packages("MASS")
library(MASS)

gp.fit1 <- glm.nb(lax_tbit_main_checkpoint ~ lockdown,
                  data = tsa.data)

summary(gp.fit1)
```

Because the Gamma-Poisson model involves two likelihood functions, it is considered a mixture model. Mixture models are models that combine two likelihood functions in order to describe a data generating process. 

So, how do we interpret this model?

```{r}
1 - (exp(-0.23122)) * 100
```

Air travel decreased by 78% in March of 2020.  

# Modeling Penguin Species

For the next example, we will build a multinomial logistic regression to classify penguin species. This data comes from the `palmerpenguins` R package. Let's load it in.

```{r}
#install.packages("palmerpenguins")
library(palmerpenguins)

data(penguins)
```

Since we want to model penguin species, let's figure out how many types of species we have in the data: 

```{r}
summary(penguins$species)
```

Ok, we have three categories. Now our two standard questions: 

1. What distribution describes a process like this?
2. What link function should we use?

We need a probability distribution that describes a data generating process that produces discrete categorical data. The multinomial distribution is a good choice for this job. But what link function? We need a link function that can classify multiple categories as either 1 or 0. For this, we need the multinomial logit, also known as the softmax, link function. Let's get to work.  

## Categorical Regression

To build a multinomial logistic regression model, we need the `nnet` R package. 

```{r}
#install.packages("nnet")
library(nnet)
```

Now we want to classify penguin species as a function of their bill length (`bill_length_mm`) and flipper length (`flipper_length_mm`). 

```{r}
multinom.fit <- 
  multinom(species ~ bill_length_mm + flipper_length_mm,
           data = penguins)
```

Notice that we don't need to specify a family (a.k.a. a likelihood function) here. That's because it's assumed by the `multinom` function. It's also important to know that the `multinom` function expects the outcome variable to be a factor. Since our `species` variable is a factor, we're good. Ok, let's look at the results.

```{r}
summary(multinom.fit)
```

Hmm. What's going on here? Multinomial regressions are complicated models, so they can be hard to interpret. Notice that we see `Chinstrap` and `Gentoo` as the row names for the Coefficients section. These rows show us the estimated coefficients for each of these categories with the `Adelie` species being the references group. With that said, here's a guide to understanding the coefficients:

*Chinstrap category:*

* A one millimeter increase in the length of a bill is associated with an increase in the log odds of being in the `Chinstrap` species vs the `Adelie` species of `r coef(multinom.fit)[1, 2]`. 

*Gentoo category:*

* A one millimeter increase in the length of a bill is associated with an increase in the log odds of being in the `Gentoo` species vs the `Adelie` species of `r coef(multinom.fit)[2, 2]`. 

We can also exponentiate the the coefficients to get the relative risk ratios:

```{r}
exp(coef(multinom.fit))
```

* The relative risk ratio for a 1 millimeter increase in bill length is 3.84 times more likely to belong in to the Chinstrap species than the Adelie species. In other words, given a 1 millimeter increase in bill length, the relative risk of being in the Chinstrap species would be 3.84 times more likely than being in the Adelie species, holding all other variables constant.

The easiest way to interpret these models is probably to plot them. It takes a bit of wrangling, but here it goes. For the plot, we'll look at how the probabilities of being in each category change across the range of bill length values, holding flipper length at the mean. 

```{r}
pred.data <- 
  expand_grid(bill_length_mm = penguins$bill_length_mm,
              flipper_length_mm = mean(penguins$flipper_length_mm, na.rm = T)) %>% 
  drop_na()


plot.data <- 
  cbind(pred.data, predict(multinom.fit, newdata = pred.data, type = "probs"))

plot.data <- 
  plot.data %>% 
  pivot_longer(cols = c(Adelie, Chinstrap, Gentoo), names_to = "species",
               values_to = "probs")

ggplot(data = plot.data, 
       aes(x = bill_length_mm, y = probs, color = species)) +
  geom_line() +
  labs(x = "Bill Length (mm)",
       y = "Predicted Probability",
       color = "Species",
       title = "Predicted Probability of Species by Bill Length") +
  theme_classic()
```

# Bonus: Modeling Proportions

Sometimes we want to build a model that can make predictions about proportions. Proportions are a new type of data because they are continuous *and* limited between 0 and 1. As an example of this, we'll use some data on gasoline yields from crude oil as a function of covariates. 

```{r}
#install.packages("betareg")
library(betareg)

data("GasolineYield")

glimpse(GasolineYield)
```

Here the `yield` column shows the proportion of crude oil converted to gasoline after distillation and fractionation. This will be our outcome variable. But how should we model it? We need a probability distribution that describes a data generating process that produces continuous values bounded between 0 and 1. Introducing the beta distribution!

## Beta Regression

The beta distribution fits the bill exactly. It's continuous and limited between 0 and 1. But what link function? Well, we already know of a link function that restricts a linear model to be between 0 and 1 - the logit link function. Let get to it:

```{r}
beta.fit <- betareg(yield ~ gravity + pressure + temp10,
                    data = GasolineYield)

summary(beta.fit)
```

Just like with logistic regression, we can interpret these coefficients on the probability scale by using the inverse link function `plogis()` in the case. So, the proportion of gasoline yielded from crude oil increases by `plogis(0.15)` about 53% for a one unit increase in `pressure`. Accounting for the intercept, it's an absolute increase of only `plogis(-2.98 + 0.15) - plogis(-2.98)` 0.7%. 
