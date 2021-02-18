// Modeling in Stata
// Set working directory
cd "/Users/nick/Documents/Teaching/workshops/data_science_series/5a_stata_modeling"

import delimited "mpg.csv", clear

// Let's estimate the relationship between highway MPG and engine 
// displacement. Does the size of the engine affect highway MPG? Before we do
// let's take a look at the scatter plot between these variables. 
twoway scatter hwy displ

// Now let's estimate a regression to quantify this relationship.
reg hwy displ

// The intercept estimate is 35.69 and the slope estimate is -3.53.


// Now, let's create a table of regression results.
ssc install outreg2 // install the outreg2 package
outreg2 using results_table.doc, replace

// If we have variable labels, then we can use them in outreg.
label var hwy "Highway MPG"
label var displ "Engine Displacement"

outreg2 using results_table.doc, replace label

// We can also label the columns.
outreg2 using results_table.doc, replace ctitle(Model 1) label

// Let's add some control variables.
reg hwy displ year cyl

// Now add this model's results to the table we just created. 
outreg2 using results_table.doc, append label

// Let's add better model labels.
outreg2 using results_table.doc, append ctitle(Model 2) label


// Model prediction
reg hwy displ year cyl
margins, at(displ = 7 year = 2008 cyl = 8)

// Beyond Linear Regression
logit y x1 x2 x3

probit y x1 x2 x3

poisson y x1 x2 x3

// Homework Problems //
// 1. Estimate a regression looking at the relationship between city MPG and 
// engine displacement.


// 2. Estimate another model with year and the number of cylinders as controls.


// 3. Create a results table with both models and everything informatively 
// labeled. 
