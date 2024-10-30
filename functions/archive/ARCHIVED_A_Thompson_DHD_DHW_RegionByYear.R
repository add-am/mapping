
#library(mapping)
library(sf)
library(gridExtra)
library(raster)
library(lwgeom)
library(lubridate)
library(rgeos)
library(rgdal)
library(tidyverse)
library(stars)
library(ncmeta)
# library(rjson)
# library(geojsonR)

#Provide nrm and aims sector level dhw or DHD figures.
#crop the DHW and DHD.nc files for each year into regions
#colour to replicate product colour schemes
#output .png files.

# load data - assumes annual download of .nc files has occured.

## ---- Get_gbr
gbr.sf <- sf::read_sf('../../GIS/Great Barrier Reef Marine Park Boundary/Great_Barrier_Reef_Marine_Park_Boundary.shp')
#gbr.sf  #GDA94

qld.sf <- sf::read_sf('../../GIS/Features/Great_Barrier_Reef_Features.shp') %>%
    filter(FEAT_NAME %in% c("Mainland","Island"))

islands.sf <- sf::read_sf('../../GIS/Features/Great_Barrier_Reef_Features.shp') %>%
  filter(FEAT_NAME =="Island")
#qld.sf  #GDA94

#st_transform(7844) #GDA2020
 
nrm.sf <- sf::read_sf('../../GIS/Marine Regions/NRM_MarineRegions.shp') 
nrm <- nrm.sf %>% 
  st_intersection(gbr.sf) #%>% # cut the land section out
  #st_transform(st_crs(4326)) # nrm regions shapes are GDA94 (crs=4283), this puts it back to WGS84

nrm.names<-as.factor(as.character(unique(nrm$NAME)))
# wt.nrm<-nrm %>% filter(NAME=="Wet Tropics")
# b.nrm<-nrm %>% filter(NAME=="Burdekin")
# wh.nrm<-nrm %>% filter(NAME=="Mackay Whitsunday")
# fit.nrm<-nrm %>% filter(NAME=="Fitzroy")
# bm.nrm<-nrm %>% filter(NAME=="Burnett Mary")

dhd_cols<-c("#6B9E56", "#9EC08A","#D1E2BE","#FFFFCC","#FFFF00","#FFE900","#FFBF00", "#FF8A00","#FF5F00", "#FF0900",
            "#EB0000","#B30000","#890000","#4C0000","#390000","#130000","#000000")

#####------ DHD data
for(i in seq(2012,2022,1)){
for(ii in 1:nlevels(nrm.names)){
  Year=i
region=nrm.names[ii] %>% droplevels()

nrm.region.sf<-nrm %>% filter(NAME==region)

islands<-islands.sf %>%
  st_intersection(nrm.region.sf)

dhd=read_ncdf(paste ('../../GIS/DHDnetCDF/dhd', Year, '.nc', sep=""), var='dhd_mosaic_imos') %>%
  st_set_crs(4326) %>%  #WGS84
  st_transform(4283) %>% #GDA94
  .[nrm.region.sf] %>%
  as_tibble() %>%
  filter(!is.na(dhd_mosaic_imos)) %>%
  mutate(dhd=as.vector(dhd_mosaic_imos)) %>%
  mutate(dhd_cat=factor(ifelse(dhd<10,1,
                               ifelse(dhd<20,2,
                                      ifelse(dhd<30,3,
                                             ifelse(dhd<40,4,
                                                    ifelse(dhd<50,5,
                                                           ifelse(dhd<60,6,
                                                                  ifelse(dhd<70,7,
                                                                         ifelse(dhd<80,8,
                                                                                ifelse(dhd<90,9,
                                                                                       ifelse(dhd<100,10,
                                                                                              ifelse(dhd<110,11,
                                                                                                     ifelse(dhd<120,12,
                                                                                                            ifelse(dhd<130,13,
                                                                                                                   ifelse(dhd<140,14,
                                                                                                                          ifelse(dhd<150,15,
                                                                                                                                 ifelse(dhd<160,16,17))))))))))))))))))

# # returns a geotiff that is appropriately located on google earth but no data, just a black box
dhd.xyz<-dhd %>% filter(!is.na(dhd_cat)) %>% dplyr::select(lon, lat, dhd_cat)
#init = TO_GeoJson$new()
#a = init$Point(data = dhd.xyz)
dhd.raster <- rasterFromXYZ(dhd.xyz, crs="+proj=longlat +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +no_defs")
writeRaster(dhd.raster, filename =  paste('reefpage/dhd/',region,Year,'dhdRaster.tif', sep=""), format="GTiff", overwrite=TRUE)
plot(dhd.raster)
dhd.rat<-ratify(dhd.raster)
writeRaster(dhd.rat, filename =  paste('reefpage/dhd/',region,Year,'dhd.tif', sep=""), format="GTiff", overwrite=TRUE)
ss<-writeRaster(dhd.raster, 'new.grid', format="GTiff", datatype='INT2U', overwrite=TRUE)



#plot away
dhd.plot<-ggplot()+
  geom_tile(data=dhd, aes(y=lat, x=lon, fill=dhd_cat))+ #could use geom_raster if missing data
  coord_sf(crs=st_crs(4283), expand=FALSE)+ #provides projection to be used by sf objects and removes space around plot
  scale_fill_manual(values = dhd_cols, 
                    labels=c("<10","<20","<30","<40","<50","<60","<70","<80","<90","<100","<110","<120","<130","<140","<150","<160","160+"),
                    name="Degree Heating Days")+
  guides(fill = FALSE)+
  geom_sf(data=islands, fill=NA, show.legend = FALSE, size=1)+
  geom_sf(data=nrm.region.sf, fill=NA, show.legend = FALSE, size=1)+
  theme_void()
 
ggsave(filename=paste('reefpage/dhd/',region,Year,'dhd.png', sep=""),dhd.plot, width=9,height=5.5)
}
}


