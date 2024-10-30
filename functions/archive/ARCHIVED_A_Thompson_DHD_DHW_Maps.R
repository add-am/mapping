
#library(mapping)
library(sf)
library(gridExtra)
library(raster)
library(lwgeom)
library(lubridate)
library(rgeos)
library(rgdal)
library(colourvalues)
library(tidyverse)
#####----- Cyclone Maps for MMP-Coral annual report.
load('data/primary/CoralDateRanges.RData')
maxYear=year(CoralDateRanges$max)

## ---- Get_gbr
gbr.sf <- sf::read_sf('../../GIS/Great Barrier Reef Marine Park Boundary/Great_Barrier_Reef_Marine_Park_Boundary.shp')
#gbr.sf <- sf::read_sf('X:/Reports/GIS/Great Barrier Reef Marine Park Boundary/Great_Barrier_Reef_Marine_Park_Boundary.shp')
#gbr.sf  #GDA94

qld.sf <- sf::read_sf('../../GIS/Features/Great_Barrier_Reef_Features.shp') %>%
  #qld.sf <- sf::read_sf('X:/reports/GIS/Features/Great_Barrier_Reef_Features.shp') %>%
  filter(FEAT_NAME %in% c("Mainland","Island"))
#qld.sf  #GDA94

full.area = qld.sf %>% 
  st_union(gbr.sf) #%>%
   #st_transform(7844) #GDA2020
 
nrm.sf <- sf::read_sf('../../GIS/Marine Regions/NRM_MarineRegions.shp') 
#nrm.sf <- sf::read_sf('X:/reports/GIS/Marine Regions/NRM_MarineRegions.shp') 
nrm <- nrm.sf %>% 
  st_intersection(gbr.sf) %>% # cut the land section out
  st_transform(st_crs(4283))

wt.nrm<-nrm %>% filter(NAME=="Wet Tropics")
b.nrm<-nrm %>% filter(NAME=="Burdekin")
wh.nrm<-nrm %>% filter(NAME=="Mackay Whitsunday")
fit.nrm<-nrm %>% filter(NAME=="Fitzroy")
bm.nrm<-nrm %>% filter(NAME=="Burnett Mary")

offset.lat<-2
# offset set of nrm sf objects
wt.nrm.1 <- st_set_geometry(wt.nrm, st_geometry(wt.nrm) + c(offset.lat, 0)) %>%
  st_set_crs(4283)
wt.nrm.2 <- st_set_geometry(wt.nrm, st_geometry(wt.nrm) + c(offset.lat*2, 0)) %>%
  st_set_crs(4283)
wt.nrm.3 <- st_set_geometry(wt.nrm, st_geometry(wt.nrm) + c(offset.lat*3, 0)) %>%
  st_set_crs(4283)
wt.nrm.4 <- st_set_geometry(wt.nrm, st_geometry(wt.nrm) + c(offset.lat*4, 0)) %>%
  st_set_crs(4283)
wt.nrm.5 <- st_set_geometry(wt.nrm, st_geometry(wt.nrm) + c(offset.lat*5, 0)) %>%
  st_set_crs(4283)

offset.b.lat<-4
# offset set of nrm sf objects
b.nrm.1 <- st_set_geometry(b.nrm, st_geometry(b.nrm) + c(offset.b.lat, 0)) %>%
  st_set_crs(4283)
b.nrm.2 <- st_set_geometry(b.nrm, st_geometry(b.nrm) + c(offset.b.lat*2, 0)) %>%
  st_set_crs(4283)
b.nrm.3 <- st_set_geometry(b.nrm, st_geometry(b.nrm) + c(offset.b.lat*3, 0)) %>%
  st_set_crs(4283)
b.nrm.4 <- st_set_geometry(b.nrm, st_geometry(b.nrm) + c(offset.b.lat*4, 0)) %>%
  st_set_crs(4283)

offset.wh.lat<-3.5
# offset set of nrm sf objects
wh.nrm.1 <- st_set_geometry(wh.nrm, st_geometry(wh.nrm) + c(offset.wh.lat, 0)) %>%
  st_set_crs(4283)
wh.nrm.2 <- st_set_geometry(wh.nrm, st_geometry(wh.nrm) + c(offset.wh.lat*2, 0)) %>%
  st_set_crs(4283)
wh.nrm.3 <- st_set_geometry(wh.nrm, st_geometry(wh.nrm) + c(offset.wh.lat*3, 0)) %>%
  st_set_crs(4283)
