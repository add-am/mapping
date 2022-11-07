#This script will be used to create 2D and 3D maps for any other region 
#required by the Northern Three.
#This script is currently in progress
#-----------------------------------------------------------------------------
#Created: 20/06/2022
#Author: Adam Shand
#Updated: 25/08/2022
#-------------------------------------------------------------------------------

#This is a difficult script to run as it requires a package that is not up to 
#date on CRAN. Instead it must be downloaded from the github repository. A 
#mostly reliable method is as follows:

#Install the "remotes" package (no need to load it as we only use one function 
#from the package and can just call it specifically.
#install.packages("remotes")

#download and install Rtools. Note Rtools is not an R package and must be 
#downloaded externally to R. Google Rtools and follow the prompts.

#use remotes to install the rayshader package from github
remotes::install_github("tylermorganwall/rayshader")

#install and load all other packages as normal (i.e. from CRAN)
library(rayshader) #Y
library(raster) #Y
library(sf) #Y
library(osmdata) #Y
library(av) #Y
library(gifski) #Y
library(leaflet) #Y
library(stringr) #Y
library(maptools) #Y
library(rayrender) #Y
library(tidyverse) #Y
library(rgdal) #M
library(tmap)
library(dplyr) #Y


#above packages are used in script. Below packages might be used in future.
library(ambient) #M
library(magick) #M
library(rgdal) #M
library(ggplot2) #M

#----------------------------------------------------------------------------------need to go through and remove any capitalization present - e.g. in the inshore_waters section

#Import elevation data as a raster
#We have a few main options. 
#The GBR 100m data set can be used for quicker processing to determine optimal
#camera angles, zscale, theta, phi, zoom, etc.
#The GBR 30m data set can then be used to render a high res version
#without having to figure out the variables again. Just remember to update zscale
#GBR data is sourced from the Aus Seabed data portal:
#https://portal.ga.gov.au/persona/marine

#-----------------------------------------------------------------------------------Up to here. Run through a low res matrix to practice hq render
#Use raster function to read elevation data as a raster. Take either the 100m
#data set or the 30m data set
gbr <- raster("input/elevation/gbr_100m_2020.tif")
#gbr <- raster("input/elevation/gbr_30m_2020.tif")

#set the project crs. Use the global EPSG:4326 unless specified otherwise
proj_crs <- crs("EPSG:4326")

#set geometry to planar - this is only a temp solution.
sf_use_s2(FALSE)

#update dataset to match project crs.
crs(gbr) <- proj_crs

#Use extent to check we have the whole Great Barrier Reef
extent(gbr)

#if required, use aggregate to group cells and reduce raster size or 
#disaggregate to do the opposite 
#low_res <- aggregate(gbr, 10) #x=data, y=number of cells to combine
#high_res <- disaggregate(gbr, fact = 2, method = "bilinear") #fact = amount to
#disaggregate, use bilinear to interpolate values, or '' to use the same as og.


#Specify the area in which we are working. Easiest way is to obtain coordinates
#from Google maps. Note that the GBR data set is huge and needs to be cropped 
#to process in a reasonable time.
#This is an easy place to store each Partnerships' boundaries
#full boundary: 
dry_tropics_full <- c(-19.8145, -17.1727, 145.4625, 148.2558)
#closeup:
dry_tropics_cu <- c(-19.7095, -18.8700, 146.1625, 147.1008)


#other
Ross <- c(-19.6912, -19.0700, 146.5864, 147.0743)

maggie <- c(-19.1862, -19.0999, 146.7653, 146.8971)
wet_tropics_full <- c(-17.0255, -16.4495, 145.3150, 145.9838)
mwi_full <- c(-21.1833, -19.8456, 148.0714, 149.3335)

#Overlay these onto a leaflet map to get an idea of how big each region is and
#how they overlap one another. These can be adjusted as required. Just pipe
#to repeat as many times as needed
leaflet() %>% 
  addTiles() %>% 
  addRectangles(lng1 = dry_tropics_cu[3], lat1 = dry_tropics_cu[1],
                lng2 = dry_tropics_cu[4], lat2 = dry_tropics_cu[2],
                fillColor = "transparent") %>%
  addRectangles(lng1 = wet_tropics_full[3], lat1 = wet_tropics_full[1],
                lng2 = wet_tropics_full[4], lat2 = wet_tropics_full[2],
                fillColor = "transparent") %>% 
  addRectangles(lng1 = mwi_full[3], lat1 = mwi_full[1],
                lng2 = mwi_full[4], lat2 = mwi_full[2],
                fillColor = "transparent")

