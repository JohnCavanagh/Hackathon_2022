rm(list = ls()) ##Clean up workspace
library(plyr)
library(dplyr)
library(tidyr)
library(stringr)
library(pals)
library (sp)
library (rgdal)
library(rgeos)
library(classInt)

setwd("~/Documents/Hackathon")

###################### Getting census data ###########################################

##### Getting HH data
## State abbreviations to loop through
x <- read.delim("Data/ACS/abrevs.txt")
abr <- str_to_lower(x$State.Abrev)
main_path <- "https://www2.census.gov/programs-surveys/acs/experimental/2020/data/pums/1-Year/csv_h"
paths <- c()
for (i in 1:length(abr)){
  pn <- paste0(main_path, abr[i],".zip")
  paths <- c(paths, pn)
}

for (i in 1:length(paths)){
  np <- paste0("Data/ACS/",abr[i],".zip")
  try(download.file(paths[i], np))
}

setwd("~/Documents/Hackathon/Data/ACS")
dir <- list.files()
for (i in 1:length(dir)){
  try(unzip(dir[i]))
}

main_df <- read.csv("psam_h01.csv", stringsAsFactors = F)
for (i in 2:56){
  if (i < 10){
    num = as.character(i)
    num = paste0("0",num)
  }
  else{
    num = as.character(i)
  }
  path <- paste0("psam_h",num,".csv")
  try(df <- read.csv(path, stringsAsFactors = F))
  try(main_df <- rbind.fill(main_df,df))
}

ACS <- write.csv(main_df, "ACS_full.csv", row.names = F)

####### Getting individual data
setwd("~/Documents/Hackathon")
x <- read.delim("Data/ACS/abrevs.txt")
abr <- str_to_lower(x$State.Abrev)
main_path <- "https://www2.census.gov/programs-surveys/acs/experimental/2020/data/pums/1-Year/csv_p"
paths <- c()
for (i in 1:length(abr)){
  pn <- paste0(main_path, abr[i],".zip")
  paths <- c(paths, pn)
}

for (i in 1:length(paths)){
  np <- paste0("Data/ACS/",abr[i],".zip")
  try(download.file(paths[i], np))
}

setwd("~/Documents/Hackathon/Data/ACS")
dir <- list.files()
for (i in 1:length(dir)){
  try(unzip(dir[i]))
}

ind_df <- read.csv("psam_p01.csv", stringsAsFactors = F)
for (i in 2:56){
  if (i < 10){
    num = as.character(i)
    num = paste0("0",num)
  }
  else{
    num = as.character(i)
  }
  path <- paste0("psam_p",num,".csv")
  try(df <- read.csv(path, stringsAsFactors = F))
  try(ind_df <- rbind.fill(ind_df,df))
}

write.csv(ind_df, "ACS_full_ind.csv", row.names = F)

###### Getting crosswalk between census PUMA areas and census tracts for EJ merge
setwd("~/Documents/Hackathon")
ind_df <- read.csv("Data/ACS/ACS_full_ind.csv")

census_cross <- download.file("https://www2.census.gov/geo/docs/maps-data/data/rel2020/2020_Census_Tract_to_2020_PUMA.txt", 
                              "Data/ACS/cross.txt")
census_cross <- read.csv("Data/ACS/cross.txt")

census_cross$sfp <- as.character(census_cross$STATEFP)
for (i in 1:nrow(census_cross)){
  if (nchar(census_cross$sfp[i]) == 1){
    census_cross$sfp[i] <- paste0("0", census_cross$sfp[i])
  }
}

census_cross$cfp <- as.character(census_cross$COUNTYFP)
for (i in 1:nrow(census_cross)){
  if (nchar(census_cross$cfp[i]) == 1){
    census_cross$cfp[i] <- paste0("00", census_cross$cfp[i])
  }
  else if (nchar(census_cross$cfp[i]) == 2){
    census_cross$cfp[i] <- paste0("0", census_cross$cfp[i])
  }
}