wh.nrm.4 <- st_set_geometry(wh.nrm, st_geometry(wh.nrm) + c(offset.wh.lat*4, 0)) %>%
  st_set_crs(4283)

offset.fit.lat<-3.5
# offset set of nrm sf objects
fit.nrm.1 <- st_set_geometry(fit.nrm, st_geometry(fit.nrm) + c(offset.fit.lat, 0)) %>%
  st_set_crs(4283)
fit.nrm.2 <- st_set_geometry(fit.nrm, st_geometry(fit.nrm) + c(offset.fit.lat*2, 0)) %>%
  st_set_crs(4283)
fit.nrm.3 <- st_set_geometry(fit.nrm, st_geometry(fit.nrm) + c(offset.fit.lat*3, 0)) %>%
  st_set_crs(4283)
fit.nrm.4 <- st_set_geometry(fit.nrm, st_geometry(fit.nrm) + c(offset.fit.lat*4, 0)) %>%
  st_set_crs(4283)

offset.bm.lat<-3.5
# offset set of nrm sf objects
bm.nrm.1 <- st_set_geometry(bm.nrm, st_geometry(bm.nrm) + c(offset.bm.lat, 0)) %>%
  st_set_crs(4283)
bm.nrm.2 <- st_set_geometry(bm.nrm, st_geometry(bm.nrm) + c(offset.bm.lat*2, 0)) %>%
  st_set_crs(4283)
bm.nrm.3 <- st_set_geometry(bm.nrm, st_geometry(bm.nrm) + c(offset.bm.lat*3, 0)) %>%
  st_set_crs(4283)
bm.nrm.4 <- st_set_geometry(bm.nrm, st_geometry(bm.nrm) + c(offset.bm.lat*4, 0)) %>%
  st_set_crs(4283)

#towns of interest
cairns.sf = data.frame(Town=c('Cairns'),Latitude=-16.93598,Longitude=145.7402) %>%
  st_as_sf(coords=c('Longitude','Latitude'),crs='+proj=longlat +ellps=WGS84 +no_defs') %>%
  st_transform(crs=4283) #GDA94
townsville.sf= data.frame(Town=c('Townsville'),Latitude=-19.25825,Longitude=146.7809)%>%
  st_as_sf(coords=c('Longitude','Latitude'),crs='+proj=longlat +ellps=WGS84 +no_defs') %>%
  st_transform(crs=4283) 
mackay.sf = data.frame(Town=c('Mackay'),Latitude=-21.15226,Longitude=149.1121) %>%
    st_as_sf(coords=c('Longitude','Latitude'),crs='+proj=longlat +ellps=WGS84 +no_defs') %>%
    st_transform(crs=4283) 
rockhampton.sf = data.frame(Town=c('Rockhampton'),Latitude=-23.379,Longitude=150.51) %>%
  st_as_sf(coords=c('Longitude','Latitude'),crs='+proj=longlat +ellps=WGS84 +no_defs') %>%
  st_transform(crs=4283) 
gladstone.sf = data.frame(Town=c('Gladstone'),Latitude=-23.81,Longitude=151.254) %>%
  st_as_sf(coords=c('Longitude','Latitude'),crs='+proj=longlat +ellps=WGS84 +no_defs') %>%
  st_transform(crs=4283) 


#set a bounding box for cropping to each region
wet.bbox<- st_bbox(c(xmin=143, ymin=-19,xmax=147.4,ymax=-15), crs=4283) 
b.bbox<- st_bbox(c(xmin=144, ymin=-20.5,xmax=150,ymax=-17.55), crs=4283) 
wh.bbox<- st_bbox(c(xmin=147.5, ymin=-22.5,xmax=151.5,ymax=-18.9), crs=4283) 


wt.crop<- qld.sf %>% st_crop(st_bbox(c(xmin=143, ymin=-19,xmax=147.4,ymax=-15), crs=4283))
b.crop<- qld.sf %>% st_crop(st_bbox(c(xmin=144, ymin=-20.5,xmax=150,ymax=-17.55), crs=4283))
wh.crop<- qld.sf %>% st_crop(st_bbox(c(xmin=147.6, ymin=-22.5,xmax=151.5,ymax=-18.9), crs=4283))

#####------ DHD data

library(stars)
library(ncmeta)

#just current year to get crs for plotting, nice axis lables..
dhd.current=read_ncdf(paste ('../../GIS/DHDnetCDF/dhd', maxYear, '.nc', sep="")) %>%
# dhd.current=read_ncdf(paste ('X:/Reports/GIS/DHDnetCDF/dhd', maxYear, '.nc', sep="")) %>%
  st_set_crs(4326) %>%  #WGS84
  st_transform(4283) #GDA94

  

