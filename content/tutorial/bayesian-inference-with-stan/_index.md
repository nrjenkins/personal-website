---
# Course title, summary, and position.
linktitle: Bayesian Inference Using Stan
summary: Learn how to use Stan and R to estimate Bayesian models.
weight: 10

# Page metadata.
title: Tutorial Overview
date: "2018-09-09T00:00:00Z"
lastmod: "2018-09-09T00:00:00Z"
draft: false  # Is this a draft? true/false
toc: true  # Show table of contents? true/false
type: docs  # Do not modify.

# Add menu entry to sidebar.
# - name: Declare this menu item as a parent with ID `name`.
# - weight: Position of link in menu.
menu:
  stan:
    parent: Part A Introduction
    weight: 10
---

## Bayesian Inference with Stan

So, you want to learn how to use Stan? Maybe you have some experience using BUGS or JAGS and are looking to make the switch to Stan. Maybe you've been using the nicely packaged [RStanARM](http://mc-stan.org/rstanarm/index.html) or [BRMS](https://mc-stan.org/users/interfaces/brms) for Stan models and you want to learn how to code in raw Stan. Maybe you've never used Bayesian analysis and are looking to dive in head first! In any case, I wrote this tutorial because I wanted to get better at programming in Stan. 

I started out my Bayesian career using JAGS and quickly switched to using [RStanARM](http://mc-stan.org/rstanarm/index.html) and [BRMS](https://mc-stan.org/users/interfaces/brms) because of their power and convenience. But something just didn't seem right about not being proficient in using raw Stan, so I set out to write this tutorial series. 

I searched around for a long time for a good tutorial series on using Stan, but found that most are either too advanced or lack the explanations needed to truly understand what is going on. My goal is to rectify these issues. My primary focus, however on teaching you how to program in Stan and not to teach you about Bayesian methods. I think the tutorial will teach you something about Bayesian methods, but that's just a bonus. 

In this tutorial, I will use [RStan](https://mc-stan.org/rstan/) and [CmdStanR](https://mc-stan.org/cmdstanr/) to interface with Stan through R and will also make frequent use of the [tidyverse](https://www.tidyverse.org). I won't be teaching any R code, so I will assume that you have some basic understanding of how to use R and the tidyverse packages. 

## What is Stan?

[Stan](https://mc-stan.org) is a programming language for Bayesian inference that uses Hamiltonian Monte Carlo sampling. Hamiltonian Monte Carlo (HMC) sampling uses on gradian evaluation to sample from the posterior which is much more efficient than other sampling methods like Metropolis-Hastings and Gibbs sampling. As a result, HMC can achieve convergence much faster than these alternative samplers.
