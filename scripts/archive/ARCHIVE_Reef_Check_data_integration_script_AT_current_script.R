#------------------------------
# Coral Data Analysis - Inshore
#------------------------------

# load libraries

library(tidyverse)
library(tidyr)
library(dplyr)


#--------------------------------------------------------------------

standardisedScoreToGrade <- function(score) {
  Grade <- ifelse (score>=81,"A",
                   ifelse(score>=61,"B",
                          ifelse(score>=41,"C",
                                 ifelse(score>=21,"D",
                                        "E"))))
  return(Grade)
  
}

#----------------------------------------------------------#
##For Reef Check data weights are a function of the sqrt(number of points sampled) relative to sqrt(number of points sampled by MMP= 3200)
## note that LTMP samples 3000 points per reef however to be consistent with MMP reporting these are weighted the same as MMP Reefs
## note also that prior script from Tegan considered MMP to sample 1600 points (a single depth) rather than reef means being based on the mean of two depths=3200 points.

n.sites=c(1:4)

rc.weights<-data.frame(n.sites) %>%
  mutate(Weight=(1/sqrt(3200)/(1/(sqrt(n.sites*160)))))

#----------------------------------------------------------#
##Bringing in Reef Check data and converting to scores -  Note save  supplied .xlsx in .csv format and edit column names to remove % symbols##

Reef.Check.data<-read_csv("input/Reef_Check_Summary_Table_Reefs_2021.csv") %>%   
  dplyr::select(Reef.Name, Site.Name, Site.Number, Survey.date,  Live.Coral.Coverage) %>%
  mutate(Date=as.Date(Survey.date, "%d/%m/%Y")) %>%
  group_by(Reef.Name, Site.Name, Site.Number) %>%
  filter(Date==max(Date))  %>% # ensure only most recent surveys are included
  ungroup %>%
  group_by(Reef.Name, Site.Name) %>%
  transmute(Site.Name = ifelse(Site.Name == "Orpheus Island (Cattle Bay)", "Palms West",
                               ifelse(Site.Name == "Pelorus Island", "Palms West",Site.Name )),
            Site.Number, Survey.date, Live.Coral.Coverage, Date)%>%
  summarise(coral.cover=mean(Live.Coral.Coverage),
            n.sites=n()) %>%
  ungroup %>%
  mutate(CoralCover.score=coral.cover/75,
         Program='RCA') %>%
  left_join(rc.weights) %>%
  rename(Reef=Site.Name) %>%
  mutate(Zone=ifelse(Reef.Name=='Magnetic Island Reefs', 'Cleveland Bay',
                     ifelse(Reef.Name=='Palm Island Reefs', 'Halifax Bay',
                            'Offshore'))) %>%
  dplyr::select(-Reef.Name)
  
#----------------------------------------------------------#
##Bring in MMP/LTMP data##
#----------------------------------------------------------
#MMP.inshore.data<-read.csv(file.path(data.path,"Burdekin inner zone reef scores.csv"), strip.white = TRUE, sep=",", stringsAsFactors=FALSE,fileEncoding="UTF-8-BOM")
MMP.inshore.data<-read.csv('input/Burdekin inner zone reef scores.csv', strip.white = TRUE, sep=",")


#This is renaming the Magnetic file to Geoffrey Bay as it actually is Geoffrey Bay and it ensures the names matches with the other names
MMP.inshore.data <-MMP.inshore.data %>% mutate(REEF=str_replace(REEF, "Magnetic", "Geoffrey Bay"))

MMP.inshore.data<-MMP.inshore.data[,-1]

MMP.data.reef.mean <- MMP.inshore.data %>% group_by(REEF) %>% 
  summarise_at(vars(index.score, composition.score, CoralCover.score,coverchange.score, juv.score,ma.score, Year), function(x) mean(x, na.rm=TRUE)) %>%
  ungroup %>%
  filter(!REEF %in% c("Lady Elliot", "Middle Rf LTMP")) %>% #remove reefs not reported
  mutate(Weight=1,
         Program=ifelse(REEF %in% c('Havannah North', 'Pandora North'), 'LTMP','MMP'),
         Zone=ifelse(REEF=='Geoffrey Bay', 'Cleveland Bay', 'Halifax Bay')) %>%
  rename(Reef=REEF)
 