#Pick out the boundaries of the region you would like to look at. This is where
#all subsequent lines get their extent/boundary/region from. swap in different
#values here to update everything else.
lat_range = c(wet_tropics_full[1], wet_tropics_full[2])
long_range = c(wet_tropics_full[3], wet_tropics_full[4])

#load a custom function that serves to convert the CRS of the coordinates 
#provided by Google (listed above) into the CRS of the data set (e.g. GBR)
source("convert_coords.R")

#Create bounding box for our chosen region using coords above and CRS from data.
location_extent <- extent(convert_coords(lat = lat_range, 
                                  long = long_range,
                                  to = crs(proj_crs)))
#Visual confirmation
location_extent

#Use crop to cut down the gbr data set to the region specified above. Run extent
#to check the output
gbr_cropped <- raster::crop(gbr, location_extent)
extent(gbr_cropped)

#Convert the raster to a matrix. (matrix are more digestible by rayshader)
gbr_cropped_matrix <- raster_to_matrix(gbr_cropped)

#-------------------------------------------------------------------------------
#Create a 2D base map to check how things look. Each overlay (and the final base
#map) can be saved as variables to lower computing costs further down.

#create simple overlays:
#create a ray shade matrix. zscale affects shadows. Smaller num = bigger shadow
raymat <- ray_shade(heightmap = gbr_cropped_matrix, zscale = 10, lambert = TRUE)
#create an ambient shade matrix. zscale affects shadows as above.
ambmat <- ambient_shade(gbr_cropped_matrix, zscale = 10)
#create a texture map for additional shadows and increased detail.
texturemat <- texture_shade(gbr_cropped_matrix, detail = 1, contrast = 10, 
                            brightness = 10)



#create more complex overlays:
#bathymetry; copy original matrix to new matrix
bathy_matrix <- gbr_cropped_matrix
#cap all matrix values greater than x to NA
bathy_matrix[bathy_matrix > 0.1] = NA
#create a colour palette suitable to the overlay (e.g. blues). Note that with
#more zoomed in maps (i.e. with less range of bathymetry) the bias should be
#adjusted. For the full map: 0.2, for the FW map: 2
bathy_palette <- colorRampPalette(c("gray5", "midnightblue", "blue4", "blue2", 
                                    "blue", "dodgerblue", "lightblue"), 
                                  bias = 2)(256)

#create an overlay using the new matrix and colour palette
bathy_elev <- height_shade(bathy_matrix, texture = bathy_palette)
#plot to check
plot_map(bathy_elev)

#Plot the base map using the layers calculated above. Note that these layers can
#be run within the below pipeline (like sphere_shade) but aren't to save time.
base_map <- gbr_cropped_matrix %>%
  sphere_shade(zscale = 30, texture = "desert") %>% 
  add_shadow(raymat, max_darken = 0.2) %>%
  add_shadow(ambmat, max_darken = 0.2) %>%
  add_shadow(texturemat, max_darken = 0.2) %>% 
  add_overlay(generate_altitude_overlay(bathy_elev, gbr_cropped_matrix, 0, 0))
 

#add_shadow(cloud_shade(gbr_cropped_matrix, seed = 3, cloud_cover = 0.3), 
             #max_darken = 0) %>% #currently clouds cause render issues, dont use.
#add_water(watermat, color = "skyblue") #Dont need water as it can be rendered
#later on
#height_shade(topo.colors(256)) #colours by height

plot_map(base_map)

#to save 2D maps, use:
#open a new file
png(filename = "output/base_map.png", units = "cm", width = 20, height = 15, res = 300)
#plot the map to the file
plot_map(base_map)
#close the new file
dev.off()

#-------------------------------------------------------------------------------
#Now the 2D base map has been rendered we can work on adding extra layers and
#features, e.g. rivers, streams, lakes. This utilizes Open Street Map (OSM).

#create a normal num list from the coordinates above. This is used to tell the
#OSM where we are looking
osm_bbox = c(long_range[1],lat_range[1], long_range[2],lat_range[2])

#opq() queries OSM's resources: https://wiki.openstreetmap.org/wiki/Map_features
#add_osm_feature() is how we find things, e.g. "waterway", "natural", "place".
#osmdata_sf() returns the output as a simple feature (required to be plotted)
cropped_waterway <- opq(osm_bbox, timeout = 100) %>% 
  add_osm_feature("waterway") %>% 
  osmdata_sf()