#################### DHW
#procees historical series of DHW from global scale .nc files to gbr sf files

qld.box<-st_bbox(c(xmin=142, ymin=-26,xmax=155,ymax=-9),crs=4283)

for(i in seq(1986,2015, 1)){
year=i
  dhw.i=read_ncdf(paste ('../../GIS/DHWnetCDF/dhw', year, '.nc', sep=""),var=c("degree_heating_week")) %>%
  st_set_crs(4326) %>% #WGS84
  st_transform(4283) %>% #GDA94
  #st_crop(qld.box) %>%
  .[gbr.sf] %>% 
    as.tibble %>%
  filter(!is.na(degree_heating_week) & degree_heating_week>-1) %>%
  mutate(dhw=as.vector(degree_heating_week),
         Year=i) 

save(dhw.i, file=paste('../../GIS/DHW_GBR/dhw',year,'.RData',sep=""))
}
###done to 2022, update below for future use

# for (i in 1986:2022){
#   year=i
# dhw.i=read_ncdf(paste ('../../GIS/DHWnetCDF/dhw', year, '.nc', sep=""),var=c("degree_heating_week")) %>%
#   st_set_crs(4326) %>% #WGS84
#   st_transform(4283) %>% #GDA94
#   .[gbr.sf]
# 
# save(dhw.i, file=paste('../../GIS/DHW_GBR/dhw',year,'.RData', sep=""))
# }


### DHW colours as per NOAA
# dhw.col<- c("200 250 250", "70 50 120", "100 80 150",
#             "130 110 180", "160 140 210", "255 255 0",
#             "255 220 0", "255 185 0", "255 150 0",
#             "255 0 0", "210 0 0", "160 0 0",
#             "110 0 0", "230 125 70",  "180 90 40", 
#             "125 60 30",  "85 45 20", "240 0 240", 
#             "200 0 200", "160 0 160", "120 0 120", "50 0 50")  
# dhw_cols<-colourvalues::convert_colours( 
#   matrix(as.numeric( unlist( strsplit(dhw.col, " ") ) ) , ncol = 3, byrow = T)
# )
#
#dhw.lab= c("0","<1","<2","<3","<4","<5","<6","<7","<8","<9","<10","<11","<12","<13","<14","<15","<16","<17","<18","<19","<20","20+")

#### DHW colours as per categories and colour blind friendly brewer
dhw_cols<-c("#2C7BB6", "#ABD9E9","#FFFFBF","#FDAE61","#D7191C")
dhw.lab= c("Bleaching low risk = 0 - 2 DHW",
           "Bleaching warning = 2 - 4 DHW",
           "Bleaching possible = 4 - 6 DHW",
           "Bleaching probable = 6 - 8 DHW",
           "Severe bleaching >8 DHW")