#----------------------------------------------------------------
#merge MMP/LTMP and RCA dataframes together, and delete rows not related to coral cover
All.Data <- MMP.data.reef.mean %>%
  dplyr::select(Program, Zone, Reef, CoralCover.score, Weight) %>%
  rbind(Reef.Check.data %>% dplyr::select(Program, Zone, Reef, CoralCover.score, Weight) %>% filter(!Zone=='Offshore'))

#sum of weights per zone
zone.weight<-All.Data %>%
  dplyr::select(Zone, Weight) %>%
  group_by(Zone) %>%
  summarise(Weight.zone=sum(Weight)) %>%
  ungroup


All.CoralCover<-All.Data %>% 
  left_join(zone.weight) %>% 
  mutate(Weight.score=CoralCover.score*(Weight/Weight.zone))

write_csv(All.CoralCover, file = "output/coral cover weight scores.csv")

zone.CoralCover.score<-All.CoralCover %>%
  group_by(Zone) %>%
  summarise(CoralCover.score=sum(Weight.score))
  
#********************************************************************************************************************
#Now need to replace the Geoffrey Bay scores as there are currently two Geoffrey Bay scores - one 
# calculated weighted average for individual sites if the data is to be presented as individual sites, not just zones.
#********************************************************************************************************************

# D Taylor update from here

# calculate the average scores per site based on the weighted averages where both Reef Check and MMP data are available.

reef.programs <- All.CoralCover %>%
  group_by(Reef) %>%
  summarise(Program)
  

freq.reef <- as.data.frame(table(reef.programs))%>%
  pivot_wider(names_from = Program, values_from = Freq) %>%
  mutate(Num.Programs = rowSums(freq.reef[,2:4]),
         Program = if_else(freq.reef$Num.Programs>1,
                           paste(ifelse(freq.reef$LTMP==1, "LTMP",""), " ", 
                                 ifelse(freq.reef$MMP==1, "MMP", ""), " ",
                                 ifelse(freq.reef$RCA==1, "RCA", "")),
                           paste(ifelse(freq.reef$LTMP==1, "LTMP",""), " ", 
                                 ifelse(freq.reef$MMP==1, "MMP", ""), " ",
                                 ifelse(freq.reef$RCA==1, "RCA", ""))))
freq.reef <- freq.reef %>%
  transmute(Reef, LTMP, MMP, RCA, Num.Programs,
            Program = trimws(Program, which = "both"))


All.CoralCover <- All.CoralCover %>%
  select(Zone, Reef, CoralCover.score, Weight, Weight.zone, Weight.score)%>%
  merge(freq.reef %>% 
          select(Reef, Program)) 
  

Reef.Data <- All.CoralCover %>%
  group_by(Reef) %>%
  summarise(Program,Zone, Reef, CoralCover.score, Weight,
            Reef.wgt.total = sum(Weight),
            CoralCover.wgt.score = CoralCover.score * Weight/Reef.wgt.total)

# The below is only separated so that the calculations above can be checked.

Reef.Coral.score <- Reef.Data %>%
  group_by(Zone, Reef, Program) %>%
  summarise(CoralCover.score = sum(CoralCover.wgt.score))
            
# combine with remainder of MMP data, replacing Coral Cover scores with weighted mean scores from MMP and Reef Check

Reef.Data <- MMP.data.reef.mean %>%
  select(Zone, Reef, composition.score,coverchange.score, juv.score, ma.score)%>%
  merge(Reef.Coral.score, all.y = TRUE) %>%
  relocate(Program, .after = Reef)

Reef.Data <- Reef.Data %>%
  select(Zone, Reef, Program, composition.score, CoralCover.score,coverchange.score, juv.score, ma.score)%>%
  mutate(index.score = round(rowMeans(Reef.Data[,4:8]*100)),
         index.grade = standardisedScoreToGrade(index.score))
  
zone.indicators <- Reef.Data %>%
  group_by(Zone) %>%
  summarise(composition.score = mean(composition.score, na.rm = TRUE),
            coverchange.score = mean(coverchange.score, na.rm = TRUE),
            juv.score = mean(juv.score,na.rm = TRUE),
            ma.score = mean(ma.score, na.rm = TRUE)) %>%
  merge(zone.CoralCover.score)
  
zone.indicators <- zone.indicators %>%  
  mutate(Zone, CoralCover.score, composition.score, coverchange.score, juv.score, ma.score,
         index.score = round(rowMeans(zone.indicators[,2:6], na.rm = TRUE)*100),
         index.grade = standardisedScoreToGrade(index.score))

write_csv(zone.indicators, file = "output/inshore_zone_indicators_score_grade.csv") 