dhd_cols<-c("#6B9E56", "#9EC08A","#D1E2BE","#FFFFCC","#FFFF00","#FFE900","#FFBF00", "#FF8A00","#FF5F00", "#FF0900",
            "#EB0000","#B30000","#890000","#4C0000","#390000","#130000","#000000")

dhd.wet=NULL
for (year in seq((maxYear-4),maxYear,1))
{
  dhd.x=read_ncdf(paste ('../../GIS/DHDnetCDF/dhd', year, '.nc', sep="")) %>%
    # dhd.x=read_ncdf(paste ('X:/Reports/GIS/DHDnetCDF/dhd', year, '.nc', sep="")) %>%
    st_set_crs(4326) %>% 
    st_transform(4283) %>%
    st_crop(wet.bbox) %>% # crop to wet tropics
   
    .[gbr.sf] %>% # mask to just the gbr
    as_tibble()  %>%
    filter(!is.na(dhd_mosaic_imos)) %>%
    mutate(dhd=as.vector(dhd_mosaic_imos),
           Year=year(time)) 
  dhd.wet<-rbind(dhd.wet,dhd.x)
}

dhd1<-dhd.wet%>% filter(!is.na(dhd)) %>%
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
                                                                                                                                     ifelse(dhd<160,16,17))))))))))))))))),
         lon=ifelse(Year==maxYear,lon,
                     ifelse(Year==maxYear-1, lon+2,
                            ifelse(Year==maxYear-2, lon+4,
                                   ifelse(Year==maxYear-3, lon+6, lon+8)))))


#plot away
dhd5<-ggplot()+
  geom_tile(data=dhd1, aes(y=lat, x=lon, fill=dhd_cat))+ #could use geom_raster if missing data
 # geom_sf(data=qld.crop, fill='#c6c6c6') +
  geom_sf(data=wt.crop, fill='#c6c6c6')+
  geom_sf(data=cairns.sf) +
  geom_sf_text(data=cairns.sf, aes(label=Town), size=4, hjust=1.1) +
  geom_sf(data=wt.nrm, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=wt.nrm.1, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=wt.nrm.2, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=wt.nrm.3, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=wt.nrm.4, fill=NA, show.legend = FALSE, size=1) +
  coord_sf(crs=st_crs(dhd.current), expand=FALSE)+ #provides projection to be used by sf objects
  scale_fill_manual(values = dhd_cols, 
                    labels=c("<10","<20","<30","<40","<50","<60","<70","<80","<90","<100","<110","<120","<130","<140","<150","<160","160+"),
                    name="Degree Heating Days")+
  scale_x_discrete(breaks=c(144,145,146,147), position="bottom")+
  
  theme(panel.border = element_blank(),
        panel.grid=element_blank(),
        axis.title=element_blank())+
  ylim(-19.2,-14.7)+
 annotate("text", x=c(145.75,147.75,149.75,151.75,153.75), y=-14.85, label=c(maxYear,maxYear-1,maxYear-2,maxYear-3,maxYear-4))
 #annotate("text", x=145, y=-11, label=maxYear)
 
ggsave(filename='output/figures/dhd_wt_5years.png',dhd5, width=9,height=5.5)

## Burdekin DHD


dhd.b=NULL
for (year in seq((maxYear-4),maxYear,1))
{
  dhd.x=read_ncdf(paste ('../../GIS/DHDnetCDF/dhd', year, '.nc', sep="")) %>%
    # dhd.x=read_ncdf(paste ('X:/Reports/GIS/DHDnetCDF/dhd', year, '.nc', sep="")) %>%
    st_set_crs(4326) %>% 
    st_transform(4283) %>%
    st_crop(b.bbox) %>% # crop to b tropics
    
    .[gbr.sf] %>% # mask to just the gbr
    as_tibble()  %>%
    filter(!is.na(dhd_mosaic_imos)) %>%
    mutate(dhd=as.vector(dhd_mosaic_imos),
           Year=year(time)) 
  dhd.b<-rbind(dhd.b,dhd.x)
}

dhd1<-dhd.b%>% filter(!is.na(dhd)) %>%
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
                                                                                                                                 ifelse(dhd<160,16,17))))))))))))))))),
         lon=ifelse(Year==maxYear,lon,
                    ifelse(Year==maxYear-1, lon+4,
                           ifelse(Year==maxYear-2, lon+8,
                                  ifelse(Year==maxYear-3, lon+12, lon+16)))))


