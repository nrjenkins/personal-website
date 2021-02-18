// first we need to set a working directory. A working directory is basically
// a folder. If you double click on a folder called "Downloads" then that 
// path to that folder would be considered your working directory. 
// So, the first step is that we need to tell Stata what folder we are working 
// out of.

// What directory are we in now?
cd

// if we type "help cd" we can find the arguments that "cd" takes
help cd

// set the working directory 
cd "/Users/nick/Documents/Teaching/workshops/data_science_series/2a_stata_intro"

// now, we need to use a function to import the data into Stata. The function
// we need is "import excel" since we are using an xlsx file. Let's look at the
// options first.
help import excel

// Our data is stored on the sheet called "cd_data", remember? So, we'll need 
// to use the "sheet" argument. We'll also want to tell Stata that the first 
// row of data are actually the names of the variables. We'll also convert all 
// variable names to lower case to make it eaiser to work with. 
import excel "excel_lab.xlsx", sheet("cd_data") firstrow case(lower) 

// Let's work through the questions we answered using excel //

// 1. What does each row of data describe?
browse

// 2. How many rows of data are there?
describe

// 3. What is the average over 65 population across all congressional 
// districts?
mean age65

// 4. Create an indicator variable for California called "ca_dum"
generate ca_dum = 0
replace ca_dum = 1 if state == "CA"
replace ca_dum = .  if missing(state)

// 5. What is the average over 65 population in each state?
mean age65, over(state) // What is the error message? 

mean age65, over(fipstate)

// 6. How many total blue collar workers are there in each state?
sort fipstate 
by fipstate: egen sum_blucllr = total(blucllr)


// HOMEWORK PROBLEMS //
// run this command
clear

// 1. Import the data on the "cd_data" sheet in the "excel_lab.xlsx" file


// 2. What is the average military population across all congressional 
// districts.


// 3. Create an indicator called "cd_dum" for when a congressional district 
// equals 10. 


// 4. How many total farmers are there in each state? (Name your variable 
// "tot_farmers").
