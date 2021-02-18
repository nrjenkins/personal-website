// Model Visualization in Stata
// Set working directory
cd "/Users/nick/Documents/Teaching/workshops/data_science_series/6a_stata_model_viz"

import delimited "mpg.csv", clear

// Estimate Model From Last Time
reg hwy displ year cyl

// Plotting the Fitted Line
twoway (lfitci hwy displ) (scatter hwy displ)

// Coefficient Plots
ssc install coefplot

reg hwy displ year cyl
coefplot

// drop the constant
coefplot, drop(_cons)

// add vertical line at 0
coefplot, drop(_cons) xline(0)


// Homework Problems //

// 1. Estimate a regression of city MPG on engine displacement.


// 2. Plot the fitted model against the data. 


// 3. Create a coefficient plot of the model's results. 