#plot away
dhd.b5<-ggplot()+
  geom_tile(data=dhd1 , aes(y=lat, x=lon, fill=dhd_cat))+ #could use geom_raster if missing data
  geom_sf(data=b.crop, fill='#c6c6c6')+
  geom_sf(data=townsville.sf) +
  geom_sf_text(data=townsville.sf, aes(label=Town), size=4, hjust=1.1) +
  geom_sf(data=b.nrm, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=b.nrm.1, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=b.nrm.2, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=b.nrm.3, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=b.nrm.4, fill=NA, show.legend = FALSE, size=1) +
  coord_sf(crs=st_crs(dhd.current), expand=FALSE)+ #provides projection to be used by sf objects
  scale_fill_manual(values = dhd_cols, 
                    labels=c("<10","<20","<30","<40","<50","<60","<70","<80","<90","<100","<110","<120","<130","<140","<150","<160","160+"),
                    name="Degree Heating Days")+
  scale_x_discrete(breaks=c(146,148,150), position="bottom")+
  
  theme(panel.border = element_blank(),
        panel.grid=element_blank(),
        axis.title=element_blank(),
        legend.position = "bottom")+
  
  ylim(-20.7,-17.2)+
  annotate("text", x=c(146.4,150.4,154.4,158.4,162.4), y=-17.35, label=c(maxYear,maxYear-1,maxYear-2,maxYear-3,maxYear-4))
#annotate("text", x=145, y=-11, label=maxYear)

ggsave(filename='output/figures/dhd_b_5years.png',dhd.b5, width=9,height=5.5)

## Whit DHD
dhd.wh=NULL
for (year in seq((maxYear-4),maxYear,1))
{
  dhd.x=read_ncdf(paste ('../../GIS/DHDnetCDF/dhd', year, '.nc', sep="")) %>%
    # dhd.x=read_ncdf(paste ('X:/Reports/GIS/DHDnetCDF/dhd', year, '.nc', sep="")) %>%
    st_set_crs(4326) %>%
    st_transform(4283) %>%
    st_crop(wh.bbox) %>% # crop to wet tropics
    
    .[gbr.sf] %>% # mask to just the gbr
    as_tibble()  %>%
    filter(!is.na(dhd_mosaic_imos)) %>%
    mutate(dhd=as.vector(dhd_mosaic_imos),
           Year=year(time)) 
  dhd.wh<-rbind(dhd.wh,dhd.x)
}

dhd3<-dhd.wh%>% filter(!is.na(dhd)) %>%
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
                                                                                                                                 ifelse(dhd<160,16,17))))))))))))))))),
         lon=ifelse(Year==maxYear,lon,
                    ifelse(Year==maxYear-1, lon+3.5,
                           ifelse(Year==maxYear-2, lon+7,
                                  ifelse(Year==maxYear-3, lon+10.5, lon+14)))))


#plot away
dhdWH<-ggplot()+
  geom_tile(data=dhd3, aes(y=lat, x=lon, fill=dhd_cat))+ #could use geom_raster if missing data
  geom_sf(data=wh.crop, fill='#c6c6c6')+
  geom_sf(data=mackay.sf) +
  geom_sf_text(data=mackay.sf, aes(label=Town), size=4, hjust=1.1) +
  geom_sf(data=wh.nrm, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=wh.nrm.1, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=wh.nrm.2, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=wh.nrm.3, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=wh.nrm.4, fill=NA, show.legend = FALSE, size=1) +
  coord_sf(crs=st_crs(dhd.current), expand=FALSE)+ #provides projection to be used by sf objects
  scale_fill_manual(values = dhd_cols, 
                    labels=c("<10","<20","<30","<40","<50","<60","<70","<80","<90","<100","<110","<120","<130","<140","<150","<160","160+"),
                    name="Degree Heating Days")+
  scale_x_discrete(breaks=c(148,150), position="bottom")+
  theme(panel.border = element_blank(),
        panel.grid=element_blank(),
        axis.title=element_blank(),
        legend.position = 'bottom')+
  guides(fill=guide_legend(nrow=2,byrow=TRUE))+
  ylim(-22.7,-18.6)+
  annotate("text", x=c(148.5,152,155.5,159,161.5), y=-18.75, label=c(maxYear,maxYear-1,maxYear-2,maxYear-3,maxYear-4))
  
#annotate("text", x=145, y=-11, label=maxYear)

ggsave(filename='output/figures/dhd_wh_5years.png',dhdWH, width=9,height=5.5)


######### DHW 

load( file='../../GIS/DHW_GBR/dhw.dat.RData')


