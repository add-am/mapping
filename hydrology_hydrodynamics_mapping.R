#This script will be used to create 2D and 3D maps for any other region 
#required by the Northern Three.
#This script is currently in progress

#Created: 20/06/2022
#Author: Adam Shand
#Updated: 26/08/2022

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

# install/load packages --------------------------------------------------------
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

# data import and global vars ---------------------------------------------------
#GBR data is sourced from the Aus Seabed data portal:
#https://portal.ga.gov.au/persona/marine

#Use raster function to read elevation data as a raster. 100m data for low res,
#30m data for high res. Remember to update zscale
gbr <- raster("input/elevation/gbr_30m_2020.tif")
#use aggregate to group cells and reduce raster size or dis aggregate to increase 

#bring in the major Dry Tropics borders
dt_master <- st_read(dsn = "input/shapefiles",
                     layer = "dt_master_layer")

#set the project crs. Use the global EPSG:4326 unless specified otherwise
proj_crs <- crs("EPSG:4326")

#set geometry to planar - this is only a temp solution.
sf_use_s2(FALSE)

# data prep for ross base map --------------------------------------------------

#update gbr dataset to match project crs.
crs(gbr) <- proj_crs

#update dt master crs
dt_master <- st_transform(dt_master, proj_crs)

#pick out the zone I want
ross_boundary <- dt_master %>% 
  filter(str_detect(zone, "ross")) %>% 
  summarise(geometry = st_union(geometry))

#Specify the area in which we are working. Easiest way is to obtain extent from
#the zone where we are working. But we want to create a bit of a buffer so the
#polygon doesn't run right against the edge of the image.
buff <- st_buffer(ross_boundary, units::set_units(0.01, degree))

#take the extent of this new, slightly bigger polygon
location_extent <- extent(buff)

#Use crop to cut down the gbr data set to specified region
gbr_cropped <- crop(gbr, location_extent)

#Convert the raster to a matrix. (matrix are more digestible by rayshader)
gbr_cropped_matrix <- raster_to_matrix(gbr_cropped)

#we also want to create a layer outside our polygon for later. Get bbox coords 
bbox <- st_bbox(buff)

#turn bbox coords into a usable list
border_list = list(matrix(c(bbox[1], bbox[3], bbox[3], bbox[1], bbox[1], 
                            bbox[2], bbox[2], bbox[4], bbox[4], bbox[2]),
                          ncol = 2))

#turn list into a simple feature 
border <- st_as_sf(st_sfc(st_polygon(border_list)))

#update crs
st_crs(border) <- st_crs(proj_crs)

#take the difference of border and main polygon
outer <- st_difference(border, ross_boundary)

# create ross base map ---------------------------------------------------------
#Each overlay can be saved as variables to lower computing costs further down.

#create simple overlays:
#create a ray shade matrix. zscale affects shadows. Smaller num = bigger shadow
raymat <- ray_shade(gbr_cropped_matrix, zscale = 10, lambert = TRUE)
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
#adjusted. For large maps, small numbers, and vice versa
bathy_palette <- colorRampPalette(c("gray5", "midnightblue", "blue4", "blue2", 
                                    "blue", "dodgerblue", "lightblue"), 
                                  bias = 2)(256)

#create an overlay using the new matrix and colour palette
bathy_elev <- height_shade(bathy_matrix, texture = bathy_palette)

#Plot the base map using the layers calculated above.
base_map <- gbr_cropped_matrix %>%
  sphere_shade(zscale = 10, texture = "desert") %>% 
  add_shadow(raymat, max_darken = 0.2) %>%
  add_shadow(ambmat, max_darken = 0.2) %>%
  add_shadow(texturemat, max_darken = 0.2) %>% 
  add_water(detect_water(gbr_cropped_matrix, zscale = 1), color = "lightblue") %>% 
  add_overlay(generate_altitude_overlay(bathy_elev, gbr_cropped_matrix, 0, 0))

plot_map(base_map)

# create ross map features -----------------------------------------------------
#This utilizes Open Street Map (OSM). https://wiki.openstreetmap.org/wiki/Map_features
#create a normal num list from the bbox above.
osm_bbox = c(bbox[1],bbox[2], bbox[3],bbox[4])

#add_osm_feature() is how we find things, e.g. "waterway", "natural", "place".
#osmdata_sf() returns the output as a simple feature (required to be plotted)
waterway <- opq(osm_bbox, timeout = 100) %>% 
  add_osm_feature("waterway") %>% 
  osmdata_sf()

#transform and filter data to only get line data
waterway_line <- st_transform(waterway$osm_lines, crs = crs(proj_crs))

#crop data to location
waterway_line <- st_crop(waterway_line, location_extent)

#pull out various aspects of the data, such as only specific rivers and streams
named_river <- waterway_line %>% 
  filter(str_detect(name, "Ross|Bohle|Alligator|Crocodile")) %>% 
  filter(is.na(note))

#create overlays that can be called later when rendering the map.
river_overlay1 <- generate_line_overlay(named_river, 
                                          extent = location_extent,
                                          linewidth = 9, color = "darkblue",
                                          heightmap = gbr_cropped_matrix)

river_overlay2 <- generate_line_overlay(named_river, 
                                        extent = location_extent,
                                        linewidth = 7, color = "dodgerblue",
                                        heightmap = gbr_cropped_matrix)

# create ross map catchment borders --------------------------------------------

#using the unioned polygon from early, create overlays
ross_overlay1 <- generate_polygon_overlay(ross_boundary, 
                                              extent = location_extent,
                                              heightmap = gbr_cropped_matrix,
                                              palette = "transparent",
                                              linecolor = "black",
                                              linewidth = "8")

ross_overlay2 <- generate_polygon_overlay(ross_boundary, 
                                          extent = location_extent,
                                          heightmap = gbr_cropped_matrix,
                                          palette = "transparent",
                                          linecolor = "white",
                                          linewidth = "6")

#using the outer polygon from early, create overlay
ross_overlay3 <- generate_polygon_overlay(outer, 
                                          extent = location_extent,
                                          heightmap = gbr_cropped_matrix,
                                          palette = "black",
                                          linecolor = "black",
                                          linewidth = "0")

# plot ross 2D map -------------------------------------------------------------

#take the base map and add all the overlays created above
ross_map <- base_map %>%
  add_overlay(river_overlay1, alphalayer = 1) %>% 
  add_overlay(river_overlay2, alphalayer = 1) %>% 
  add_overlay(ross_overlay1, alphalayer = 1) %>%
  add_overlay(ross_overlay2, alphalayer = 1) %>% 
  add_overlay(ross_overlay3, alphalayer = 0.7)
 
plot_map(ross_map)

# plot and save ross 3D map ----------------------------------------------------
#Lets make everything go into the 3rd dimension.

#zscale affects height. It is relative to x,y,z ratio and resolution. E.g. if 
#original DEM is at 30m res, then using zscale = 30 will render accurately, and
#zscale = 15 will render heights and bathymetry twice as large.
plot_3d(ross_map, gbr_cropped_matrix, zscale = 20, soliddepth = -300,
        water = F, background = "white", shadowcolor = "grey50", 
        shadowdepth = -550, theta = 0, phi = 22, fov = 16.16, zoom = 0.59,
        windowsize = c(50, 50, 2160, 2160)) #normal 3840 2160, square 2160 2160

