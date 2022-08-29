#This script will be used to extract annual rainfall data for a) Australia, and
#b) any other region required by the Northern Three
#This script is currently in progress
#-----------------------------------------------------------------------------
#Created: 20/06/2022
#Author: Adam Shand
#Updated: 30/07/2022
#-------------------------------------------------------------------------------

#This is a difficult script to run as it requires a package that is not up to 
#date on CRAN. Instead it must be downloaded from the github repository. A 
#mostly reliable method is as follows:

#Install the "remotes" package (no need to load it as we only use one function 
#from the package and can just call it specifically.
install.packages("remotes")

#download and install Rtools. Note Rtools is not an R package and must be 
#downloaded externally to R. Google Rtools and follow the prompts.

#use remotes to install the rayshader package from github
remotes::install_github("tylermorganwall/rayshader")

#install and load all other packages as normal (i.e. from CRAN)
#Load required packages.
library(ncdf4) #Y
library(raster) #Y
library(sf) #Y
library(rayshader) #Y
library(RColorBrewer) #Y
library(tmap) #Y
library(stringr)#Y
library(dplyr) #Y
library(tidyr) #M

#these packages might be useful in the future
#library(rasterVis)
#library(rgdal)
#library(ggplot2)
#library(chron)

#-------------------------------------------------------------------------------
#load in a custom function for converting coordinates.
#-------------------------------------------------------------------------------

source("src/convert_coords.R")

#-------------------------------------------------------------------------------
#below all works  as intended. Basics of data loading
#-------------------------------------------------------------------------------

#Bring in data as a raster brick to save on processing time
raster_brick <- brick(x = "input/rainfall/monthly_rainfall_abs.nc", varid = "rain_day")

#ensure the correct crs is used.
crs(raster_brick) <- "EPSG:4326"

#create a data frame of layer names. This will be important so we know what 
#layers we should be grabbing.
layer_names_df <- names(raster_brick) %>% 
  data.frame()
  
layer_names_df <- rename(layer_names_df, layer_names = .)

#option 1 to check what layer is what. Inspect or print data frame and scroll.
#option 2 to check what layer is what. Below, ordered as: [row(s),col]
layer_names_df[1:12,1]

#create raster stack from brick, raster stacks are more versatile. Use df above 
#to either: a) figure out the layer numbers you want to grab. or b) to create a
#subset that can then be used to select the desired layers
#option 1. Look up the index of desired layers
rast_stack <- stack(raster_brick, layers = c(1:12))

#option 2. Pick layers by matching name (or partial matching name)
temp <- layer_names_df %>% 
  filter(str_detect(layer_names, "X1911"))

rast_stack1 <- raster::subset(raster_brick, temp$layer_names)

rm(temp)

#option 2a. Pick layers by stating range, such as by finacial year
#split the layer name column into year, month, and day cols
layer_names_df <- layer_names_df %>% 
  separate(col = layer_names, sep = "[.]", remove = FALSE,
           into = c("year", "month", "day"))

#remove X from year, maybe this can be done in dplyr but couldn't figure it out
layer_names_df$year <- sub("X", "", layer_names_df$year)

#create a new col that is the financial year. 
#first convert year, month, day to numeric for the following operation. (Use
#glimpse() for before and after).
#then create two temp columns based on month and year. one if month <= 06 then 
#fyear = year-1, else fyear = year. and one doing the opposite

layer_names_df <- layer_names_df %>% 
  transform(year = as.numeric(year), month = as.numeric(month), 
            day = as.numeric(day)) %>% 
  mutate(fyear_p1 = case_when(month <= 6 ~ year - 1, month > 6 ~ year),
         fyear_p2 = case_when(month <= 6 ~ year, month > 6 ~ year + 1))

#convert the newly created columns to character so we can do the following op.
#combine the columns into one, with a hyphen as a separator
layer_names_df <- layer_names_df %>% 
  transform(fyear_p1 = as.character(fyear_p1),
            fyear_p2 = as.character(fyear_p2)) %>% 
  mutate(fyear = paste( fyear_p1, fyear_p2, sep = "-"), .keep = "unused")

#now we can create a temporary list based off the newly created financial year
temp <- layer_names_df %>% 
  filter(str_detect(fyear, "2020-2021"))