cropped_nature <- opq(osm_bbox, timeout = 100) %>% 
  add_osm_feature("natural") %>% 
  osmdata_sf()

cropped_location <- opq(osm_bbox, timeout = 100) %>% 
  add_osm_feature("place") %>% 
  osmdata_sf()

#Inspect various features to check what we got and the best way to filter
cropped_waterway$osm_lines
cropped_waterway$osm_lines$name
cropped_nature$osm_polygon

#transform and filter the data to ensure it has the same crs as the base map.
cropped_waterway_line <- st_transform(cropped_waterway$osm_lines, crs = crs(proj_crs))
cropped_nature_poly <- st_transform(cropped_nature$osm_polygons, crs = crs(proj_crs))
cropped_location_point <- st_transform(cropped_location$osm_points, crs = crs(proj_crs))

#double check the crs
crs(cropped_location_point)

#pull out various aspects of the data, such as only the named waterways, lakes,
#shoals, wetlands etc.
named_waterway <- cropped_waterway_line %>% 
  filter(!is.na(name))

named_river <- cropped_waterway_line %>% 
  filter(str_detect(name, "River|Alligator"))

reef <- cropped_nature_poly %>% 
  filter(natural %in% c("reef"))

town <- cropped_location_point %>% 
  filter(!is.na(name)) %>% 
  filter(place %in% c("city","town")) %>% 
  filter(name != "Trebonne") #here to show additional filter options

#double check things look how you want
town$name

#create overlays that can be called later when rendering the map.
waterway_overlay <- generate_line_overlay(named_river, 
                                          extent = location_extent,
                                          linewidth = 1, color = "skyblue",
                                          heightmap = gbr_cropped_matrix)

nature_overlay <- generate_polygon_overlay(reef,
                                           extent = location_extent,
                                           heightmap = gbr_cropped_matrix, 
                                           palette = "deepskyblue4")

location_overlay <- generate_label_overlay(town,
                                           extent = location_extent,
                                           text_size = 2.5, point_size = 1.5, 
                                           seed = 1, halo_color = "white",
                                           halo_expand = 4, halo_blur = 2,
                                           halo_alpha = 0.7,
                                           heightmap = gbr_cropped_matrix,
                                           data_label_column = "name")

#take the 2D base map from earlier and add the new overlay.
overlay_map <- base_map %>% 
  add_overlay(waterway_overlay, alphalayer = 1)# %>% 
  #add_overlay(nature_overlay, alphalayer = 1) %>% 
  #add_overlay(location_overlay, alphalayer = 1) #note this should be added last 
#to be put onto of anything else - that includes later map overlays
plot_map(overlay_map)
#yay!

png(filename = "output/overlay_map.png", 
    units = "cm", width = 20, height = 15, res = 300)
plot_map(overlay_map)
dev.off()

#-------------------------------------------------------------------------------
#Now we can extract data from OSM lets try bring in the major Dry Tropics 
#borders. If I need to add the dt boundaries to these 2D and 3D elevation maps:
#read in layer
dt_master <- st_read(dsn = "input/shapefiles",
                      layer = "dt_master_layer")

#set the crs
dt_master <- st_transform(dt_master, proj_crs)

#create the overlay. Remember to filter the df before creating the overlay to
#pull out specific things
dt_master_overlay <- generate_polygon_overlay(dt_master, 
                                             extent = location_extent,
                                             heightmap = gbr_cropped_matrix,
                                             palette = "transparent",
                                             linecolor = "black",
                                             linewidth = "5")
test <- base_map %>% 
  add_overlay(dt_master_overlay)
plot(test)
dev.off()

#-------------------------------------------------------------------------------
#Now that we know how to create maps, and bring in extra overlays. Lets make 
#everything go into the 3rd dimension.

#zscale affects height. It is relative to x,y,z ratio and resolution. E.g. if 
#original DEM is at 30m res, then using zscale = 30 will render accurately, and
#zscale = 15 will render heights and bathymetry twice as large.
plot_3d(base_map, gbr_cropped_matrix, zscale = 25, soliddepth = -100, #use -1500 solid depth for bigger maps
        water = F, background = "grey50", shadowcolor = "white", 
        shadowdepth = -150, theta = 0, phi = 45, fov = 0, zoom = 1, #use -2500 shadow depth for bigger maps
        windowsize = c(200, 200, 2160, 2160)) #normal 3840 2160 # square 2160 2160