# colour pal
  dhw.col<- c("200 250 250", "70 50 120", "100 80 150",
              "130 110 180", "160 140 210", "255 255 0",
              "255 220 0", "255 185 0", "255 150 0",
              "255 0 0", "210 0 0", "160 0 0",
              "110 0 0", "230 125 70",  "180 90 40", 
              "125 60 30",  "85 45 20", "240 0 240", 
              "200 0 200", "160 0 160", "120 0 120", "50 0 50")  

dhw_cols<-colourvalues::convert_colours( 
  matrix(as.numeric( unlist( strsplit(dhw.col, " ") ) ) , ncol = 3, byrow = T)
)
 dhw.lab= c("0","<1","<2","<3","<4","<5","<6","<7","<8","<9","<10","<11","<12","<13","<14","<15","<16","<17","<18","<19","<20","20+")
 
#Wet Tropics
 
 wt.dhw<- dhw.dat %>% 
   filter(lon>=143 & lat>=-19 & lon<=147.4 & lat<=-15) %>%
   #fliter(Year>maxYear-5)
   filter(Year>maxYear-6)

 
dhw1<-wt.dhw %>% filter(!is.na(dhw)) %>%
  mutate(dhw_cat=factor(ifelse(dhw==0,0,
                             ifelse(dhw<1,1,
                               ifelse(dhw<2,2,
                                ifelse(dhw<3,3,
                                 ifelse(dhw<4,4,
                                  ifelse(dhw<5,5,
                                   ifelse(dhw<6,6,
                                    ifelse(dhw<7,7,
                                      ifelse(dhw<8,8,
                                        ifelse(dhw<9,9,
                                          ifelse(dhw<10,10,
                                           ifelse(dhw<11,11,
                                            ifelse(dhw<12,12,
                                             ifelse(dhw<13,13,
                                              ifelse(dhw<14,14,
                                               ifelse(dhw<15,15,
                                                ifelse(dhw<16,16,
                                                 ifelse(dhw<17,17,
                                                  ifelse(dhw<18,18,
                                                   ifelse(dhw<19,19,
                                                    ifelse(dhw<20,20,21)))))))))))))))))))))),
         
lon=ifelse(Year==maxYear,lon,
           ifelse(Year==maxYear-1, lon+2,
                  ifelse(Year==maxYear-2, lon+4,
                         ifelse(Year==maxYear-3, lon+6, 
                                ifelse(Year==maxYear-4, lon+8, lon+10))))))
                         #ifelse(Year==maxYear-3, lon+6, lon+8)))))


#plot away
dhw5<-ggplot()+
  geom_tile(data=dhw1, aes(y=lat, x=lon, fill=dhw_cat))+ #could use geom_raster if missing data
  geom_sf(data=wt.crop, fill='#c6c6c6') +
  geom_sf(data=cairns.sf) +
  geom_sf_text(data=cairns.sf, aes(label=Town), size=4, hjust=1.1) +
  geom_sf(data=wt.nrm, fill=NA, show.legend = FALSE) +
  geom_sf(data=wt.nrm.1, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=wt.nrm.2, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=wt.nrm.3, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=wt.nrm.4, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=wt.nrm.5, fill=NA, show.legend = FALSE, size=1) +
  coord_sf(crs=st_crs(wt.nrm), expand=FALSE)+ #provides projection to be used by sf objects
  scale_fill_manual(values = dhw_cols, 
                    labels=dhw.lab,
                    name="Degree Heating weeks")+
  #scale_x_discrete(breaks=c(145,147), position="bottom")+
  
  theme(panel.border = element_blank(),
        panel.grid=element_blank(),
        axis.title=element_blank(),
        legend.position = "bottom",
        axis.text.x=element_blank())+
  guides(fill=guide_legend(nrow=2,byrow=TRUE))+
  ylim(-19.2,-14.65)+
  #annotate("text", x=c(145.75,147.75,149.75,151.75,153.75), y=-14.85, label=c(maxYear,maxYear-1,maxYear-2,maxYear-3,maxYear-4))
annotate("text", x=c(145.75,147.75,149.75,151.75,153.75, 155.75), y=-14.8, label=c(maxYear,maxYear-1,maxYear-2,maxYear-3,maxYear-4,maxYear-5))


ggsave(filename='output/figures/wt_dhw_6years.png',dhw5, width=11, height=5.5)


#Dry Tropics
b.dhw<- dhw.dat %>% filter(lon>=144 & lat>=-20.5 & lon<=150 & lat<=-17.55)

