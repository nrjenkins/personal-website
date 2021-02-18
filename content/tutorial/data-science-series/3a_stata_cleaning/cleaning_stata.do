// Lab 4 - Cleaning Data in Stata
// start by setting the working directory
cd "/Users/nick/Documents/Teaching/workshops/data_science_series/3a_stata_cleaning"

// import data
import excel "leg_data.xlsx", firstrow clear

// let's see what we're dealing with
browse

// There are a bunch of issues here. Our goal is to get this data set into a 
// form where just looking at it provide a lot of useful information. 
// First, the variable names are not very imformative. We'll state by fixing
// them. Let's look at the codebook to firgue out what each variable is. The 
// codebook is on the sheet called "codebook" in the "leg_data.xlsx" file. 
rename x name
rename st state
rename cd cong_dist

// let's admire our work
browse

// Now let's deal with the variable values. What does it mean when party is 
// equal to 1? How about 2? Let's go back to the codebook. 
// Stata will let us give those 1's and 2's more imformative labels. We start
// by creating a label definition. 
label define party_label 1 "Republican" 2 "Democrat"
// This line basically says, "create a label (label define) called 'party' 
// (party) where a value of 1 equals 'Republican' and a value of 2 'Democrat'.
// Now let's admire our work. 
browse

// Nothing changed! That's because all we did was create a label definition 
// called 'party'. Now we need to apply the label to our data. We do that by 
// typing the command 'label values' then the variable name that we want to 
// label. In this case, that variable is 'party'. Finally, we have to tell 
// Stata what label definition we want to apply to the variable we picked. 
label values party party_label

// Now admire!
browse

// We can also get info about variables with the command 'codebook'
codebook party

// or 'tab'
tab party

// Next, let's deal with the missing data. Stata codes missing values as '.'
// In the party column, we see a value of -99 which likely indicates a missing
// value. We need to recode that to '.'
replace party = . if party == -99

// Let's look!
browse

// Finally, let's Stata also allows us to create variable labels that give
// descriptions of what each variable is. Let's create two for 'name' and 
// 'party'.
label variable name "Legislator Name"
label variable party "State"

// Homework Problems //
// 1. Give XMP098 and M094 more informative variable names.


// 2. Give the values "1" and "2" of XMP098 informative labels.


// 3. Fix the missing value of "-6" in XMP098.


// 4. Give all the remaining variables information descriptions. 


// 5. What is the average birth year?
