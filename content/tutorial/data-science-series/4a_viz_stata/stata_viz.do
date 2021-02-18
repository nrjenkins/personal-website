// Cleaning Data in Stata
// start by setting the working directory
cd "/Users/nick/Documents/Teaching/workshops/data_science_series/4a_viz_stata"

// import data
import delimited "mpg.csv", clear

// One Variable Plots
hist displ

kdensity displ

// Two Variable Plots
twoway scatter hwy displ

// Grouped Plots
graph bar (mean) hwy, over(class)

graph bar, over(hwy) over(class)

// Customize Plot Appearance
twoway scatter cty displ, xtitle(Engine Displacement) ytitle(Highway MPG) ///
title(Highway MPG vs. Engine Size)


// Homework Problems //
// 1. Create a histogram of cylinders. Why are there only three main spikes?


// 2. Create a scatter plot of city mpg and engine displacement.


// 3. Create a grouped bar plot of city mpg and vehicle class using the median 
// instead of the mean. 


// 4. Label the axes of the plot you just made. 