#wh.dhw<- dhw.dat %>% filter(lon>=147.5 & lat>=-22.5 & lon<=151.5 & lat<=-18.9)


dhw.b1<-b.dhw %>% filter(!is.na(dhw)) %>%
  mutate(dhw_cat=factor(ifelse(dhw==0,0,
                               ifelse(dhw<1,1,
                                      ifelse(dhw<2,2,
                                             ifelse(dhw<3,3,
                                                    ifelse(dhw<4,4,
                                                           ifelse(dhw<5,5,
                                                                  ifelse(dhw<6,6,
                                                                         ifelse(dhw<7,7,
                                                                                ifelse(dhw<8,8,
                                                                                       ifelse(dhw<9,9,
                                                                                              ifelse(dhw<10,10,
                                                                                                     ifelse(dhw<11,11,
                                                                                                            ifelse(dhw<12,12,
                                                                                                                   ifelse(dhw<13,13,
                                                                                                                          ifelse(dhw<14,14,
                                                                                                                                 ifelse(dhw<15,15,
                                                                                                                                        ifelse(dhw<16,16,
                                                                                                                                               ifelse(dhw<17,17,
                                                                                                                                                      ifelse(dhw<18,18,
                                                                                                                                                             ifelse(dhw<19,19,
                                                                                                                                                                    ifelse(dhw<20,20,21)))))))))))))))))))))),
         
         lon=ifelse(Year==maxYear,lon,
                    ifelse(Year==maxYear-1, lon+4,
                           ifelse(Year==maxYear-2, lon+8,
                                  ifelse(Year==maxYear-3, lon+12, lon+16)))))

#plot away
dhw.b5<-ggplot()+
  geom_tile(data=dhw.b1, aes(y=lat, x=lon, fill=dhw_cat))+ #could use geom_raster if missing data
  geom_sf(data=b.crop, fill='#c6c6c6') +
  geom_sf(data=townsville.sf) +
  geom_sf_text(data=townsville.sf, aes(label=Town), size=4, hjust=1.1) +
  geom_sf(data=b.nrm, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=b.nrm.1, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=b.nrm.2, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=b.nrm.3, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=b.nrm.4, fill=NA, show.legend = FALSE, size=1) +
  coord_sf(crs=st_crs(b.nrm), expand=FALSE)+ #provides projection to be used by sf objects
  scale_fill_manual(values = dhw_cols, 
                    labels=dhw.lab,
                    name="Degree Heating weeks")+
  scale_x_discrete(breaks=c(146,148,150), position="bottom")+
  
  theme(panel.border = element_blank(),
        panel.grid=element_blank(),
        axis.title=element_blank(),
        legend.position = "bottom")+
  ylim(-20.7,-17.2)+
  annotate("text", x=c(146.4,150.4,154.4,158.4,162.4), y=-17.35, label=c(maxYear,maxYear-1,maxYear-2,maxYear-3,maxYear-4))


ggsave(filename='output/figures/b_dhw_5years.png',dhw.b5, width=9, height=5.5)

#Mackay Whitsundays

wh.dhw<- dhw.dat %>% filter(lon>=147.5 & lat>=-22.5 & lon<=151.5 & lat<=-18.9)


dhw.wh1<-wh.dhw %>% filter(!is.na(dhw)) %>%
  mutate(dhw_cat=factor(ifelse(dhw==0,0,
                               ifelse(dhw<1,1,
                                      ifelse(dhw<2,2,
                                             ifelse(dhw<3,3,
                                                    ifelse(dhw<4,4,
                                                           ifelse(dhw<5,5,
                                                                  ifelse(dhw<6,6,
                                                                         ifelse(dhw<7,7,
                                                                                ifelse(dhw<8,8,
                                                                                       ifelse(dhw<9,9,
                                                                                              ifelse(dhw<10,10,
                                                                                                     ifelse(dhw<11,11,
                                                                                                            ifelse(dhw<12,12,
                                                                                                                   ifelse(dhw<13,13,
                                                                                                                          ifelse(dhw<14,14,
                                                                                                                                 ifelse(dhw<15,15,
                                                                                                                                        ifelse(dhw<16,16,
                                                                                                                                               ifelse(dhw<17,17,
                                                                                                                                                      ifelse(dhw<18,18,
                                                                                                                                                             ifelse(dhw<19,19,
                                                                                                                                                                    ifelse(dhw<20,20,21)))))))))))))))))))))),
         
         lon=ifelse(Year==maxYear,lon,
                    ifelse(Year==maxYear-1, lon+3.5,
                           ifelse(Year==maxYear-2, lon+7,
                                  ifelse(Year==maxYear-3, lon+10.5, lon+14)))))