#and use our temp list to subset the main raster brick to get what we want
rast_stack2 <- raster::subset(raster_brick, temp$layer_names)

rm(temp)

#plot to make sure the data is there
plot(rast_stack2)

#check things such as the crs and extent - vital to then be able to add on our
#shapefiles and other overlays later
crs(rast_stack2)
extent(rast_stack2)

#perform calculations on our stack. Most should work as in algebraic expressions
mean_rast <- mean(rast_stack2)

#plot the new raster layer
plot(mean_rast)

#and little extra spice on top.
animate(rast_stack, n = 1)
dev.off()

#-------------------------------------------------------------------------------
#lets bring over our shapefiles that we use in the elevation script. Note that 
#this works with everything tried so far - particularly even the EPP layers
#-------------------------------------------------------------------------------

#we can read in shapefiles as we have in the elevation script. source: https://data.gov.au/dataset/ds-dga-2dbbec1a-99a2-4ee5-8806-53bc41d038a7/details?q=
state_border <- st_read(dsn = "input/shapefiles",
                        layer = "qld_polygon")

#set the crs to our desired crs
state_border <- st_transform(state_border, crs = crs(raster_brick))

#example of different crop, for instance
dry_tropics_full <- c(-19.8145, -17.1727, 145.4625, 148.2558)
lat_range = c(dry_tropics_full[1],dry_tropics_full[2])
long_range = c(dry_tropics_full[3],dry_tropics_full[4])
location_extent <- extent(convert_coords(lat = lat_range, long = long_range,
                                         to = crs(raster_brick)))

#get basin outlines from the EPP schedule outline
EPP_schedule_outlines <- st_read(dsn = "input/shapefiles",
                                 layer = "EPP_Water_schedule_outlines_Qld")

sf_use_s2(FALSE)

#crop to the desired region to increase processing speeds
EPP_schedule_outlines_crop <- st_crop(EPP_schedule_outlines, location_extent)

#Use this to just get black Ross and Maggie outlines
filtered_schedule <- EPP_schedule_outlines_crop %>% 
  filter(BASIN_NAME %in% c("Black", "Ross")) %>% 
  filter(PROJECT_NA %in% c("Townsville Region"))
#-------------------------------------------------------------------------------
#now we can start to combine and overlay data
#-------------------------------------------------------------------------------

#crop our raster by the extent of dt location (we can also crop by the extent
#of any bounding box or shapefile we choose to make).
crop_mean_rast <- crop(mean_rast, location_extent)

#plot to check
plot(crop_mean_rast)

#example using state border
plot(crop(mean_rast, state_border))

#back to main, it looks a bit blurry, increase the resolution by a factor of 10
crop_mean_rast <- disaggregate(x = crop_mean_rast, fact = 10, method = "bilinear")

#that's better
plot(crop_mean_rast)

#mask the raster by the inverse of the area of our shapefile (i.e. take only 
#what is within the polygon). Use state border to clean up coastline without
#losing any of the data.
mask_mean_rast <- mask(crop_mean_rast, state_border)

#looking good - check the coastlines
plot(mask_mean_rast)

#-------------------------------------------------------------------------------
#now lets try so more advanced plotting methods. As a proof of concept, lets do
#rayshader first up.
#-------------------------------------------------------------------------------

#rayshader likes to have a matrix rather than a raster.
rain_matrix <- raster_to_matrix(mask_mean_rast)

#create the overlay using the height shade func. this gives the most generic
#creation and allows easy colour manipulation
rain_overlay <- height_shade(heightmap = rain_matrix, 
                             texture = rev(brewer.pal(9,"YlGnBu")))

#looks good! this is limited however, for example there are no legends. ------------------------------look into how i can generate legends separately.
plot_map(rain_overlay)

#as a proof of concept, check this out DONT USE THIS RIGHT NOW - CRASHING SESSION
#plot_3d(rain_overlay, rain_matrix, zscale = 10)

#-------------------------------------------------------------------------------
#lets move on to a more realistic mapping option. Tmap works by getting a shape,
#then doing something to the shape
#-------------------------------------------------------------------------------

