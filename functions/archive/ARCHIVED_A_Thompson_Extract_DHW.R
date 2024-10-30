library(stars)
library(ncmeta)
library(lubridate)
library(tidyverse)
library(dataaimsr) #load the aims datasets


#back-catalogue 1985-2019 ofannual max DHW values
# for (year in seq(1985,2019,1))  # retrieve current year estimates to append to previous years
# {
#   startUrl<-'ftp://ftp.star.nesdis.noaa.gov/pub/sod/mecb/crw/data/5km/v3.1/nc/v1.0/annual/ct5km_dhw-max_v3.1_'
#   endUrl<-'.nc'
#   url <- paste (startUrl, year, endUrl, sep="")
#   fname<-paste ('../../GIS/DHWnetCDF/dhw', year, '.nc', sep="")
#   download.file(url, fname, mode = 'wb')
# }

#current year to add to back-catalogue NOTE assumes, reasonabliy, that max DHW occurs in fist half of the year.


gbr.sf <- sf::read_sf('X:/Reports/GIS/Great Barrier Reef Marine Park Boundary/Great_Barrier_Reef_Marine_Park_Boundary.shp')

#read in waterbodies data from the gisaimsr package
data("gbr_bounds", package = "gisaimsr")

gbr.sf <- gbr_bounds


#Set year
year=2022


startUrl<-"https://www.star.nesdis.noaa.gov/pub/sod/mecb/crw/data/5km/v3.1_op/nc/v1.0/daily/year-to-date/ct5km_dhw-max-ytd_v3.1_"
endUrl<-"0630.nc"
url <- paste (startUrl, year, endUrl, sep="")
fname<-paste ('DHWnetCDF/dhw',year, '.nc', sep="")
download.file(url, fname, mode = 'wb')

### Check what is included   
xx<-nc_atts(paste ('DHWnetCDF/dhw',year,'.nc',sep="")) 
# CRS= EPSG:32663 - this is WGS84

qld.box<-st_bbox(c(xmin=142, ymin=-26,xmax=155,ymax=-9),crs=7844)

#ensure change object year "dhwYYY"
dhw2022=read_ncdf(paste('DHWnetCDF/dhw', year, '.nc', sep=""), var=c("degree_heating_week")) %>%
  st_set_crs(4326) %>% #WGS84
  st_transform(7844) %>% #GDA2020
  st_crop(qld.box) %>%
  .[gbr.sf] %>% # mask to just the gbr
  as_tibble()  %>%
  filter(!is.na(degree_heating_week) & degree_heating_week>-1) %>%
  mutate(dhw=as.vector(degree_heating_week),
         Year=year) 
#ensure update name of object and saved file
save(dhw2022, file='DHW_GBR/dhw2022.RData')