#we can now also render features after the rgl window is open, e.g. clouds, 
#labels, extra water, etc.

#Use this to render additional layers of water, easily model floods and sea
#level rise by adjusting the water depth option.
render_water(gbr_cropped_matrix, zscale = 10, waterdepth = 0, wateralpha = 0.5)

#save this as a gif before moving on to add additional features. Note that gif 
#outputs should have a square window size input. Note, dont interact with rgl
#window while running. Dont resive rgl window. Requires gifski package.
render_movie(frames = 360, fps = 30, 
             filename = "output/hydrodynamics_hydrology_maps/ross_gif.gif")

#close the rgl window so we can adjust the z scale
rgl::close3d()

#replot with new z scale
plot_3d(ross_map, gbr_cropped_matrix, zscale = 10, soliddepth = -300,
        water = F, background = "white", shadowcolor = "grey50", 
        shadowdepth = -550, theta = 0, phi = 22, fov = 16.16, zoom = 0.59,
        windowsize = c(50, 50, 2160, 2160)) #normal 3840 2160, square 2160 2160

#add water
render_water(gbr_cropped_matrix, zscale = 10, waterdepth = 0, wateralpha = 0.5)

#add 3D labels using osm to pull place names from online
places <- opq(osm_bbox, timeout = 100) %>% 
  add_osm_feature("place") %>% 
  osmdata_sf()

#transform data and filter for only point data
places <- st_transform(places$osm_points, crs = crs(proj_crs))

#crop data to location and filter to remove NAs
places <- st_crop(places, location_extent) %>%  
  filter(!is.na(name))

#extract the coordinates from the sf data as a data frame
town_names <- as.data.frame(sf::st_coordinates(places)) %>% 
  rename("long" = "X", "lat" = "Y")

#extract the names for each as a data frame
temp <- as.data.frame(places) %>% 
  dplyr::select(name)

#combine the coordinates and the names - this probably can be done in one pipe
town_names <- cbind(temp, town_names)

#fix up the index numbers
row.names(town_names) <- 1:nrow(town_names)

#remove the temp files
rm(temp)

#once the data is ready we are now adding labels while the rgl window is open
#used to clear all labels
render_label(clear_previous = TRUE)

#render labels from the town_names df. With the [] system, the row index is the 
#first number. Lat is always 3, long is always 2, and name is always 1. 
render_label(gbr_cropped_matrix, lat = town_names[1,3], long = town_names[1,2], 
             extent = location_extent, altitude=1000, zscale=10, 
             linewidth = 3, linecolor = "white", textsize = 1.5, text = town_names[1,1])

render_label(gbr_cropped_matrix, lat = town_names[1,3], long = town_names[1,2], 
             extent = location_extent, altitude=1000, zscale=10, 
             text = town_names[1,1], textalpha = 0, linewidth = 6)

#add a compass
render_compass(position = "W", compass_radius = 100)

#save a snapshot of the map 
#Use render_camera to determine camera perspective, useful to make a 
#predetermined optimal angle for the base 3D map
render_camera()
render_camera(theta = 180, phi = 30, fov = 16.16, zoom = 0.44)

#Basic snapshot render of the current RGL view, no filename opens in view pane,
#adding file name saves as png, can do generic things such as add title text.
render_snapshot(filename = "output/hydrodynamics_hydrology_maps/ross_still")

rgl::close3d()

# data prep for black base map --------------------------------------------------

#pick out the zone I want
black_boundary <- dt_master %>% 
  filter(str_detect(zone, "black")) %>% 
  summarise(geometry = st_union(geometry))

#Specify the area in which we are working. Easiest way is to obtain extent from
#the zone where we are working. But we want to create a bit of a buffer so the
#polygon doesn't run right against the edge of the image.
buff <- st_buffer(black_boundary, units::set_units(0.01, degree))

#take the extent of this new, slightly bigger polygon
location_extent <- extent(buff)

#Use crop to cut down the gbr data set to specified region
gbr_cropped <- crop(gbr, location_extent)

#Convert the raster to a matrix. (matrix are more digestible by rayshader)
gbr_cropped_matrix <- raster_to_matrix(gbr_cropped)

#we also want to create a layer outside our polygon for later. Get bbox coords 
bbox <- st_bbox(buff)

#turn bbox coords into a usable list
border_list = list(matrix(c(bbox[1], bbox[3], bbox[3], bbox[1], bbox[1], 
                            bbox[2], bbox[2], bbox[4], bbox[4], bbox[2]),
                          ncol = 2))

#turn list into a simple feature 
border <- st_as_sf(st_sfc(st_polygon(border_list)))

#update crs
st_crs(border) <- st_crs(proj_crs)

#take the difference of border and main polygon
outer <- st_difference(border, black_boundary)

# create black base map ---------------------------------------------------------
#Each overlay can be saved as variables to lower computing costs further down.

#create simple overlays:
#create a ray shade matrix. zscale affects shadows. Smaller num = bigger shadow
raymat <- ray_shade(gbr_cropped_matrix, zscale = 10, lambert = TRUE)
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
#adjusted. For large maps, small numbers, and vice versa
bathy_palette <- colorRampPalette(c("gray5", "midnightblue", "blue4", "blue2", 
                                    "blue", "dodgerblue", "lightblue"), 
                                  bias = 2)(256)

#create an overlay using the new matrix and colour palette
bathy_elev <- height_shade(bathy_matrix, texture = bathy_palette)

#Plot the base map using the layers calculated above.
base_map <- gbr_cropped_matrix %>%
  sphere_shade(zscale = 10, texture = "desert") %>% 
  add_shadow(raymat, max_darken = 0.2) %>%
  add_shadow(ambmat, max_darken = 0.2) %>%
  add_shadow(texturemat, max_darken = 0.2) %>% 
  add_water(detect_water(gbr_cropped_matrix, zscale = 1), color = "lightblue") %>% 
  add_overlay(generate_altitude_overlay(bathy_elev, gbr_cropped_matrix, 0, 0))

plot_map(base_map)

# create black map features -----------------------------------------------------
#This utilizes Open Street Map (OSM). https://wiki.openstreetmap.org/wiki/Map_features
#create a normal num list from the bbox above.
osm_bbox = c(bbox[1],bbox[2], bbox[3],bbox[4])

#add_osm_feature() is how we find things, e.g. "waterway", "natural", "place".
#osmdata_sf() returns the output as a simple feature (required to be plotted)
waterway <- opq(osm_bbox, timeout = 100) %>% 
  add_osm_feature("waterway") %>% 
  osmdata_sf()

#transform and filter data to only get line data
waterway_line <- st_transform(waterway$osm_lines, crs = crs(proj_crs))

#crop data to location
waterway_line <- st_crop(waterway_line, location_extent)