zone.indicators$Reef <- ifelse(zone.indicators$Zone=="Cleveland Bay", "Cleveland Bay", "Halifax Bay")


All.CoralCover$Program <- as.factor(All.CoralCover$Program)
levels(All.CoralCover$Program)

zone.programs <- All.CoralCover %>%
  group_by(Zone) %>%
  summarise(Program)

freq <- table(zone.programs)


zone.indicators$Program <- ifelse(zone.indicators$Zone == "Cleveland Bay",
                                  paste(ifelse(freq["Cleveland Bay","LTMP"]>0, "LTMP",""),
                                        ifelse(freq["Cleveland Bay","MMP"]>0 && freq["Cleveland Bay","MMP   RCA"]>0,"MMP RCA",
                                               ifelse(freq["Cleveland Bay","MMP"]>0 && freq["Cleveland Bay","MMP   RCA"]==0,"MMP",
                                                      ifelse(freq["Cleveland Bay","MMP"]==0 && freq["Cleveland Bay","MMP   RCA"]>0,"MMP RCA",""))),
                                        ifelse(freq["Cleveland Bay","RCA"]>0 && freq["Cleveland Bay","MMP   RCA"]==0 ,"RCA",""), sep = " "),
                                  paste(ifelse(freq["Halifax Bay","LTMP"]>0, "LTMP",""),
                                        ifelse(freq["Halifax Bay","MMP"]>0 && freq["Halifax Bay","MMP   RCA"]>0,"MMP RCA",
                                               ifelse(freq["Halifax Bay","MMP"]>0 && freq["Halifax Bay","MMP   RCA"]==0,"MMP",
                                                      ifelse(freq["Halifax Bay","MMP"]==0 && freq["Halifax Bay","MMP   RCA"]>0,"MMP RCA",""))),
                                        ifelse(freq["Halifax Bay","RCA"]>0 && freq["Halifax Bay","MMP   RCA"]==0,"RCA",""), sep = " "))

All.Data.Final <- rbind(Reef.Data, zone.indicators)

str(All.Data.Final)

All.Data.Final$Zone <- as.factor(All.Data.Final$Zone)
levels(All.Data.Final$Zone)

All.Data.Final$Reef <- as.factor(All.Data.Final$Reef)
levels(All.Data.Final$Reef) 
All.Data.Final$Reef <- factor(All.Data.Final$Reef, 
                              levels = c("Alma Bay", "Florence Bay", "Geoffrey Bay", "Middle Reef", "Nelly Bay", "Cleveland Bay",
                                         "Fantome Island (Juno Bay)", "Havannah", "Havannah North",   
                                         "Orpheus Island (Pioneer Bay)", "Palms East",  "Palms West", "Pandora",  "Pandora North",
                                         "Halifax Bay"))
                                                                                                                 
               
All.Data.Final <- All.Data.Final %>%
  arrange(Reef) %>%
  transmute(Reef, Program,
            composition.score = round(composition.score*100),
            composition.grade = standardisedScoreToGrade(composition.score),
            CoralCover.score = round(CoralCover.score*100),
            CoralCover.grade = standardisedScoreToGrade(CoralCover.score),
            coverchange.score = round(coverchange.score*100),
            coverchange.grade = standardisedScoreToGrade(coverchange.score),
            juv.score = round(juv.score*100),
            juv.grade = standardisedScoreToGrade(juv.score),
            ma.score = round(ma.score*100),
            ma.grade = standardisedScoreToGrade(ma.score),
            index.score, index.grade)
            
All.Data.Final <- All.Data.Final %>%
  transmute(Reef, Program,
         "Composition of hard corals" =  ifelse(composition.score == "NA", "ND", paste(composition.score, " (",composition.grade,")")),
         "% Coral Cover" = ifelse(CoralCover.score == "NA", "ND", paste(CoralCover.score, " (",CoralCover.grade,")")),
         "% Change hard corals" = ifelse(coverchange.score == "NA", "ND", paste(coverchange.score, " (",coverchange.grade,")")),
         "Juvenile density" = ifelse(juv.score == "NA", "ND", paste(juv.score, " (",juv.grade,")")),
         "Macroalgae" = ifelse(ma.score == "NA", "ND", paste(ma.score, " (",ma.grade,")")),
         "Coral Indicator" = ifelse(index.score == "NA", "ND", paste(index.score, " (",index.grade,")")))
         


write_csv(All.Data.Final, file = "output/Inshore_Coral_for_report.csv") # this table to be included in the report



