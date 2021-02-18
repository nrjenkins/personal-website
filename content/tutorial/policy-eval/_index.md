---
# Course title, summary, and position.
linktitle: Intro to Policy Evaluation using R
summary: Learn how to conduct a policy evaluation project using R.
weight: 2

# Page metadata.
title: Overview
date: "2018-09-09T00:00:00Z"
lastmod: "2018-09-09T00:00:00Z"
draft: false  # Is this a draft? true/false
toc: true  # Show table of contents? true/false
type: docs  # Do not modify.

# Add menu entry to sidebar.
# - name: Declare this menu item as a parent with ID `name`.
# - weight: Position of link in menu.
menu:
  policy-eval:
    name: Policy Evaluation
    weight: 1

markup: mmark
---

## Overview

This document provides a guide for the policy evaluation project. This project asks you to us the [Correlates of State Policy](http://ippsr.msu.edu/public-policy/correlates-state-policy) data available from the Institute for Public Policy and Social Research College of Social Science.  

You will develop a project using this data set and write a 10 page (double-spaced, 12 point font, printed and stapled) memo that shows the knowledge you gained from this class. To do this project, you will need to first download the codebook describing the data, and then develop a research question that you will be able to answer using the data. You will do the analysis using both regression and difference-in-differences and compare the results. The memo will have four sections: 1) the problem and the policy intervention that the study substantively focuses on; 2) the methods you use to evaluate the impact of the intervention; 3) the findings of your analysis; and 4) a discussion of the importance of the evaluation. The memo must include a minimum of five cites to academic research to justify your hypothesis (you can cite blogs, websites and newspapers but these will not count toward the academic cites).

This document will walk you though the steps required to conduct a policy evaluation project. In general, every project involves the following steps:

1. Obtain policy data and familiarize yourself with the variables, how they are measured, and their availability
2. Read the data into your statistical software and prepare it for analysis
3. Explore the data but plotting variables of interest and calculate summary statistics
4. Develop your statistical model and analyse your data
5. Explain your findings


# Workflow

As a data analyst, it is absolutely essential that you keep detailed documentation of your analysis process. This means saving all of the code that you use for a project somewhere convenient so that you or anyone else can quickly and easily exactly reproduce your original results. In addition to saving your code, you should also provide explanations for your procedures and code so that you will always remember your data sources, what each line of code is doing, and why you analysed the data the way that you did. Not only will this help you remember the details about your project, but it will also make it easy for others to read through your code and validate your methodology. Practically, your code should be saved in a script file, though I strongly recommend using Rmarkdown since it allows you to create complete documents and execute code at the same time, exactly like this guide!

To create an Rmarkdown document go to file -> New File -> R notebook:

![](create_markdown.png)