#we can now also render features after the rgl window is open, e.g. clouds, 
#labels, extra water, etc.

#Use this to render additional layers of water, easily model floods and sea
#level rise by adjusting the water depth option.
render_water(gbr_cropped_matrix, zscale = 30, waterdepth = 0, wateralpha = 0.5)

#Note that currently render_clouds() causes issues with other transparent layers
#such as water - it is best not to use clouds currently
render_clouds(gbr_cropped_matrix, zscale = 30, seed = 3, fractal_levels = 14,
              start_altitude = 3000, end_altitude = 4000, cloud_cover = 0.3,
              clear_clouds = T)

#we can also render things such as place labels

#create df with place names and lat/long from the sf extracted from osm earlier
temp <- cropped_location_point %>% 
  filter(!is.na(name))

#extract the coordinates from the sf data as a data frame
town_names <- as.data.frame(sf::st_coordinates(temp)) %>% 
  rename("long" = "X", "lat" = "Y")

#extract the names for each as a data frame
temp1 <- as.data.frame(temp) %>% 
  dplyr::select(name)

#combine the coorindates and the names - this probably can be done in one pipe
town_names <- cbind(temp1, town_names)

#fix up the index numbers
row.names(town_names) <- 1:nrow(town_names)

#remove the temp files
rm(temp, temp1)

#render labels from the town_names df. With the [] system, the row index is the 
#first number. Lat is always 3, long is always 2, and name is always 1. 
render_label(gbr_cropped_matrix, lat = town_names[1,3], long = town_names[1,2], 
             extent = location_extent, altitude=5000, zscale=50, 
             text = town_names[1,1])

#to get the row index use this or open the df and look them up
town_names[town_names$name=="Magnetic Island",]

render_label(gbr_cropped_matrix, lat = town_names[9,3], long = town_names[9,2], 
             extent = location_extent, altitude=5000, zscale=50, 
             text = town_names[9,1])

#used to clear all labels
render_label(clear_previous = TRUE)

#-------------------------------------------------------------------------------
#Once happy with the map it is time to save. for 3D maps:

#Use this to determine the current perspective of the camera, useful to make
#a predetermined optimal angle for the base 3D map
render_camera()

#Basic snapshot render of the current RGL view, no filename opens in view pane,
#adding file name saves as png, can do generic things such as add title text.
render_snapshot(title_text = "3D example", 
                title_font = "Helvetica", title_size = 50, title_color = "grey90",
                filename = "output/test2")

#Note, don't interact with RGL while render_movie() is running.
#Note, adding title text increases processing time dramatically (its weird idk why)
#render the 3D image as a movie, default is a 360 rotation, which is fine. File
#size is small than gif, but does not automatically repeat.Requires av package.
render_movie(title_text = "Townsville Dry Tropics, Queensland", 
             title_font = "Helvetica", title_size = 50, title_color = "grey90",
             filename = "output/test.mp4")

#gif outputs should have a square window size input. Requires gifski package.
render_movie(title_text = "3D gif example", 
             title_font = "Helvetica", title_size = 50,title_color = "grey90", 
             frames = 360, fps = 30, filename = "output/test.gif")

#There is also the option to render (and save) high quality versions using more
#realistic light transport models. Note that render_highquality() will take approx.
#8h plus to run. Prepare adequately to account for this. E.g. establish and 
#double check pipeline using a very low res version, then run full res.

#-----------------------------------------------------------------------------------------------Up to here. Trying to get a good hq render through

#Render image in high quality. Note this takes a long time to run and currently
#only produces a 2D output. There seems to be the option for 3D but I am yet
#to make that work.
#Note that using the function means I don't need to pre-calculate the shadows
#I should take the raw render
render_highquality("output/hq_test", width = 1080, height = 720)

#I can even add a light
render_highquality(light = FALSE, 
                   scene_elements = sphere(y = 150, radius = 30,
                                           material = diffuse(lightintensity = 40,
                                                              implicit_sample = TRUE)))


#------------------------------------------------------------------------------------------------- Create some examples for WT and MWI

town <- cropped_location_point %>% 
  filter(!is.na(name)) %>% 
  filter(place %in% c("city","town")) #%>% 
  filter(name == "Cairns") #here to show additional filter options