#pull out various aspects of the data, such as only specific rivers and streams
named_river <- waterway_line %>% 
  filter(str_detect(name, "Black|Alice|Ollera|Althaus|Rollingstone|Crystal|
                    |Sleeper|Camp|Deep|Lorna|Salt|Bluew|Leichhardt|Hencamp"))
  

#create overlays that can be called later when rendering the map.
river_overlay1 <- generate_line_overlay(named_river, 
                                        extent = location_extent,
                                        linewidth = 9, color = "darkblue",
                                        heightmap = gbr_cropped_matrix)

river_overlay2 <- generate_line_overlay(named_river, 
                                        extent = location_extent,
                                        linewidth = 7, color = "dodgerblue",
                                        heightmap = gbr_cropped_matrix)

# create black map catchment borders --------------------------------------------

#using the unioned polygon from early, create overlays
black_overlay1 <- generate_polygon_overlay(black_boundary, 
                                          extent = location_extent,
                                          heightmap = gbr_cropped_matrix,
                                          palette = "transparent",
                                          linecolor = "black",
                                          linewidth = "8")

black_overlay2 <- generate_polygon_overlay(black_boundary, 
                                          extent = location_extent,
                                          heightmap = gbr_cropped_matrix,
                                          palette = "transparent",
                                          linecolor = "white",
                                          linewidth = "6")

#using the outer polygon from early, create overlay
black_overlay3 <- generate_polygon_overlay(outer, 
                                          extent = location_extent,
                                          heightmap = gbr_cropped_matrix,
                                          palette = "black",
                                          linecolor = "black",
                                          linewidth = "0")

# plot black 2D map -------------------------------------------------------------

#take the base map and add all the overlays created above
black_map <- base_map %>%
  add_overlay(river_overlay1, alphalayer = 1) %>% 
  add_overlay(river_overlay2, alphalayer = 1) %>% 
  add_overlay(black_overlay1, alphalayer = 1) %>%
  add_overlay(black_overlay2, alphalayer = 1) %>% 
  add_overlay(black_overlay3, alphalayer = 0.7)

plot_map(black_map)

# plot and save black 3D map ----------------------------------------------------
#Lets make everything go into the 3rd dimension.

#zscale affects height. It is relative to x,y,z ratio and resolution. E.g. if 
#original DEM is at 30m res, then using zscale = 30 will render accurately, and
#zscale = 15 will render heights and bathymetry twice as large.
plot_3d(black_map, gbr_cropped_matrix, zscale = 20, soliddepth = -300,
        water = F, background = "white", shadowcolor = "grey50",
        shadowdepth = -550, theta = 0, phi = 22, fov = 16.16, zoom = 0.59,
        windowsize = c(50, 50, 2160, 2160)) #normal 3840 2160, square 2160 2160

#we can now also render features after the rgl window is open, e.g. clouds, 
#labels, extra water, etc.

#Use this to render additional layers of water, easily model floods and sea
#level rise by adjusting the water depth option.
render_water(gbr_cropped_matrix, zscale = 20, waterdepth = 0, wateralpha = 0.5)

#save this as a gif before moving on to add additional features. Note that gif 
#outputs should have a square window size input. Note, dont interact with rgl
#window while running. Dont resive rgl window. Requires gifski package.
render_movie(frames = 360, fps = 30, 
             filename = "output/hydrodynamics_hydrology_maps/black_gif.gif")

#close the rgl window so we can adjust the z scale
rgl::close3d()

#replot with new z scale
plot_3d(black_map, gbr_cropped_matrix, zscale = 10, soliddepth = -300,
        water = F, background = "white", shadowcolor = "grey50",
        shadowdepth = -550, theta = 180, phi = 30, fov = 16.16, zoom = 0.44,
        windowsize = c(50, 50, 2160, 2160))

#add water
render_water(gbr_cropped_matrix, zscale = 10, waterdepth = 0, wateralpha = 0.5)

#add compass
render_compass(position = "W", compass_radius = 100)

#save a snapshot of the map 
#Use render_camera to determine camera perspective, useful to make a 
#predetermined optimal angle for the base 3D map
render_camera()
render_camera(theta = 180, phi = 30, fov = 16.16, zoom = 0.44)

#Basic snapshot render of the current RGL view, no filename opens in view pane,
#adding file name saves as png, can do generic things such as add title text.
render_snapshot(filename = "output/hydrodynamics_hydrology_maps/black_still")

rgl::close3d()

# data prep for sea level 30m map --------------------------------------------------

#update gbr dataset to match project crs.
crs(gbr) <- proj_crs

#update dt master crs
dt_master <- st_transform(dt_master, proj_crs)

#pick out the zone I want
ross_black_boundary <- dt_master %>% 
  filter(str_detect(zone, "ross|black")) %>% 
  summarise(geometry = st_union(geometry))

#Specify the area in which we are working. Use coords for this one
sea_lvl_bound <- c(-19.70954, -18.70752, 146.1567, 147.3358)

#Overlay these onto a leaflet map to get an idea of how big each region is
leaflet() %>% 
  addTiles() %>% 
  addRectangles(lng1 = sea_lvl_bound[3], lat1 = sea_lvl_bound[1],
                lng2 = sea_lvl_bound[4], lat2 = sea_lvl_bound[2],
                fillColor = "transparent") 

#load a custom function that converts coords
source("src/convert_coords.R")

#convert coords, set crs, and make into an extent object
location_extent <- extent(convert_coords(lat = c(sea_lvl_bound[1], sea_lvl_bound[2]), 
                                         long = c(sea_lvl_bound[3], sea_lvl_bound[4]),
                                         to = crs(proj_crs)))

#Use crop to cut down the gbr data set to specified region
gbr_cropped <- crop(gbr, location_extent)

#Convert the raster to a matrix. (matrix are more digestible by rayshader)
gbr_cropped_matrix <- raster_to_matrix(gbr_cropped)

#we also want to create a layer outside our polygon for later. Get bbox coords 
bbox <- st_bbox(location_extent)

#turn bbox coords into a usable list
border_list = list(matrix(c(bbox[1], bbox[3], bbox[3], bbox[1], bbox[1], 
                            bbox[2], bbox[2], bbox[4], bbox[4], bbox[2]),
                          ncol = 2))

#turn list into a simple feature 
border <- st_as_sf(st_sfc(st_polygon(border_list)))

#update crs
st_crs(border) <- st_crs(proj_crs)

#take the difference of border and main polygon
outer <- st_difference(border, ross_black_boundary)

#bring in qld coast shp
qld <- st_read(dsn = "input/shapefiles",
               layer = "qld_polygon")

#set the crs
qld <- st_transform(qld, crs = proj_crs)

#take the difference of the qld poly and the bbox to get a coast cut
coast <- st_difference(border, qld)

#use coast to cut outer, returning only the land parts of outer
outer <- st_difference(outer, coast)

# create sea level 30m base map ----------------------------------------------------
#Each overlay can be saved as variables to lower computing costs further down.

#create simple overlays:
#create a ray shade matrix. zscale affects shadows. Smaller num = bigger shadow
raymat <- ray_shade(gbr_cropped_matrix, zscale = 10, lambert = TRUE)
#create an ambient shade matrix. zscale affects shadows as above.
ambmat <- ambient_shade(gbr_cropped_matrix, zscale = 10)
#create a texture map for additional shadows and increased detail.
texturemat <- texture_shade(gbr_cropped_matrix, detail = 1, contrast = 10, 
                            brightness = 10)

#create more complex overlays:
#bathymetry; copy original matrix to new matrix
bathy_matrix <- gbr_cropped_matrix
#cap all matrix values greater than x to NA
bathy_matrix[bathy_matrix > -30] = NA
#create a colour palette suitable to the overlay (e.g. blues). Note that with
#more zoomed in maps (i.e. with less range of bathymetry) the bias should be
#adjusted. For large maps, small numbers, and vice versa
bathy_palette <- colorRampPalette(c("gray5", "midnightblue", "blue4", "blue2", 
                                    "blue", "dodgerblue", "lightblue"), 
                                  bias = 2)(256)

#create an overlay using the new matrix and colour palette
bathy_elev <- height_shade(bathy_matrix, texture = bathy_palette)

#Plot the base map using the layers calculated above.
base_map <- gbr_cropped_matrix %>%
  sphere_shade(zscale = 10, texture = "desert") %>% 
  add_shadow(raymat, max_darken = 0.2) %>%
  add_shadow(ambmat, max_darken = 0.2) %>%
  add_shadow(texturemat, max_darken = 0.2) %>% 
  #add_water(detect_water(gbr_cropped_matrix, zscale = 1), color = "lightblue") %>% 
  add_overlay(generate_altitude_overlay(bathy_elev, gbr_cropped_matrix, -30, -30))

plot_map(base_map)

# create sea level 30m map features ------------------------------------------------
#This utilizes Open Street Map (OSM). https://wiki.openstreetmap.org/wiki/Map_features
#create a normal num list from the bbox above.
osm_bbox = c(bbox[1],bbox[2], bbox[3],bbox[4])

#add_osm_feature() is how we find things, e.g. "waterway", "natural", "place".
#osmdata_sf() returns the output as a simple feature (required to be plotted)
waterway <- opq(osm_bbox, timeout = 100) %>% 
  add_osm_feature("waterway") %>% 
  osmdata_sf()

#transform and filter data to only get line data
waterway_line <- st_transform(waterway$osm_lines, crs = crs(proj_crs))

#crop data to location
waterway_line <- st_intersection(waterway_line, ross_black_boundary)

#pull out various aspects of the data, such as only specific rivers and streams
named_river <- waterway_line %>% 
  filter(str_detect(name, "Ross|Bohle|Alligator|Crocodile|Black|Alice|Ollera|
  Althaus|Rollingstone|Crystal|Sleeper|Camp|Deep|Lorna|Salt|Bluew|Leichhardt|Hencamp")) %>% 
  filter(is.na(note))

#create overlays that can be called later when rendering the map.
river_overlay1 <- generate_line_overlay(named_river, 
                                        extent = location_extent,
                                        linewidth = 7, color = "darkblue",
                                        heightmap = gbr_cropped_matrix)

river_overlay2 <- generate_line_overlay(named_river, 
                                        extent = location_extent,
                                        linewidth = 5, color = "dodgerblue",
                                        heightmap = gbr_cropped_matrix)

# create sea level 30m map catchment borders ---------------------------------------

#using the unioned polygon from early, create overlays
ross_black_overlay1 <- generate_polygon_overlay(ross_black_boundary, 
                                          extent = location_extent,
                                          heightmap = gbr_cropped_matrix,
                                          palette = "transparent",
                                          linecolor = "black",
                                          linewidth = "8")

ross_black_overlay2 <- generate_polygon_overlay(ross_black_boundary, 
                                          extent = location_extent,
                                          heightmap = gbr_cropped_matrix,
                                          palette = "transparent",
                                          linecolor = "white",
                                          linewidth = "6")

#using the outer polygon from early, create overlay
ross_black_overlay3 <- generate_polygon_overlay(outer, 
                                          extent = location_extent,
                                          heightmap = gbr_cropped_matrix,
                                          palette = "black",
                                          linecolor = "black",
                                          linewidth = "0")

# plot sea level 30m 2D map --------------------------------------------------------

#take the base map and add all the overlays created above
sea_level_map <- base_map %>%
  add_overlay(river_overlay1, alphalayer = 1) %>% 
  add_overlay(river_overlay2, alphalayer = 1) %>% 
  add_overlay(ross_black_overlay1, alphalayer = 1) %>%
  add_overlay(ross_black_overlay2, alphalayer = 1) %>% 
  add_overlay(ross_black_overlay3, alphalayer = 0.7)

plot_map(sea_level_map)

# plot and save sea level 30m 3D map -----------------------------------------------
#Lets make everything go into the 3rd dimension.

#zscale affects height. It is relative to x,y,z ratio and resolution. E.g. if 
#original DEM is at 30m res, then using zscale = 30 will render accurately, and
#zscale = 15 will render heights and bathymetry twice as large.
plot_3d(sea_level_map, gbr_cropped_matrix, zscale = 20, soliddepth = -300,
        water = F, background = "white", shadowcolor = "grey50", 
        shadowdepth = -550, theta = 0, phi = 22, fov = 16.16, zoom = 0.40,
        windowsize = c(50, 50, 2160, 2160)) #normal 3840 2160, square 2160 2160

#we can now also render features after the rgl window is open, e.g. clouds, 
#labels, extra water, etc.

#Use this to render additional layers of water, easily model floods and sea
#level rise by adjusting the water depth option.
render_water(gbr_cropped_matrix, zscale = 20, waterdepth = -30, wateralpha = 0.5)

#save this as a gif before moving on to add additional features. Note that gif 
#outputs should have a square window size input. Note, dont interact with rgl
#window while running. Dont resive rgl window. Requires gifski package.
render_movie(frames = 360, fps = 30, 
             filename = "output/hydrodynamics_hydrology_maps/sea_level_30m_gif.gif")

#close the rgl window so we can adjust the z scale
rgl::close3d()

#replot with new z scale
plot_3d(sea_level_map, gbr_cropped_matrix, zscale = 10, soliddepth = -300,
        water = F, background = "white", shadowcolor = "grey50", 
        shadowdepth = -550, theta = 180, phi = 22, fov = 16.16, zoom = 0.46,
        windowsize = c(50, 50, 3840, 2160)) #normal 3840 2160, square 2160 2160

#add water
render_water(gbr_cropped_matrix, zscale = 10, waterdepth = -30, wateralpha = 0.5)

#add 3D labels using osm to pull place names from online
places <- opq(osm_bbox, timeout = 100) %>% 
  add_osm_feature("place") %>% 
  osmdata_sf()

#transform data and filter for only point data
places <- st_transform(places$osm_points, crs = crs(proj_crs))

#crop data to location and filter to remove NAs
places <- st_crop(places, location_extent) %>%  
  filter(!is.na(name))

#extract the coordinates from the sf data as a data frame
town_names <- as.data.frame(sf::st_coordinates(places)) %>% 
  rename("long" = "X", "lat" = "Y")

#extract the names for each as a data frame
temp <- as.data.frame(places) %>% 
  dplyr::select(name)

#combine the coordinates and the names - this probably can be done in one pipe
town_names <- cbind(temp, town_names)

#fix up the index numbers
row.names(town_names) <- 1:nrow(town_names)

#remove the temp file
rm(temp)

#once the data is ready we are now adding labels while the rgl window is open
#used to clear all labels
render_label(clear_previous = TRUE)

#render labels from the town_names df. With the [] system, the row index is the 
#first number. Lat is always 3, long is always 2, and name is always 1. 
render_label(gbr_cropped_matrix, lat = town_names[1,3], long = town_names[1,2], 
             extent = location_extent, altitude=7000, zscale=10, 
             linewidth = 3, linecolor = "white", textsize = 2, text = town_names[1,1])

render_label(gbr_cropped_matrix, lat = town_names[1,3], long = town_names[1,2], 
             extent = location_extent, altitude=7000, zscale=10, 
             text = town_names[1,1], textalpha = 0, linewidth = 6)

#add a compass
render_compass(position = "W", compass_radius = 100)

#save a snapshot of the map 
#Use render_camera to determine camera perspective, useful to make a 
#predetermined optimal angle for the base 3D map
render_camera()

#Basic snapshot render of the current RGL view, no filename opens in view pane,
#adding file name saves as png, can do generic things such as add title text.
render_snapshot(width = 3840, height = 2160,
  filename = "output/hydrodynamics_hydrology_maps/sea_level_30m_still")

rgl::close3d()
dev.off()

# -17m sea level ---------------------------------------------------------------
#NOTE. This requires the 30m sea level pipeline to be run first

#bathymetry; copy original matrix to new matrix
bathy_matrix <- gbr_cropped_matrix

#cap all matrix values greater than x to NA
bathy_matrix[bathy_matrix > -17] = NA

#create an overlay using the new matrix and colour palette
bathy_elev <- height_shade(bathy_matrix, texture = bathy_palette)

#Plot the base map using the layers calculated above.
base_map <- gbr_cropped_matrix %>%
  sphere_shade(zscale = 10, texture = "desert") %>% 
  add_shadow(raymat, max_darken = 0.2) %>%
  add_shadow(ambmat, max_darken = 0.2) %>%
  add_shadow(texturemat, max_darken = 0.2) %>% 
  add_overlay(generate_altitude_overlay(bathy_elev, gbr_cropped_matrix, -17, -17))

#take the base map and add all the overlays created above
sea_level_map <- base_map %>%
  add_overlay(river_overlay1, alphalayer = 1) %>% 
  add_overlay(river_overlay2, alphalayer = 1) %>% 
  add_overlay(ross_black_overlay1, alphalayer = 1) %>%
  add_overlay(ross_black_overlay2, alphalayer = 1) %>% 
  add_overlay(ross_black_overlay3, alphalayer = 0.7)

#plot_3d(sea_level_map, gbr_cropped_matrix, zscale = 20, soliddepth = -300,
        #water = F, background = "white", shadowcolor = "grey50", 
        #shadowdepth = -550, theta = 0, phi = 22, fov = 16.16, zoom = 0.40,
        #windowsize = c(50, 50, 2160, 2160))

#render_water(gbr_cropped_matrix, zscale = 20, waterdepth = -17, wateralpha = 0.5)

#render_movie(frames = 360, fps = 30, 
             #filename = "output/hydrodynamics_hydrology_maps/sea_level_17m_gif.gif")

#close the rgl window so we can adjust the z scale
#rgl::close3d()

#replot with new z scale
plot_3d(sea_level_map, gbr_cropped_matrix, zscale = 10, soliddepth = -300,
        water = F, background = "white", shadowcolor = "grey50", 
        shadowdepth = -550, theta = 180, phi = 22, fov = 16.16, zoom = 0.46,
        windowsize = c(50, 50, 3840, 2160)) #normal 3840 2160, square 2160 2160

#add water
render_water(gbr_cropped_matrix, zscale = 10, waterdepth = -17, wateralpha = 0.5)

render_label(gbr_cropped_matrix, lat = town_names[1,3], long = town_names[1,2], 
             extent = location_extent, altitude=7000, zscale=10, 
             linewidth = 3, linecolor = "white", textsize = 2, text = town_names[1,1])

render_label(gbr_cropped_matrix, lat = town_names[1,3], long = town_names[1,2], 
             extent = location_extent, altitude=7000, zscale=10, 
             text = town_names[1,1], textalpha = 0, linewidth = 6)

#Basic snapshot render of the current RGL view, no filename opens in view pane,
#adding file name saves as png, can do generic things such as add title text.
render_snapshot(width = 3840, height = 2160,
                filename = "output/hydrodynamics_hydrology_maps/sea_level_17m_still")

rgl::close3d()

# -10m sea level ---------------------------------------------------------------
#NOTE. This requires the 30m sea level pipeline to be run first

#bathymetry; copy original matrix to new matrix
bathy_matrix <- gbr_cropped_matrix

#cap all matrix values greater than x to NA
bathy_matrix[bathy_matrix > -10] = NA

#create an overlay using the new matrix and colour palette
bathy_elev <- height_shade(bathy_matrix, texture = bathy_palette)

#Plot the base map using the layers calculated above.
base_map <- gbr_cropped_matrix %>%
  sphere_shade(zscale = 10, texture = "desert") %>% 
  add_shadow(raymat, max_darken = 0.2) %>%
  add_shadow(ambmat, max_darken = 0.2) %>%
  add_shadow(texturemat, max_darken = 0.2) %>% 
  add_overlay(generate_altitude_overlay(bathy_elev, gbr_cropped_matrix, -10, -10))

#take the base map and add all the overlays created above
sea_level_map <- base_map %>%
  add_overlay(river_overlay1, alphalayer = 1) %>% 
  add_overlay(river_overlay2, alphalayer = 1) %>% 
  add_overlay(ross_black_overlay1, alphalayer = 1) %>%
  add_overlay(ross_black_overlay2, alphalayer = 1) %>% 
  add_overlay(ross_black_overlay3, alphalayer = 0.7)

#plot_3d(sea_level_map, gbr_cropped_matrix, zscale = 20, soliddepth = -300,
        #water = F, background = "white", shadowcolor = "grey50", 
        #shadowdepth = -550, theta = 0, phi = 22, fov = 16.16, zoom = 0.40,
        #windowsize = c(50, 50, 2160, 2160))

#render_water(gbr_cropped_matrix, zscale = 20, waterdepth = -10, wateralpha = 0.5)

#(frames = 360, fps = 30, 
             #filename = "output/hydrodynamics_hydrology_maps/sea_level_10m_gif.gif")

#close the rgl window so we can adjust the z scale
rgl::close3d()

#replot with new z scale
plot_3d(sea_level_map, gbr_cropped_matrix, zscale = 10, soliddepth = -300,
        water = F, background = "white", shadowcolor = "grey50", 
        shadowdepth = -550, theta = 180, phi = 22, fov = 16.16, zoom = 0.46,
        windowsize = c(50, 50, 3840, 2160)) #normal 3840 2160, square 2160 2160

#add water
render_water(gbr_cropped_matrix, zscale = 10, waterdepth = -10, wateralpha = 0.5)

render_label(gbr_cropped_matrix, lat = town_names[1,3], long = town_names[1,2], 
             extent = location_extent, altitude=7000, zscale=10, 
             linewidth = 3, linecolor = "white", textsize = 2, text = town_names[1,1])

render_label(gbr_cropped_matrix, lat = town_names[1,3], long = town_names[1,2], 
             extent = location_extent, altitude=7000, zscale=10, 
             text = town_names[1,1], textalpha = 0, linewidth = 6)

#Basic snapshot render of the current RGL view, no filename opens in view pane,
#adding file name saves as png, can do generic things such as add title text.
render_snapshot(width = 3840, height = 2160,
                filename = "output/hydrodynamics_hydrology_maps/sea_level_10m_still")

rgl::close3d()
# +3m sea level ---------------------------------------------------------------
#NOTE. This requires the 30m sea level pipeline to be run first

#bathymetry; copy original matrix to new matrix
bathy_matrix <- gbr_cropped_matrix

#cap all matrix values greater than x to NA
bathy_matrix[bathy_matrix > 3] = NA

#create an overlay using the new matrix and colour palette
bathy_elev <- height_shade(bathy_matrix, texture = bathy_palette)

#Plot the base map using the layers calculated above.
base_map <- gbr_cropped_matrix %>%
  sphere_shade(zscale = 10, texture = "desert") %>% 
  add_shadow(raymat, max_darken = 0.2) %>%
  add_shadow(ambmat, max_darken = 0.2) %>%
  add_shadow(texturemat, max_darken = 0.2) %>% 
  add_overlay(generate_altitude_overlay(bathy_elev, gbr_cropped_matrix, 3, 3))

#take the base map and add all the overlays created above
sea_level_map <- base_map %>%
  add_overlay(river_overlay1, alphalayer = 1) %>% 
  add_overlay(river_overlay2, alphalayer = 1) %>% 
  add_overlay(ross_black_overlay1, alphalayer = 1) %>%
  add_overlay(ross_black_overlay2, alphalayer = 1) %>% 
  add_overlay(ross_black_overlay3, alphalayer = 0.7)

#plot_3d(sea_level_map, gbr_cropped_matrix, zscale = 20, soliddepth = -300,
        #water = F, background = "white", shadowcolor = "grey50", 
        #shadowdepth = -550, theta = 0, phi = 22, fov = 16.16, zoom = 0.40,
        #windowsize = c(50, 50, 2160, 2160))

#render_water(gbr_cropped_matrix, zscale = 20, waterdepth = 2.8, wateralpha = 0.5)

#render_movie(frames = 360, fps = 30, 
             #filename = "output/hydrodynamics_hydrology_maps/sea_level_2.8m_gif.gif")

#close the rgl window so we can adjust the z scale
rgl::close3d()

#replot with new z scale
plot_3d(sea_level_map, gbr_cropped_matrix, zscale = 10, soliddepth = -300,
        water = F, background = "white", shadowcolor = "grey50", 
        shadowdepth = -550, theta = 180, phi = 22, fov = 16.16, zoom = 0.46,
        windowsize = c(50, 50, 3840, 2160)) #normal 3840 2160, square 2160 2160

#add water
render_water(gbr_cropped_matrix, zscale = 10, waterdepth = 3, wateralpha = 0.5)

render_label(gbr_cropped_matrix, lat = town_names[1,3], long = town_names[1,2], 
             extent = location_extent, altitude=7000, zscale=10, 
             linewidth = 3, linecolor = "white", textsize = 2, text = town_names[1,1])

render_label(gbr_cropped_matrix, lat = town_names[1,3], long = town_names[1,2], 
             extent = location_extent, altitude=7000, zscale=10, 
             text = town_names[1,1], textalpha = 0, linewidth = 6)

#Basic snapshot render of the current RGL view, no filename opens in view pane,
#adding file name saves as png, can do generic things such as add title text.
render_snapshot(width = 3840, height = 2160,
                filename = "output/hydrodynamics_hydrology_maps/sea_level_3m_still")

rgl::close3d()
# +1m sea level ---------------------------------------------------------------
#NOTE. This requires the 30m sea level pipeline to be run first

#bathymetry; copy original matrix to new matrix
bathy_matrix <- gbr_cropped_matrix

#cap all matrix values greater than x to NA
bathy_matrix[bathy_matrix > 1] = NA

#create an overlay using the new matrix and colour palette
bathy_elev <- height_shade(bathy_matrix, texture = bathy_palette)

#Plot the base map using the layers calculated above.
base_map <- gbr_cropped_matrix %>%
  sphere_shade(zscale = 10, texture = "desert") %>% 
  add_shadow(raymat, max_darken = 0.2) %>%
  add_shadow(ambmat, max_darken = 0.2) %>%
  add_shadow(texturemat, max_darken = 0.2) %>% 
  add_overlay(generate_altitude_overlay(bathy_elev, gbr_cropped_matrix, 1, 1))

#take the base map and add all the overlays created above
sea_level_map <- base_map %>%
  add_overlay(river_overlay1, alphalayer = 1) %>% 
  add_overlay(river_overlay2, alphalayer = 1) %>% 
  add_overlay(ross_black_overlay1, alphalayer = 1) %>%
  add_overlay(ross_black_overlay2, alphalayer = 1) %>% 
  add_overlay(ross_black_overlay3, alphalayer = 0.7)

#plot_3d(sea_level_map, gbr_cropped_matrix, zscale = 20, soliddepth = -300,
        #water = F, background = "white", shadowcolor = "grey50", 
        #shadowdepth = -550, theta = 0, phi = 22, fov = 16.16, zoom = 0.40,
        #windowsize = c(50, 50, 2160, 2160))

#render_water(gbr_cropped_matrix, zscale = 20, waterdepth = 1, wateralpha = 0.5)

#render_movie(frames = 360, fps = 30, 
             #filename = "output/hydrodynamics_hydrology_maps/sea_level_1m_gif.gif")

#close the rgl window so we can adjust the z scale
rgl::close3d()

#replot with new z scale
plot_3d(sea_level_map, gbr_cropped_matrix, zscale = 10, soliddepth = -300,
        water = F, background = "white", shadowcolor = "grey50", 
        shadowdepth = -550, theta = 180, phi = 22, fov = 16.16, zoom = 0.46,
        windowsize = c(50, 50, 3840, 2160)) #normal 3840 2160, square 2160 2160

#add water
render_water(gbr_cropped_matrix, zscale = 10, waterdepth = 1, wateralpha = 0.5)

render_label(gbr_cropped_matrix, lat = town_names[1,3], long = town_names[1,2], 
             extent = location_extent, altitude=7000, zscale=10, 
             linewidth = 3, linecolor = "white", textsize = 2, text = town_names[1,1])

render_label(gbr_cropped_matrix, lat = town_names[1,3], long = town_names[1,2], 
             extent = location_extent, altitude=7000, zscale=10, 
             text = town_names[1,1], textalpha = 0, linewidth = 6)

#Basic snapshot render of the current RGL view, no filename opens in view pane,
#adding file name saves as png, can do generic things such as add title text.
render_snapshot(width = 3840, height = 2160,
                filename = "output/hydrodynamics_hydrology_maps/sea_level_1m_still")

rgl::close3d()
# 0m sea level ---------------------------------------------------------------
#NOTE. This requires the 30m sea level pipeline to be run first

#bathymetry; copy original matrix to new matrix
bathy_matrix <- gbr_cropped_matrix

#cap all matrix values greater than x to NA
bathy_matrix[bathy_matrix > 0] = NA

#create an overlay using the new matrix and colour palette
bathy_elev <- height_shade(bathy_matrix, texture = bathy_palette)

#Plot the base map using the layers calculated above.
base_map <- gbr_cropped_matrix %>%
  sphere_shade(zscale = 10, texture = "desert") %>% 
  add_shadow(raymat, max_darken = 0.2) %>%
  add_shadow(ambmat, max_darken = 0.2) %>%
  add_shadow(texturemat, max_darken = 0.2) %>% 
  add_overlay(generate_altitude_overlay(bathy_elev, gbr_cropped_matrix, 0, 0))

#take the base map and add all the overlays created above
sea_level_map <- base_map %>%
  add_overlay(river_overlay1, alphalayer = 1) %>% 
  add_overlay(river_overlay2, alphalayer = 1) %>% 
  add_overlay(ross_black_overlay1, alphalayer = 1) %>%
  add_overlay(ross_black_overlay2, alphalayer = 1) %>% 
  add_overlay(ross_black_overlay3, alphalayer = 0.7)

#plot_3d(sea_level_map, gbr_cropped_matrix, zscale = 20, soliddepth = -300,
        #water = F, background = "white", shadowcolor = "grey50", 
        #shadowdepth = -550, theta = 0, phi = 22, fov = 16.16, zoom = 0.40,
        #windowsize = c(50, 50, 2160, 2160))

#render_water(gbr_cropped_matrix, zscale = 20, waterdepth = 0, wateralpha = 0.5)

#render_movie(frames = 360, fps = 30, 
             #filename = "output/hydrodynamics_hydrology_maps/sea_level_0m_gif.gif")

#close the rgl window so we can adjust the z scale
rgl::close3d()

#replot with new z scale
plot_3d(sea_level_map, gbr_cropped_matrix, zscale = 10, soliddepth = -300,
        water = F, background = "white", shadowcolor = "grey50", 
        shadowdepth = -550, theta = 180, phi = 22, fov = 16.16, zoom = 0.46,
        windowsize = c(50, 50, 3840, 2160)) #normal 3840 2160, square 2160 2160

#add water
render_water(gbr_cropped_matrix, zscale = 10, waterdepth = 0, wateralpha = 0.5)

render_label(gbr_cropped_matrix, lat = town_names[1,3], long = town_names[1,2], 
             extent = location_extent, altitude=7000, zscale=10, 
             linewidth = 3, linecolor = "white", textsize = 2, text = town_names[1,1])

render_label(gbr_cropped_matrix, lat = town_names[1,3], long = town_names[1,2], 
             extent = location_extent, altitude=7000, zscale=10, 
             text = town_names[1,1], textalpha = 0, linewidth = 6)

#Basic snapshot render of the current RGL view, no filename opens in view pane,
#adding file name saves as png, can do generic things such as add title text.
render_snapshot(width = 3840, height = 2160,
                filename = "output/hydrodynamics_hydrology_maps/sea_level_0m_still")

rgl::close3d()

# n3 temporary section---------------------------------------------------------

#set the project crs. Use the global EPSG:4326 unless specified otherwise
proj_crs <- crs("EPSG:4326")

#set geometry to planar
sf_use_s2(T)

#Read in raster
gbr <- raster("input/elevation/gbr_30m_2020.tif")

#read the drainage basins and drainage basin sub areas
basins <- st_read(dsn = "input/shapefiles/Drainage_basins.gpkg")
sub_basins <- st_read(dsn = "input/shapefiles/Drainage_basin_sub_areas.gpkg")

#update crs
basins <- st_transform(basins, proj_crs)
sub_basins <- st_transform(sub_basins, proj_crs)

#select northern three basins based on list of names
n3_basins <- basins %>% 
  filter(BASIN_NAME %in% c("Ross", "Black", "Don", "Proserpine", "O'Connell", 
                           "Pioneer", "Plane", "Daintree", "Mossman", "Barron", 
                           "Johnstone", "Tully", "Murray", "Herbert"))

#wet tropics split mulgrave-russell into two separate sub basins.
#get Russell and Mulgrave River from sub_basins
temp <- sub_basins %>% 
  filter(SUB_NAME %in% c("Russell River", "Mulgrave River")) %>% 
  mutate(SUB_NAME = case_when(SUB_NAME == "Russell River" ~ "Russell",
                              SUB_NAME == "Mulgrave River" ~ "Mulgrave")) %>% 
  rename(BASIN_NAME = SUB_NAME, BASIN_NUMBER = SUB_NUMBER)

#add the two basins onto main
n3_basins <- rbind(n3_basins, temp)

#clean up
rm(temp, basins, sub_basins)

#remove unwanted vars and add regional context
n3_basins <- n3_basins %>% 
  select(BASIN_NAME) %>% 
  rename(basin = BASIN_NAME) %>% 
  mutate(region = case_when(
    str_detect(basin, "Ross|Black") ~ "Dry Tropics",
    str_detect(basin, "Dain|Moss|Barr|John|Tull|Murr|Herb|Mulg|Russ") ~ "Wet Tropics",
    str_detect(basin, "Don|Proser|O'|Pio|Plane") ~ "Mackay Whitsunday Isaac"), .after = basin)

#update gbr dataset to match project crs.
crs(gbr) <- proj_crs

#pick out the zone I want
ross_black_boundary <- n3_basins %>% 
  filter(str_detect(region, "Wet Tropics")) %>% 
  st_union(by_feature = FALSE) %>% st_combine() %>%
  nngeo::st_remove_holes() %>% 
  st_sf()

#Specify the area in which we are working. Use coords for this one
sea_lvl_bound <- c(-17.0255, -16.4495, 145.3150, 145.9838)
DT <- 
wet_tropics_full <- c(-17.0255, -16.4495, 145.3150, 145.9838)
mwi_full <- c(-21.1833, -19.8456, 148.0714, 149.3335)



#Overlay these onto a leaflet map to get an idea of how big each region is
leaflet() %>% 
  addTiles() %>% 
  addRectangles(lng1 = sea_lvl_bound[3], lat1 = sea_lvl_bound[1],
                lng2 = sea_lvl_bound[4], lat2 = sea_lvl_bound[2],
                fillColor = "transparent") 

#load a custom function that converts coords
source("convert_coords.R")

#convert coords, set crs, and make into an extent object
location_extent <- extent(convert_coords(lat = c(sea_lvl_bound[1], sea_lvl_bound[2]), 
                                         long = c(sea_lvl_bound[3], sea_lvl_bound[4]),
                                         to = crs(proj_crs)))

#Use crop to cut down the gbr data set to specified region
gbr_cropped <- crop(gbr, location_extent)

#Convert the raster to a matrix. (matrix are more digestible by rayshader)
gbr_cropped_matrix <- raster_to_matrix(gbr_cropped)

#we also want to create a layer outside our polygon for later. Get bbox coords 
bbox <- st_bbox(location_extent)

#turn bbox coords into a usable list
border_list = list(matrix(c(bbox[1], bbox[3], bbox[3], bbox[1], bbox[1], 
                            bbox[2], bbox[2], bbox[4], bbox[4], bbox[2]),
                          ncol = 2))

#turn list into a simple feature 
border <- st_as_sf(st_sfc(st_polygon(border_list)))

#update crs
st_crs(border) <- st_crs(proj_crs)

#take the difference of border and main polygon
outer <- st_difference(border, ross_black_boundary)

#bring in qld coast shp
qld <- st_read(dsn = "input/shapefiles",
               layer = "qld_polygon")

#set the crs
qld <- st_transform(qld, crs = proj_crs)

#take the difference of the qld poly and the bbox to get a coast cut
coast <- st_difference(border, qld)

#use coast to cut outer, returning only the land parts of outer
outer <- st_difference(outer, coast)

#bathymetry; copy original matrix to new matrix
bathy_matrix <- gbr_cropped_matrix

#cap all matrix values greater than x to NA
bathy_matrix[bathy_matrix > 0] = NA

bathy_palette <- colorRampPalette(c("gray5", "midnightblue", "blue4", "blue2", 
                                    "blue", "dodgerblue", "lightblue"), 
                                  bias = 2)(256)


#create an overlay using the new matrix and colour palette
bathy_elev <- height_shade(bathy_matrix, texture = bathy_palette)

#create simple overlays:
#create a ray shade matrix. zscale affects shadows. Smaller num = bigger shadow
raymat <- ray_shade(gbr_cropped_matrix, zscale = 10, lambert = TRUE)
#create an ambient shade matrix. zscale affects shadows as above.
ambmat <- ambient_shade(gbr_cropped_matrix, zscale = 10)
#create a texture map for additional shadows and increased detail.
texturemat <- texture_shade(gbr_cropped_matrix, detail = 1, contrast = 10, 
                            brightness = 10)


#Plot the base map using the layers calculated above.
base_map <- gbr_cropped_matrix %>%
  sphere_shade(zscale = 10, texture = "desert") %>% 
  add_shadow(raymat, max_darken = 0.2) %>%
  add_shadow(ambmat, max_darken = 0.2) %>%
  add_shadow(texturemat, max_darken = 0.2) %>% 
  add_overlay(generate_altitude_overlay(bathy_elev, gbr_cropped_matrix, 0, 0))

#using the unioned polygon from early, create overlays
ross_black_overlay1 <- generate_polygon_overlay(ross_black_boundary, 
                                                extent = location_extent,
                                                heightmap = gbr_cropped_matrix,
                                                palette = "transparent",
                                                linecolor = "black",
                                                linewidth = "8")

ross_black_overlay2 <- generate_polygon_overlay(ross_black_boundary, 
                                                extent = location_extent,
                                                heightmap = gbr_cropped_matrix,
                                                palette = "transparent",
                                                linecolor = "white",
                                                linewidth = "6")

#using the outer polygon from early, create overlay
ross_black_overlay3 <- generate_polygon_overlay(outer, 
                                                extent = location_extent,
                                                heightmap = gbr_cropped_matrix,
                                                palette = "black",
                                                linecolor = "black",
                                                linewidth = "0")

#take the base map and add all the overlays created above
sea_level_map <- base_map #%>%
  add_overlay(river_overlay1, alphalayer = 1) %>% 
  add_overlay(river_overlay2, alphalayer = 1) %>% 
  add_overlay(ross_black_overlay1, alphalayer = 1) %>%
  add_overlay(ross_black_overlay2, alphalayer = 1) %>% 
  add_overlay(ross_black_overlay3, alphalayer = 0.7)

#plot_3d(sea_level_map, gbr_cropped_matrix, zscale = 20, soliddepth = -300,
#water = F, background = "white", shadowcolor = "grey50", 
#shadowdepth = -550, theta = 0, phi = 22, fov = 16.16, zoom = 0.40,
#windowsize = c(50, 50, 2160, 2160))

#render_water(gbr_cropped_matrix, zscale = 20, waterdepth = 0, wateralpha = 0.5)

#render_movie(frames = 360, fps = 30, 
#filename = "output/hydrodynamics_hydrology_maps/sea_level_0m_gif.gif")

#close the rgl window so we can adjust the z scale
rgl::close3d()

#replot with new z scale
plot_3d(sea_level_map, gbr_cropped_matrix, zscale = 10, soliddepth = -300,
        water = F, background = "white", shadowcolor = "grey50", 
        shadowdepth = -550, theta = 180, phi = 22, fov = 16.16, zoom = 0.46,
        windowsize = c(50, 50, 3840, 2160)) #normal 3840 2160, square 2160 2160

#add water
render_water(gbr_cropped_matrix, zscale = 10, waterdepth = 0, wateralpha = 0.5)

buff <- st_buffer(ross_black_boundary, units::set_units(0.01, degree))

#we also want to create a layer outside our polygon for later. Get bbox coords 
bbox <- st_bbox(buff)

osm_bbox = c(bbox[1],bbox[2], bbox[3],bbox[4])

#add 3D labels using osm to pull place names from online
places <- opq(osm_bbox, timeout = 100) %>% 
  add_osm_feature("place") %>% 
  osmdata_sf()

#transform data and filter for only point data
places <- st_transform(places$osm_points, crs = crs(proj_crs))

#crop data to location and filter to remove NAs and smaller places
places <- st_crop(places, location_extent) %>%  
  filter(!is.na(name)) %>% 
  filter(place == c("city", "town"))

#extract the coordinates from the sf data as a data frame
town_names <- as.data.frame(sf::st_coordinates(places)) %>% 
  rename("long" = "X", "lat" = "Y")

#extract the names for each as a data frame
temp <- as.data.frame(places) %>% 
  dplyr::select(name)

#combine the coordinates and the names - this probably can be done in one pipe
town_names <- cbind(temp, town_names)

#fix up the index numbers
row.names(town_names) <- 1:nrow(town_names)

#remove the temp files
rm(temp)


render_label(gbr_cropped_matrix, lat = town_names[1,3], long = town_names[1,2], 
             extent = location_extent, altitude=7000, zscale=10, 
             linewidth = 3, linecolor = "white", textsize = 2, text = town_names[1,1])

render_label(gbr_cropped_matrix, lat = town_names[1,3], long = town_names[1,2], 
             extent = location_extent, altitude=7000, zscale=10, 
             text = town_names[1,1], textalpha = 0, linewidth = 6)

render_label(gbr_cropped_matrix, lat = town_names[3,3], long = town_names[3,2], 
             extent = location_extent, altitude=7000, zscale=10, 
             linewidth = 3, linecolor = "white", textsize = 2, text = town_names[3,1])

render_label(gbr_cropped_matrix, lat = town_names[3,3], long = town_names[3,2], 
             extent = location_extent, altitude=7000, zscale=10, 
             text = town_names[3,1], textalpha = 0, linewidth = 6)



#Basic snapshot render of the current RGL view, no filename opens in view pane,
#adding file name saves as png, can do generic things such as add title text.
render_snapshot(width = 3840, height = 2160,
                filename = "output/hydrodynamics_hydrology_maps/Wet_Tropics")

rgl::close3d()