#plot away
dhw.wh5<-ggplot()+
  geom_tile(data=dhw.wh1, aes(y=lat, x=lon, fill=dhw_cat))+ #could use geom_raster if missing data
  geom_sf(data=wh.crop, fill='#c6c6c6') +
  geom_sf(data=mackay.sf) +
  geom_sf_text(data=mackay.sf, aes(label=Town), size=4, hjust=1.1) +
  geom_sf(data=wh.nrm, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=wh.nrm.1, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=wh.nrm.2, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=wh.nrm.3, fill=NA, show.legend = FALSE, size=1) +
  geom_sf(data=wh.nrm.4, fill=NA, show.legend = FALSE, size=1) +
  coord_sf(crs=st_crs(wh.nrm), expand=FALSE)+ #provides projection to be used by sf objects
  scale_fill_manual(values = dhw_cols, 
                    labels=dhw.lab,
                    name="Degree Heating weeks")+
  scale_x_discrete(breaks=c(148,150), position="bottom")+
  theme(panel.border = element_blank(),
        panel.grid=element_blank(),
        axis.title=element_blank(),
        legend.position = 'bottom')+
  guides(fill=guide_legend(nrow=2,byrow=TRUE))+
  ylim(-22.7,-18.6)+
  annotate("text", x=c(148.5,152,155.5,159,162.5), y=-18.75, label=c(maxYear,maxYear-1,maxYear-2,maxYear-3,maxYear-4))



ggsave(filename='output/figures/wh_dhw_5years.png',dhw.wh5, width=9, height=5.5)

#Mackay Whitsundays - new categories
#### DHW colours as per categories and colour blind friendly brewer
# dhw_cols<-c("#2C7BB6", "#ABD9E9","#FFFFBF","#FDAE61","#D7191C")
# dhw.lab= c("Bleaching low risk = 0 - 2 DHW",
#            "Bleaching warning = 2 - 4 DHW",
#            "Bleaching possible = 4 - 6 DHW",
#            "Bleaching probable = 6 - 8 DHW",
#            "Severe bleaching >8 DHW")
# wh.dhw<- dhw.dat %>% filter(lon>=147.5 & lat>=-22.5 & lon<=151.5 & lat<=-18.9)
# 
# 
# dhw.wh1<-wh.dhw %>% filter(!is.na(dhw)) %>%
# mutate(dhw_cat=factor(ifelse(dhw<2,1,
#                              ifelse(dhw<4,2,
#                                     ifelse(dhw<6,3,
#                                            ifelse(dhw<8,4,5))))),
# lon=ifelse(Year==maxYear,lon,
#            ifelse(Year==maxYear-1, lon+3.5,
#                   ifelse(Year==maxYear-2, lon+7,
#                          ifelse(Year==maxYear-3, lon+10.5, lon+14)))))
# #plot away
# dhw.wh5<-ggplot()+
#   geom_tile(data=dhw.wh1, aes(y=lat, x=lon, fill=dhw_cat))+ #could use geom_raster if missing data
#   geom_sf(data=wh.crop, fill='#c6c6c6') +
#   geom_sf(data=mackay.sf) +
#   geom_sf_text(data=mackay.sf, aes(label=Town), size=4, hjust=1.1) +
#   geom_sf(data=wh.nrm, fill=NA, show.legend = FALSE, size=1) +
#   geom_sf(data=wh.nrm.1, fill=NA, show.legend = FALSE, size=1) +
#   geom_sf(data=wh.nrm.2, fill=NA, show.legend = FALSE, size=1) +
#   geom_sf(data=wh.nrm.3, fill=NA, show.legend = FALSE, size=1) +
#   geom_sf(data=wh.nrm.4, fill=NA, show.legend = FALSE, size=1) +
#   coord_sf(crs=st_crs(wh.nrm), expand=FALSE)+ #provides projection to be used by sf objects
#   scale_fill_manual(values = dhw_cols, 
#                     labels=dhw.lab,
#                     name="Thermal Stress")+
#   scale_x_discrete(breaks=c(148,150), position="bottom")+
#   theme(panel.border = element_blank(),
#         panel.grid=element_blank(),
#         axis.title=element_blank(),
#         legend.position = 'bottom')+
#   guides(fill=guide_legend(nrow=2,byrow=TRUE))+
#   ylim(-22.7,-18.6)+
#   annotate("text", x=c(148.5,152,155.5,159,162.5), y=-18.75, label=c(maxYear,maxYear-1,maxYear-2,maxYear-3,maxYear-4))
# 