#set the mapping mode. plot for "normal" use, view for a more interactive use.
tmap_mode("plot")

#map for absolute rainfall, check fig 4 in Mapping the climate: guidance on 
#appropriate techniques to map climate variables and their uncertainty 
#palette also matches AWO BOM scheme
tm_shape(mask_mean_rast) +
  tm_raster(palette = brewer.pal(9, "YlGnBu"), n = 9, style = "cont",
            title = "Mean yearly rainfall (mm) \n (2020-2021)", legend.reverse = TRUE,
            contrast = 0.8) + #e.g. raster, w/ pal + 22 col bands
  tm_shape(filtered_schedule) + #any shapefiles can be added here
  tm_borders(col = "black") + #e.g. only take borders of shape above
  tm_shape(filtered_schedule) +
  tm_text(text = "BASIN_NAME", shadow = T) +
  tm_shape(state_border) +
  tm_borders(col = "black") +
  tm_compass(size = 1.5, position = c("RIGHT", "TOP")) + #uppercase = position without margin, lowercase = position with margin (not as tight)
  tm_scale_bar(position = c("left", "BOTTOM"), width = 0.1) +
  tm_logo(file = "input/dt_logo.png", position = c("LEFT", "TOP"), height = 2) +
  tm_layout(legend.outside = TRUE, legend.outside.position = c("right", "top"), frame = TRUE, bg.color = "grey75") #similar to ggplot - lots of options

#-------------------------------------------------------------------------------
#Lets do the same thing with the relative dataset now. For more detailed
#comments refer to above
#-------------------------------------------------------------------------------

#read the data
rel_rain_fall <- brick(x = "input/rainfall/monthly_rainfall_rel.nc") #------------------------------these values range from 0 - 1, figure out the best way to understand them as they are relative values. Speak to Dinny

#update the crs
crs(rel_rain_fall) <- "EPSG:4326"

#steal the df created previously to make our temp filter
temp <- layer_names_df %>% 
  filter(str_detect(fyear, "2020-2021"))

#filter by temp
rel_stack <- raster::subset(rel_rain_fall, temp$layer_names)

#remove temp df
rm(temp)

#plot to make sure the data is there
plot(rel_stack)

#perform calculations on our stack. Most should work as in algebraic expressions
mean_rel <- mean(rel_stack) #is mean the correct method here?? I dont think so---------------------------------------------ask dinny!

#plot the new raster layer
plot(mean_rel)

dev.off()

#-------------------------------------------------------------------------------
#now we have our data read to go lets start getting ready to plot.
#-------------------------------------------------------------------------------

#crop using bbox
crop_mean_rel <- crop(mean_rel, location_extent)

#increase resolution
crop_mean_rel <- disaggregate(x = crop_mean_rel, fact = 10, method = "bilinear")

#mask by state border
mask_mean_rel <- mask(crop_mean_rel, state_border)

#plot to check
plot(mask_mean_rel)

#-------------------------------------------------------------------------------
#plotting time. Note, currently unsure how to interpret data. Do not use plot
#-------------------------------------------------------------------------------

tmap_mode("plot")

tm_shape(mask_mean_rel) +
  tm_raster(palette = brewer.pal(7, "RdBu"), n = 7, #----------------------------need to set colour gradient from 0-1
            title = "Mean yearly rainfall (mm) \n (2020-2021)", legend.reverse = TRUE,
            contrast = 0.8) + #e.g. raster, w/ pal + 22 col bands
  tm_shape(filtered_schedule) + #any shapefiles can be added here
  tm_borders(col = "black") + #e.g. only take borders of shape above
  tm_shape(filtered_schedule) +
  tm_text(text = "BASIN_NAME", shadow = T) +
  tm_shape(state_border) +
  tm_borders(col = "black") +
  tm_compass(size = 1.5, position = c("RIGHT", "TOP")) + #uppercase = position without margin, lowercase = position with margin (not as tight)
  tm_scale_bar(position = c("left", "BOTTOM"), width = 0.1) +
  tm_logo(file = "input/dt_logo.png", position = c("LEFT", "TOP"), height = 2) +
  tm_layout(legend.outside = TRUE, legend.outside.position = c("right", "top"), frame = TRUE, bg.color = "grey75") #