census_cross$tfp <- as.character(census_cross$TRACTCE)
for (i in 1:nrow(census_cross)){
  if (nchar(census_cross$tfp[i]) == 3){
    census_cross$tfp[i] <- paste0("000", census_cross$tfp[i])
  }
  else if (nchar(census_cross$tfp[i]) == 4){
    census_cross$tfp[i] <- paste0("00", census_cross$tfp[i])
  }
  else if (nchar(census_cross$tfp[i]) == 5){
    census_cross$tfp[i] <- paste0("0", census_cross$tfp[i])
  }
}

census_cross$tract <- paste0(census_cross$sfp,census_cross$cfp,census_cross$tfp)
census_cross$nc <- nchar(census_cross$tract)

################ Cleaning census data and generating index vars
ind_df <- select(ind_df, c(RT:AGEP,HICOV,OCCP,MIGPUMA))
ind_df$OBS <- substr(as.character(ind_df$OCCP),1,2)
ind_df$BCF <- ifelse(
  ind_df$OBS == "45"|ind_df$OBS == "49"|ind_df$OBS == "47"|ind_df$OBS == "51"|
    ind_df$OBS == "53",1,0
)
ind_df$WCF <- ifelse(
  ind_df$OBS == "19"|ind_df$OBS == "17",1,0)

ind_df$OF <- ifelse(ind_df$WCF >0 | ind_df$BCF >0,1,0)
ind_df$EF <- ifelse(substr(as.character(ind_df$OCCP),1,3) == "475",1,0)

ind_df$uninsure <- ifelse(ind_df$HICOV == 2,1,0)
ind_df$migrant <- ifelse(ind_df$MIGPUMA >1,1,0)
ind_df$migrant <- ifelse(is.na(ind_df$migrant),0,ind_df$migrant)

ACS_ind_coll <- ind_df %>%
  group_by(PUMA) %>%
  dplyr::summarise(Prop_BlueCollar_Rel = mean(BCF, na.rm = T),
                   Prop_WhiteCollar_Rel = mean(WCF,na.rm = T),
                   Prop_Any_Rel = mean(OF,na.rm = T),
                   Prop_Extractive = mean(EF, na.rm = T),
                   Prop_uninsured = mean(uninsure, na.rm = T),
                   Prop_migrant = mean(migrant, na.rm = T)
  )

cc <- select(census_cross, c(tract,PUMA5CE))
fb <- merge(ACS_ind_coll, cc, by.x = "PUMA", by.y = "PUMA5CE", all.x = T)

############### Cleaning EJ data and generating index vars #####
EJ <- readOGR(dsn = "Data/EPA-EJScreen", layer = "EJSCREEN_FULL-Enriched")
EJ_df <- data.frame(EJ)
rm(list = c("EJ"))
EJ_df <- select(EJ_df, c(ID:Count_plan,MINORPCT,LOWINCPCT,LESSHSPCT,LINGISOPCT, UNDER5PCT, OVER64PCT,UNEMPPCT))
EJ_df$ID <- as.character(EJ_df$ID)
EJ_df$c <- nchar(EJ_df$ID)
EJ_df$tract <- substr(EJ_df$ID, 1,nchar(EJ_df$ID)-1)

SD <- merge(EJ_df, fb, by = "tract") #### Merging sociodemographic vars together
write.csv(SD, "Data/SD_index_raw.csv")

############### Cleaning EP epower data and generating index vars #########
EPA_re <- readOGR(dsn = "Data/EPA RE-Powering", layer = "epa-re-powering-brownfields-sites")
ep <- data.frame(EPA_re)
rm(list = c("EPA_re"))

ep <- select(ep, c(Cross_Refe:Site_ID,Estimated_, Estimated1,Cumulative,Cumulati_1,Surface_Te,Distance_t,Distance_1,Distance_2,Distance_3))
ep$tot <- ep$Estimated_ + ep$Estimated1
max <- sum(ep$tot, na.rm = T)


ep$Surface_Te <- as.numeric(ep$Surface_Te)
for (i in 6:10){
  j = i + 9
  mn <- mean(ep[,i], na.rm = T)
  sd <- sd(ep[,i], na.rm = T)
  ep[,j] <- (ep[,i] - mn)/sd
}

write.csv(ep, "Data/Env_index_raw.csv")