For a good overview of Rmarkdown check out chapter 27 of [R for Data Science](https://r4ds.had.co.nz/r-markdown.html). For more details, check out [R Markdown: The Definitive Guide](https://bookdown.org/yihui/rmarkdown/).


## Step 1: Obtain the Policy Data

### About the dataset

The Correlates of State Policy Project includes more than 900 variables, with observations across the 50 U.S. states and across time (1900–2016, approximately). These variables represent policy outputs or political, social, or economic factors that may influence policy differences. The codebook includes the variable name, a short description of the variable, the variable time frame, a longer description of the variable, and the variable source(s) and notes.

Begin by downloading the Correlates of State Policy Project [codebook](https://ippsr.msu.edu/sites/default/files/CorrelatesCodebook.pdf). After the file is downloaded, open it and review the table of contents. The table of contents simply lists the categories of variables available in the data. Scrolling down to page 3, we see examples of types of data (or variables) that are available under each category:

![](variables.png)

#### Unit of Analysis and Data Type

Before you begin thinking about your research question, you first need to identify what type of data the Correlates of State Policy Project are what the unit of analysis is. Does the data span multiple years or is it just a single year? Do the variables contain data on individuals, ZIP codes, counties, Congressional districts, states, countries, ...? This is an essential first step because the answers to these questions will narrow the range of research questions that you can answer.

For example, suppose we were interested to know if going to college leads to increases in pay rates. In addition to a research design that would allow us to identify this causal effect, we would need data on individual people; whether or not they have a college degree and what their pay rates are. With this data, the unit of analysis would be the individual-level.

Let's suppose we have this data. Now we need to decide if we need cross-sectional data, or panel data. Cross-sectional data are data that only have data for a single point in time. An example of this would be a survey of a randomly sampled respondents in year, say, 2020. Panel data (also known as longitudinal data) contains data on the **same** variables **and** **units** across multiple years. An example of this would be if we surveyed the same individuals every year for 5 years. Thus, we would have multiple measurements of a variable for the same individual over multiple time points. Note that we don't need data on individuals to construct a panel dataset. We could also have a panel of, say, the GDP of all 50 states over a 10 year period.

What if we have data for multiple years, but the variables aren't measuring the **same** individuals? In this case, we would have a pooled-cross-section. For example, the [General Social Survey](http://www.gss.norc.org) (GSS) conducts surveys of a random sample of individuals every year, but they don't survey the **same** individuals. This means that we cannot compare the values of a variable in one year to the values of the same variable in another year, since each year is measuring a different person.

Getting back to the Correlates of State Policy Project data, we can see in the "About the Correlates of State Policy Project" section that the data measures all 50 states from 1900 to 2018. Thus, the unit of analysis is at the state-level and because it measures states (the same states) over time, it is a panel dataset. This should orient our research question to one about state-level outcomes and programs.

#### Research Question and Theory

In this guide, I will consider the following research question:

*Do policies that ban financial incentives for doctors to preform less costly procedures and prescribe less costly drugs affect per capita state spending on health care expenditures?*

In addition to a precise research question, you also need to develop an explanation for why you think these two variables are related. For my research question, my theory might be that incentivising doctors to preform less costly procedures and prescribe less costly drugs will make them more likely to do these things which will ultimately lead to a reduction in, both private and public, health care expenditures.

#### Selecting Variables

In deciding which variables we need to answer our research question, we need to consider three different categories of variables: the outcome variable, the predictor of interest (usually the policy intervention or treatment), and control predictors.

For my question, policies banning financial incentives for doctors will be my predictor of interest (or treatment) and state health care expenditures will be my outcome. Here are the descriptions given to each of these variables in the codebook:

| Variable Name | Variable Description | Variable Coding | Dates Available |
|---------------|----------------------|-----------------|-----------------|
| `banfaninc`   | Did state adopt a ban on financial incentives for doctors to perform less costly procedures/prescribe less costly drugs? | 0 = no, 1 = yes | 1996 - 2001 |
| `healthspendpc` | Health care expenditures per capita (in dollars), measuring spending for all privately and publicly funded personal health care services and products (hospital care, physician services, nursing home care, prescription drugs, etc.) by state of residence. | in dollars | 1991 - 2009 |

There are a few things to note about this information. First, data are available for both of these variables from 1996 to 2001. If the years of collection for these variables didn't overlap, then we wouldn't be able to use them to answer our question. Second, `banfaninc` is an indicator variable (also known as a dummy variable) that simply indicates a binary, "yes" "no" status. Conversely, `healthspendpc` is continuous meaning that it could be any positive number (since it is measured in dollars). Note that when working with money as a variable, it is important to control for inflation!

Now that we have the outcome and treatment, we need to think about what controls we need. The important criterion for identifying control variables is to pick variables that are correlated with *both* the treatment and outcome.

For my question I will need to identify variables that affect both policies that prohibit financial incentives *and* affect a state's health care spending per capita. Here are some examples:

| Variable Name | Variable Description | Variable Coding | Dates Available |
|---------------|----------------------|-----------------|-----------------|
| `sen_cont_alt` | Party in control of state senate | 1 = Democrats, 0 = Republicans, .5 = split | 1937 – 2011 |
| `hs_cont_alt` | Party in control of state house | 1 = Democrats, 0 = Republicans, .5 = split | 1937 – 2011 |
| `hou_chamber` | State house ideological median | Scale is -1 (liberal) to +1 (conservative) | 1993 - 2016 |
| `sen_chamber` | State house ideological median | Scale is -1 (liberal) to +1 (conservative) | 1993 - 2016 |

Perhaps Democrats are more likely to regulate the health care industry including policies about prescription drugs and they are more likely to allocate public funds for health care.  

Finally, in addition to your outcome, predictor of interest, and control variables, you need to keep variables that uniquely identify each row of data. For this dataset, this will be the state and the year. This means that the level of data we have is "state-year" because each row of data contains measures for a given state and a given year.

Now that we know what variables we need, we can start working with the data. Download the [`.csv`](https://ippsr.msu.edu/sites/default/files/correlatesofstatepolicyprojectv2_2.csv) file containing the data. Next, open your R markdown, or script, file and set the working directory using the command `setwd`. This tells R where your the files for you project are located which makes it easier to import data. The `setwd` command works as follows: `setwd("/YOUR FILE STRUCTURE HERE")`. For me, this looks like this:

```{r echo = TRUE, message = TRUE}
setwd("/Users/nick/Documents/Teaching/TA Classes/UCR - PBPL 220/Policy Evaluation Project")
```

Using an [R project](https://r4ds.had.co.nz/workflow-projects.html#rstudio-projects) is actually a better idea than simply setting the working directory, but I'll leave it to you to learn about R projects.


## Step 2: Prepare the Data for Analysis

### Import Data

**Disclaimer:** Depending on your level of experience with programming languages, R can be difficult to learn. I will do my best to explain my code in this guide, but it will not serve as a tutorial on how to use R. For resources to help you learn R, I recommend reading [R for Data Science](https://r4ds.had.co.nz).

With the working directory set, we are ready to import the data. Because R is an open source language, we need to rely on various packages that R users write to provide us with the functionality we need. To install a package type `install.packages()` with the package name in the function. You only need to install a package once, and after it's installed you tell R to load it using the function `library()` with the package name in the argument. If R ever tells you that it can't find the function you're trying to use, make sure that you have the packaged loaded and installed.

In this guide, I will be using [tidyverse](https://www.tidyverse.org) syntax since it makes coding easier and more flexible. For some excellent beginner tutorials on the tidyverse, check out Sono Shah's [Tidyverse Basics](https://www.sonoshah.com/tutorial/tidyverse-1/) and Sean Kross' [An Irresponsibly Brief Introduction to the Tidyverse](https://seankross.com/2020/01/29/An-Irresponsibly-Brief-Introduction-to-the-Tidyverse.html). Calling the package `tidyverse` actually loads a series of packages, as you can see below:  

```{r}
library(tidyverse)
```

Now let's import the data. Because it's a `.csv` file we use the function `read.csv()`:

```{r}
# this code tells R to read in the csv file called "projectdata.csv" and save
# it in an object that I named data.raw
data.raw <- read.csv("projectdata.csv")
```

I normally save my original data to an object with the extension `.raw` so that I can always get back to the original data without having to import it again.

### Clean Data

Before we can begin analyzing the data, we need to prepare, or clean, it. This could involve restructuring the data into a format that we can analyse, creating indicator variables, dealing with missing data, etc... In order to run a regression, for example, the data needs to be in "long form" where every row contains a unique observation (e.g. California in 2005) and each column contains a unique variable. To start, let's take a look at our data.  

```{r}
# before visualizing your data let's select the varables we will use
data.raw <-
  data.raw %>%
  select(year, state, healthspendpc, banfaninc, sen_cont_alt, hs_cont_alt,
         hou_chamber, sen_chamber)

# this shows the variable names, their types, and previews their values
glimpse(data.raw)

# or we could use head to see the first 10 rows (you can click through the columns too)
head(data.raw)

# this opens the complete dataset
view(data.raw)
```


The data is already in long form but notice all the `NA`s. Any time a variable contains a missing value, R codes it as `NA`. The fact that we see missing values shouldn't be surprising however, because we are looking at measurements for the year 1900 and we already know that our data only spans 1996 - 2001.

This is helpful, but often times datasets will code missing values a -9, or 99, or some other values. This creates problems if you're not careful because R won't know that these values mean that data is missing. To prevent this issue, you will need to look though the codebook to see if they discuss how missing values are coded. As a second precaution you should also tabulate your variables to see if there are any unusual values.

Looking through the codebook, I don't see any mention of a missing value coding scheme but lets examine the data in R.

```{r}
# this calculates summary statistics for all the variables in our dataset
summary(data.raw)
```

The minimum and maximum values all look like they should (no unexpectedly large or small values).

Let's rename our variables to give them more intuitive names. When using indicator variables, you typically want to give the variable the same name as the meaning of a value of 1. For example, if we had an indicator variable for sex where 0 = female and 1 = male, we would name the variable something like, `male_dum`. For my data, the predictor of interest is already a 0 - 1 indicator so I'll just rename it to `treatment`.

```{r}
# the %>% is called the pipe operator. It basically means "and then..."
data <- # create an object called data
  data.raw %>% # use the data.raw object then ...
  rename(treatment = banfaninc, # rename the banfaninc variable to treatment
         senate_control = sen_cont_alt,
         house_control = hs_cont_alt,
         house_ideology = hou_chamber,
         senate_ideology = sen_chamber)
```

Now we have a new object called `data` with the changes that we made. Let's look at it:

```{r}
glimpse(data)

# let's look at the possible values that senate_control can take
# first we tell R to use data then use the $ operator to select the column we want
unique(data$senate_control)
```

This tells use that the variable `senate_control` has missing values (`NA`), a `1.0`, a `0.0` and a `0.5`. Remember that the codebook tells us that 1 = Democrats, 0 = Republicans, .5 = split. Let's tell R that this is what these values mean.

```{r}
data <- # assign the changes to the object called data
  data %>% # use the object called data and then ...
  mutate(senate_control = factor(x = senate_control, # use the variable senate_control
                                 levels = c(0.0, 0.5, 1.0), # the values of the variables
                                 # assign labels to these values
                                 labels = c("Republican", "Split", "Democrat")),
         house_control = factor(x = house_control,
                                levels = c(0.0, 0.5, 1.0),
                                labels = c("Republican", "Split", "Democrat")),
         treatment = factor(x = treatment,
                            levels = c(0, 1),
                            labels = c("No", "Yes")))
```

Now let's look at what we did.

```{r}
summary(data$senate_control)
```

We could also create new indicator variables for each of the variables with multiple levels. This might make it easier to use, but it isn't necessary.

```{r}
data <-
  data %>%
  mutate(house_rep_control = ifelse(house_control == "Republican", yes = 1, no = 0))
         # in english, this line of code says, create a variable called
         # house_rep_control equal to 1 if house_control is equal to Republican
         # but if house_control is not equal to Republican then set
         # house_control equal to 0

# let's repeat this code for the other variables
data <-
  data %>%
  mutate(house_dem_control = ifelse(house_control == "Democrat", yes = 1, no = 0),
         senate_dem_control = ifelse(senate_control == "Democrat", yes = 1, no = 0))

# finally, let's tell R that these indicator variables aren't continuous
# variables - they can only have two values 0 or 1
data <-
  data %>%
  mutate(house_dem_control = as_factor(house_dem_control),
         senate_dem_control = as_factor(senate_dem_control))

# now we have indicator variables for Democratic control of the house and senate
data %>% # notice that there's no assignment here
  select(house_dem_control, senate_dem_control) %>%
  summary()
```

Since we're sure that the missing values in the dataset are coded correctly, let's drop the rows that are missing data for our outcome and key predictor variables and preview the data again:

```{r}
# filter out the rows of data that are missing data for the treatment
# ! is the operator for "not" and the function is.na() checks to see if a
# variable is missing. Try running it on your own.
data <-
  data %>%
  filter(!is.na(treatment)) %>% # filter out missing rows of treatment
  filter(!is.na(healthspendpc)) # filter our missing rows of healthspendpc

# a faster way to drop missing values is to use the function drop_na()
data <-
  data %>%
  drop_na(treatment, healthspendpc) # without a column in the function, it will drop missing values in
# all rows of all columns

data %>% glimpse()
```

Much better! Now let's select only the variables we need for our analysis.

```{r}
data <-
  data %>%
  select(year, state, healthspendpc, treatment, senate_control, senate_ideology,
         house_control, house_ideology)
```

As a final step, let's adjust our expenditure variable for inflation. To do so, we'll use the `blscrapeR` package with allows us to directly download Consumer Price Index (CPI) data which we need to adjust for inflation:

```{r}
# adjust values for inflation
library(blscrapeR)

# we'll use 1996 as the base year because that's when the treatment started
real.values <- inflation_adjust(base_year = 1996)

real.values <-
  real.values %>%
  mutate(year = as.numeric(year)) %>%
  select(year, adj_value)

# now we need to join the CPI data with our orignial data
data <- left_join(
  data,
  real.values,
  by = c("year")
)

# finally, we'll multiply the expendature amounts by the adjusment value to
# get inflation adjusted values
data <-
  data %>%
  mutate(real_healthspendpc = healthspendpc * adj_value)
```


## Step 3: Exploratory Analysis

Before running any models, it is important that you become an expert on your data. This is easy with a small dataset, but can get harder when you are working with a lot of variables. Here are some examples of questions you should ask about your data:

- What do the distributions of my variables look like?
- What are means and standard deviations?
- What is the relationship between variables?

Answering these questions will help you identify errors in your data - errors that could lead to erroneous regression results.

Let's load the package [`DataExplorer`](https://cran.r-project.org/web/packages/DataExplorer/vignettes/dataexplorer-intro.html) which provides a lot of great tools for data exploration.

```{r messages = FALSE}
library(DataExplorer)

# create a table of summary information
introduce(data)

# plot this table
plot_intro(data)
```

7% of our data is missing. Let's see where that missing data is coming from:

```{r}
plot_missing(data)
```

Let's look at some of variable distributions:

```{r}
# bar plot
plot_bar(data)

# histogram
plot_histogram(data) # note that we only get histrgrams for continuous variables
```

Now let's look at health care spending by treatment and control groups (states with and without the policy I'm interested in).

```{r}
ggplot(data = data, aes(x = treatment, y = healthspendpc)) +
  geom_point() # this tells R to make a plot with points
```

With the exception on one outlier, it looks like states with bans on incentives for doctors spend slightly more on health care.

We could even plot the treatments on a map:

```{r}
library(mapproj)

# Get US Map Coordinates
us <- map_data("state")

# get the data we need for the map from our variables
plot.data <-
  data %>%
  filter(year == 1996) %>% # we'll plot the map for the year 1996
  select(state, treatment) %>%
  mutate(state = str_to_lower(state)) # we need to lowercase the state names

# Merge Limit Data with Map Coordinates
map.data <- left_join(
  us,
  plot.data,
  by = c("region" = "state") # merge by region (which is called state in our data)
)

# plot the map
ggplot(data = map.data %>% filter(!is.na(treatment)),
         mapping = aes(x = long, y = lat, group = group, fill = treatment)) +
  geom_polygon(color = "gray20", size = 0.10) +
  labs(x = NULL, y = NULL, title = "States that Ban Financial Incentives in the Year 1996") +
  coord_map("albers", lat0 = 39, lat1 = 45) +
  theme(panel.border =  element_blank()) +
  theme(panel.background = element_blank()) +
  theme(axis.ticks = element_blank()) +
  theme(axis.text = element_blank())
```

Finally, let's create a table of summary statistics.

```{r}
# basic
summary(data)

# fancy
data %>%
  # convert factor variables to dummies using the fastDummies package
  fastDummies::dummy_cols(select_columns= c("treatment", "senate_control",
                                            "house_control")) %>%
  as.data.frame %>% # convert object to a data frame
  drop_na() %>% # drop missing values
  stargazer::stargazer(.,
                       type = "text",
                       style = "apsr",
                       summary.stat = c("mean", "sd", "min", "max"))

# summary statistics by group
data %>%
  # convert factor variables to dummies using the fastDummies package
  fastDummies::dummy_cols(select_columns= c("senate_control", "house_control")) %>%
  as.data.frame %>%
  drop_na() %>%
  # summary statistics by treatment using the psych package
  psych::describeBy(group = .$treatment)
```

Does it look like the treatment and control groups are well balanced?


## Step 4: Develop a Statistical Model and Analyse your Data

### Treatment Indicator Model

Now, to test my research question, I will use the following statistical model:

$$\log(\text{Health Spending})_{it} = \alpha_{it} + \beta_{1,it} \times \text{T}_{it} + \epsilon{it}$$

where T is the treatment. However, because I only want to test my research question for one year of data, I add the following option to my data object: `%>% filter(year == 1996)`, since 1996 is when some of my states had the treatment and some did not.

We can estimate this model in R using the `lm()` command. As with all other parts of R, if we want to save the model, we need to assign it to an object:

```{r}
# the ~ essentially means =
model.01 <- lm(real_healthspendpc ~ treatment,
               data = data %>% filter(year == 1996)) # use the data in the object called "data"

# now let's view the model summary
summary(model.01)

# to look at the output with confidence intervals (and without stars!) we'll
# use the broom package
library(broom)
tidy(model.01, conf.int = TRUE)
```

Our model says that adopting policies that ban financial incentives for doctors increases a state's per capita spending on health care by about $241. In other words, there's not much of an effect.

Now the model with controls:

$$\log(\text{Health Spending})_{it} = \alpha_{it} + \beta_{1,it} \times \text{T}_{it} + \beta_{2,it} \times \text{DemHouse}_{it} + \beta_{3,it} \times \text{DemSenate} + \beta_{4,it} \times \text{SenateIdeo}_{it} + \beta_{5,it} \times \text{HouseIdeo}_{it} + \epsilon{it}$$

```{r}
model.02 <- lm(real_healthspendpc ~ treatment + senate_control + house_control +
                 senate_ideology + house_ideology,
               data = data %>% filter(year == 1996))
summary(model.02)

tidy(model.02, conf.int = TRUE)
```

Notice how much the point estimate slightly decreases after including controls. Now the model is telling us that a when a state adopts policies that ban financial incentives for doctors increases a state's per capita spending on health care by about $233.

We can create a table of results using a function called `stargazer`.

```{r message = FALSE, warning = FALSE}
library(stargazer)

stargazer(model.01, model.02,
          out = c("model_results.txt"), # file path to save the table
          type = "text",
          # now label our variables
          covariate.labels = c("Received Treatment",
                               "Control of Senate is Split",
                               "Senate Controlled by Democrats",
                               "Control of House is Split",
                               "House Controlled by Democrats",
                               "Senate Ideology Score",
                               "House Ideology Score"),
          # Now label our outcome variable
          dep.var.labels = c("Real Health Care Spending Per Capita"))
```

Now you have a nicely formatted results table in your working directory. Go check it out!

Now let's plot our results:

```{r}
# create a new data set with the values of the predictor variables that we want
# to create predictions for.
# control outcomes
no.treat.data <- expand.grid(
  year = unique(data$year),
  state = unique(data$state),
  treatment = "No", # this will predict outcomes for the control group
  senate_control = "Democrat",
  house_control = "Democrat",
  house_ideology = mean(data$house_ideology, na.rm = TRUE),
  senate_ideology = mean(data$senate_ideology, na.rm = TRUE)
)

# predict the outcome based on the data we created with confidence intervals
no.treat.preds <- predict(model.02, newdata = no.treat.data, interval = "confidence")

# convert the predictions to a dataframe
no.treat.preds <-
  as.data.frame(no.treat.preds) %>%
  rename(pred = fit,
         .upper = upr,
         .lower = lwr) %>%
  slice(1) %>% # only select the first row
  mutate(group = "control")

# Treatment outcomes
treat.data <- expand.grid(
  year = unique(data$year),
  state = unique(data$state),
  treatment = "Yes", # this will predict outcomes for the treatment group
  senate_control = "Democrat",
  house_control = "Democrat",
  house_ideology = mean(data$house_ideology, na.rm = TRUE),
  senate_ideology = mean(data$senate_ideology, na.rm = TRUE)
)

# predict the outcome based on the data we created with confidence intervals
treat.preds <- predict(model.02, newdata = treat.data, interval = "confidence")

# convert the predictions to a dataframe
treat.preds <-
  as.data.frame(treat.preds)  %>%
  rename(pred = fit,
         .upper = upr,
         .lower = lwr) %>%
  slice(1) %>% # only select the first row
  mutate(group = "treatment")

# combine both sets of predictions into one dataframe
preds <- bind_rows(no.treat.preds, treat.preds)

# Now plot the predictions!
ggplot(data = preds, aes(y = pred, ymin = .lower, ymax = .upper, x = group)) +
  geom_errorbar(width = .1) + # add the confidence intervals
  geom_point() + # add the predicted value
  scale_y_continuous(breaks = scales::pretty_breaks(n = 7),
                     labels = scales::dollar_format()) +
  scale_x_discrete(labels = c("Control Group", "Treatment Group")) +
  ggpubr::theme_pubr() +
  labs(x = "", # leave the x-axis blank
       y = "Predicted Spending Per Capital on Health Care")
```

### Differences-in-differences Model

With differences-in-differences estimation, our goal is to control for differences in the treatment and control groups by look only at how the change over time. A simple estimation of this uses this formula:

$$
\text{DiD Estimate} = \text{E}[Y^{after}_{treated} - Y^{after}_{control}] - \text{E}[Y^{before}_{treated} - Y^{before}_{control}]
$$

This gives us the difference in the treatment group ($\text{E}[Y^{after}_{treated} - Y^{after}_{control}]$) minus the difference in the control group ($\text{E}[Y^{before}_{treatment} - Y^{before}_{control}]$). We'll let at several different ways to calculate the DiD estimate depending on our data structure.

Because we only want to compare two states, we'll need to start by dropping all other states from our data. To do this, we'll use the `filter`. For my project, California is the treatment state and Texas is my control state. Note that the `|` operator means "or."

```{r}
diff.in.diff.data <-
  data %>%
  filter(state == "California" | state == "Texas")
```

Now if you look at your data, the only states that you will have are California and Texas.

Now let's add a variable to identify which states are affected by the treatment and the first year that the receive the treatment.

```{r}
diff.in.diff.data <-
  diff.in.diff.data %>%
  mutate(treatment_group = ifelse(state == "California", 1, 0))
```


Now we have a variable named `treatment_group` that tells us which states are in the treatment group.

Let's review the important elements of our dataset. We have a column called `treatment` that tells us the year when states in the treatment group received the treatment and we have a column called `treatment_group` that tells us which states are in the treatment group and which are in the control group.

For my project, Texas adopts the policy treatment in 1997, so if I include years after 1997 then my pre-post comparisons won't be accurate. California adopts the treatment in 1996 and Texas adopts it in 1997. In order to account for this staggered policy adoption, I would need to develop a more complex statistical model. Instead of doing that, I'll just exclude the years after California adopts the treatment. That is, years after 1996.

Now, we'll need to remove years greater than 1996 in our estimation dataset. This means that we'll need to filter for years less than or equal to 1996:

```{r}
diff.in.diff.data <-
  diff.in.diff.data %>%
  filter(year <= 1996)
```

Before we calculate the DiD estimate, and since we have multiple pre-treatment periods, let's check the parallel trends assumption:

```{r}
ggplot(data = diff.in.diff.data,
       aes(x = year, y = real_healthspendpc, color = as_factor(treatment_group))) +
  geom_point() +
  geom_line() +
  labs(x = "Year", y = "Health Spending per Capita", color = "Treatment Group") +
  ggpubr::theme_pubr()
```


Now we're ready to calculate the DiD estimate:

```{r}
# pre-treatment
## treatment group
pre.tmean <-
  diff.in.diff.data %>%
  filter(treatment_group == 1) %>% # keep members of treatment group
  filter(treatment == "No") %>% # before they received the treatment
  summarise(pre_mean = mean(real_healthspendpc)) # calcualte average spending
pre.tmean

## control group
pre.cmean <-
  diff.in.diff.data %>%
  filter(treatment_group == 0) %>% # keep members of control group
  filter(treatment == "No") %>% # before anyone received the treatment
  summarise(pre_mean = mean(real_healthspendpc)) # calcualte average spending
pre.cmean

# pre-treatment difference
pre.tmean - pre.cmean

# post-treatment
## treatment group
post.tmean <-
  diff.in.diff.data %>%
  filter(treatment_group == 1) %>%
  filter(treatment == "Yes") %>%
  summarise(post_mean = mean(real_healthspendpc))
post.tmean

post.cmean <-
  diff.in.diff.data %>%
  filter(treatment_group == 0) %>%
  filter(treatment == "Yes") %>%
  summarise(post_mean = mean(real_healthspendpc))
post.cmean # what happened??
```

Why is our `control.diff` equal to `NaN` (which stands for not a number)? Go back and look through data for members of the control group. What is `filter(treatment == "Yes")` for states in the control group?

There are no states in the control group that have a value of "Yes" in the `treatment` column. That means that we can't calculate $\text{E}[Y^{after}_{control}]$, or more technically, $\text{E}[Y(T = 0 | D = 1)]$ where $D$ indicates treatment period and $T$ indicates group assignment.

How can we fix this? All we have to do is create a column that tells us when the treatment period starts (which is 1996 for our data):

```{r}
diff.in.diff.data <-
  diff.in.diff.data %>%
  mutate(treatment_period = ifelse(year == 1996, 1, 0))
```

Now let's look at California and Texas, a treatment and control members, to see what is going with these columns:

```{r}
diff.in.diff.data %>%
  select(year, state, treatment, treatment_group, treatment_period) %>%
  arrange(state)
```

For California, it doesn't look like there is any difference between the `treatment` and `treatment_period` columns. But what about Texas?

With the `treatment_group` and the `treatment_period` columns, we have all the ingredients that we need. Now let's finish calculating the post-treatment differences and the DiD estimate.

```{r}
# post-treatment
## treatment group
post.tmean <-
  diff.in.diff.data %>%
  filter(treatment_group == 1) %>%
  filter(treatment == "Yes") %>%
  summarise(post_mean = mean(real_healthspendpc))
post.tmean

post.cmean <-
  diff.in.diff.data %>%
  filter(treatment_group == 0) %>%
  filter(treatment_period == 1) %>%
  summarise(post_mean = mean(real_healthspendpc))
post.cmean

# post-treatment differences
post.tmean - post.cmean

# DiD estimate
(post.tmean - post.cmean) - (pre.tmean - pre.cmean)
```

Looks like the treatment has a negative effect on the log of health spending per capita. Specifically, when a state adopts policies that ban financial incentives for doctors decreases a state's per capita spending on health care by about `(exp(-0.03052237) - 1) * 100` = `r abs(round((exp(-0.03052237) - 1) * 100))` percentage points.

It's great that we have the DiD estimate, but if we want to conduct a hypothesis test we'll need to calculate its standard errors. The easiest way to do this is to run a regression. The specification we need to use is this:

$$
\log(\text{Health Spending})_{it} = \alpha + \beta_{1} \text{T}_{it} + \beta_{2} \text{G}_{it} + \beta_{3}\text{T}_{it} \times \text{G}_{it} + \epsilon{it}
$$
where $T$ is the `treatment_period`, $G$ is `treatment_group`, and $\beta_{3}$ is estimate for the interaction between `treatment_period` and `treatment_group` (this is the DiD estimate). Let's run it!

```{r}
# R is smart enough to include all three terms when we tell it to multiply
# to different variables
diff.in.diff <- lm(real_healthspendpc ~ treatment_period * treatment_group,
                   data = diff.in.diff.data)
summary(diff.in.diff)
```

Check out the estimate for our interaction `treatment_period:treatment_group`! Exactly what we calculated. Unfortunately, however, the treatment doesn't seem to have any effect. Let's add this model to our results table.

```{r warning = FALSE, results = "asis"}
stargazer(model.01, model.02, diff.in.diff,
          out = c("model_results.txt"), # file path to save the table
          type = "latex",
          # now label our variables
          covariate.labels = c("Received Treatment",
                               "Control of Senate is Split",
                               "Senate Controlled by Democrats",
                               "House Controlled by Democrats",
                               "Senate Ideology Score",
                               "House Ideology Score",
                               "Treatment Period",
                               "Treatment Group",
                               "Diff-in-Diff Estimate"),
          # Now label our outcome variable
          dep.var.labels = c("Real Health Care Spending Per Capita"))
```