for(i in seq(1987,2022,1)){
  for(ii in 1:nlevels(nrm.names)){
    Year=i
    region=nrm.names[ii] %>% droplevels()
    
    nrm.region.sf<-nrm %>% filter(NAME==region)
    
    islands<-islands.sf %>%
      st_intersection(nrm.region.sf)
    
    #dhw=read_ncdf(paste ('../../GIS/DHW_GBR/dhw', Year, '.RData', sep=""), var='degree_heating_week') %>%
   dhw<-get(load(paste ('../../GIS/DHW_GBR/dhw', Year, '.RData', sep="")) ) %>%
     st_as_sf(coords=c("lon","lat"), crs=st_crs(4283)) %>%
     st_intersection(nrm.region.sf) %>% #this GDA94
      #st_set_crs(4326) %>%  #WGS84
      # st_transform(4283) %>% #GDA94
      st_transform(4326) %>% #WGS84
      # .[nrm.region.sf] %>%
      # mutate(lon=st_coordinates(.)[,1],
      #        lat=st_coordinates(.)[,2]) %>%
      as_tibble() %>%
     mutate(lon=st_coordinates(geometry)[,1],
            lat=st_coordinates(geometry)[,2]) %>%
      filter(!is.na(degree_heating_week)) %>%
      mutate(dhw=as.vector(degree_heating_week)) %>%
            
      # mutate(dhw_cat=factor(ifelse(dhw==0,0,
      #                              ifelse(dhw<1,1,
      #                                     ifelse(dhw<2,2,
      #                                            ifelse(dhw<3,3,
      #                                                   ifelse(dhw<4,4,
      #                                                          ifelse(dhw<5,5,
      #                                                                 ifelse(dhw<6,6,
      #                                                                        ifelse(dhw<7,7,
      #                                                                               ifelse(dhw<8,8,
      #                                                                                      ifelse(dhw<9,9,
      #                                                                                             ifelse(dhw<10,10,
      #                                                                                                    ifelse(dhw<11,11,
      #                                                                                                           ifelse(dhw<12,12,
      #                                                                                                                  ifelse(dhw<13,13,
      #                                                                                                                         ifelse(dhw<14,14,
      #                                                                                                                                ifelse(dhw<15,15,
      #                                                                                                                                       ifelse(dhw<16,16,
      #                                                                                                                                              ifelse(dhw<17,17,
      #                                                                                                                                                     ifelse(dhw<18,18,
      #                                                                                                                                                            ifelse(dhw<19,19,
      #                                                                                                                                                                   ifelse(dhw<20,20,21)))))))))))))))))))))))
    mutate(dhw_cat=factor(ifelse(dhw<2,1,
                                 ifelse(dhw<4,2,
                                        ifelse(dhw<6,3,
                                               ifelse(dhw<8,4,5))))))
  # save raster    
      dhw.xyz<-dhw %>% filter(!is.na(dhw_cat)) %>% dplyr::select(lon, lat, dhw_cat)
      #init = TO_GeoJson$new()
      #a = init$Point(data = dhd.xyz)
      dhw.raster <- rasterFromXYZ(dhw.xyz, crs="+proj=longlat +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +no_defs")
      #writeRaster(dhw.raster, filename =  paste('reefpage/dhd/',region,Year,'dhdRaster.tif', sep=""), format="GTiff", overwrite=TRUE)
      plot(dhw.raster)
      dhw.rat<-ratify(dhw.raster, crs="+proj=longlat +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +no_defs")
      writeRaster(dhw.rat, filename =  paste('reefpage/dhw/',region,Year,'dhw.tif', sep=""), format="GTiff", overwrite=TRUE)
                                                          
    #plot away
    dhw.plot<-ggplot()+
      geom_tile(data=dhw, aes(y=round(lat,10), x=round(lon,10), fill=dhw_cat))+ 
      #geom_tile(data=dhw, aes(y=lat, x=lon, fill=dhw_cat))+
      coord_sf(crs=st_crs(4326), expand=FALSE)+ #provides projection to be used by sf objects and removes space around plot
      scale_fill_manual(values = dhw_cols, 
                        labels=dhw.lab,
                        name="Degree Heating weeks")+
      #guides(fill = FALSE)+
      geom_sf(data=islands, fill=NA, show.legend = FALSE, size=1)+
      geom_sf(data=nrm.region.sf, fill=NA, show.legend = FALSE, size=1)+
      theme_void()
    
    ggsave(filename=paste('reefpage/dhw/',region,Year,'dhw.png', sep=""),dhw.plot, width=9,height=5.5)
  }
}
