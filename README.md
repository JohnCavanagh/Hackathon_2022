# Hackathon_2022
Repo for the Environmental Justice League technical appendix

The repository contains two scripts:

- Create_raw_indices.R
- Indices.do

The first downloads data, cleans it, generates the variables of the indices, and exports. The second takes the raw variables, prepares them for index creation, and creates the two indices.

# Data sources:
Data is pulled from the following locations:

- [The American Community Survey from the U.S. census](https://www.census.gov/programs-surveys/acs)
  - Information for variables on occupation, migration status, and healthcare status.
- [The EPA's Re-powering mapper](https://www.epa.gov/re-powering/mapper-technical-document)
  - Information for the variables on clean energy viability on brownfield sites used to create the Clean energy viability index
- NRDC's enriched EJ dataset
  - For geocoded information on the remaining variables in the sociodemographic index.
  
# Methods:
The two indices are created using the following variables:

- Clean energy viability index:
  - Index of variables in EPA empower dataset:
  - Highest standardized of one of the following:
      - Potential wind power
      - Potential solar power
      - Potential bioenergy
  - Distance to nearest substation
  - Distance to nearest road
  - Distance to nearest railroad
  
 - Sociodemographic Vulnerabiltiy index:
  - % People of color
  - % Low income
  - Unemployment rate
  - % limited english speaking
  - % < high school education
  - % under 5
  - % over 64
  - % migrant
  - % no health insurance
  - % extractive industries
  - % of labor force in blue collar jobs relevant to clean energy construction/generation
  - % of labor force in white collar jobs relevant to clean energy construction/generation
  
Indices are created by standardizing the variables, making sure all signs are such that an increase in the standardized version makes the index more likely to be targeted (i.e., increases in clean energy viability or increases in the likelihood of benefit. Indices are calculated using the procedure outlined in [Schwab et al. 2020](http://www.stata-journal.com/article.html?article=st0622).



