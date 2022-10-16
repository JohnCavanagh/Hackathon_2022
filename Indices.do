clear all

cd "" //Insert yout working directory

import delimited "SD_index_raw.csv" //Taking in the raw sociodemographic index

drop c //Dropping unused var


*** Standardizing before running through index
foreach x of varlist minorpct-prop_migrant{
	qui: summ `x'
	replace `x' = (`x' - `r(mean)')/`r(sd)'
}

*** Running through index
swindex minorpct-prop_migrant,gen(SD_index)
export delimited using "SD_index_clean.csv", replace

**** Taking in raw clean energy index
import delimited "Env_index_raw.csv", clear
egen power = rowmax(v15-v19) // Generating one clean power variable -- the max of standardized versions of potential solar, wind, etc. 

*** Changing sign for distance vars so movements up or down mean the same thing
global negvars distance_t distance_1 distance_2 distance_3 
foreach x of global negvars{
	replace `x' = `x'*-1
}

*** Standardizing
foreach x of varlist estimated_-distance_3 power{
	qui: summ `x'
	replace `x' = (`x' - `r(mean)')/`r(sd)'	
}

*** Running through the index
swindex estimated_-distance_3 power,gen(env_index)
export delimited using "Env_index_clean.csv", replace //Exporting