#Southern
southern.bbox<-c(xmin=149.5, ymin=-24.5,xmax=152.5,ymax=-22.8)  
south.dhw<- dhw.dat %>% filter(lon>=150 & lat>=-24.5 & lon<=152.5 & lat<=-22.8)
southern.qld<-qld.sf %>% st_crop(southern.bbox) 
southern.islands=southern.qld %>%
  filter(FEAT_NAME=="Island")
southern.coast<-qld.sf %>%
  filter(FEAT_NAME=="Mainland") %>%
  st_cast('MULTILINESTRING') %>%
  st_crop(southern.bbox)
 


dhw.s1<-south.dhw %>% filter(!is.na(dhw)) %>%
  mutate(dhw_cat=factor(ifelse(dhw==0,0,
                               ifelse(dhw<1,1,
                                      ifelse(dhw<2,2,
                                             ifelse(dhw<3,3,
                                                    ifelse(dhw<4,4,
                                                           ifelse(dhw<5,5,
                                                                  ifelse(dhw<6,6,
                                                                         ifelse(dhw<7,7,
                                                                                ifelse(dhw<8,8,
                                                                                       ifelse(dhw<9,9,
                                                                                              ifelse(dhw<10,10,
                                                                                                     ifelse(dhw<11,11,
                                                                                                            ifelse(dhw<12,12,
                                                                                                                   ifelse(dhw<13,13,
                                                                                                                          ifelse(dhw<14,14,
                                                                                                                                 ifelse(dhw<15,15,
                                                                                                                                        ifelse(dhw<16,16,
                                                                                                                                               ifelse(dhw<17,17,
                                                                                                                                                      ifelse(dhw<18,18,
                                                                                                                                                             ifelse(dhw<19,19,
                                                                                                                                                                    ifelse(dhw<20,20,21)))))))))))))))))))))),
         
         lon=ifelse(Year==maxYear,lon,
                    ifelse(Year==maxYear-1, lon+2.2,
                           ifelse(Year==maxYear-2, lon+4.4,
                                  ifelse(Year==maxYear-3, lon+6.6, lon+8.8)))))

#plot away
dhw.s5<-ggplot()+
  geom_tile(data=dhw.s1, aes(y=lat, x=lon, fill=dhw_cat))+ #could use geom_raster if missing data
  geom_sf(data=southern.qld, fill='#c6c6c6') +
  geom_sf(data=st_set_crs(st_geometry(southern.coast) + c(2.2,0), st_crs(southern.qld))) +
  geom_sf(data=st_set_crs(st_geometry(southern.islands) + c(2.2,0), st_crs(southern.qld))) +
  geom_sf(data=st_set_crs(st_geometry(southern.coast) + c(4.4,0), st_crs(southern.qld))) +
  geom_sf(data=st_set_crs(st_geometry(southern.islands) + c(4.4,0), st_crs(southern.qld))) +
  geom_sf(data=st_set_crs(st_geometry(southern.coast) + c(6.6,0), st_crs(southern.qld))) +
  geom_sf(data=st_set_crs(st_geometry(southern.islands) + c(6.6,0), st_crs(southern.qld))) +
  geom_sf(data=st_set_crs(st_geometry(southern.coast) + c(8.8,0), st_crs(southern.qld))) +
  geom_sf(data=st_set_crs(st_geometry(southern.islands) + c(8.8,0), st_crs(southern.qld))) +
  geom_sf(data=rockhampton.sf) +
  geom_sf_text(data=rockhampton.sf, aes(label=Town), size=3.5, hjust=0.85, vjust=-0.9) +
  geom_sf(data=gladstone.sf) +
  geom_sf_text(data=gladstone.sf, aes(label=Town), size=3.5, hjust=1.1) +
  coord_sf(crs=st_crs(southern.qld), expand=FALSE)+ #provides projection to be used by sf objects
  scale_fill_manual(values = dhw_cols, 
                    labels=dhw.lab,
                    name="Degree Heating weeks")+
  scale_x_discrete(breaks=c(150,152), position="bottom")+
  theme(panel.border = element_blank(),
        panel.grid=element_blank(),
        axis.title=element_blank(),
        legend.position = 'bottom')+
  ylim(-25,-22.2)+
  annotate("text", x=c(151.5,153.7,155.9,158.1,160.3), y=-22.6, label=c(maxYear,maxYear-1,maxYear-2,maxYear-3,maxYear-4))



ggsave(filename='output/figures/gladstone_dhw_5years.png',dhw.s5, width=9, height=5.5)
