#General mapping script
#This script is currently in progress
#Created: 16/08/2022
#Author: Adam Shand
#Updated: 18/08/2022

# packages ---------------------------------------------------------------------
#install and load all packages as normal (i.e. from CRAN)
library(raster) #Y
library(tmap) #Y
library(grid) #Y
library(RColorBrewer) #Y
library(sf) #Y
library(osmdata) #Y
library(maptools) #Y
library(tidyverse) #Y
library(stringr) #Y
library(dplyr) #Y

# CRS and Other Basics ---------------------------------------------------------

#set the project crs. Use the global EPSG:4326 unless specified otherwise
proj_crs <- crs("EPSG:4326")

#set geometry to planar - this is only a temp solution.
sf_use_s2(FALSE)

#set a common aspect ratio - debatable but seems to make maps look better
dt_master <- st_read(dsn = "input/shapefiles", 
                     layer = "dt_master_layer")

#set crs
dt_master <- st_transform(dt_master, proj_crs)

#group geometries at an env level
dt_env_lvl <- dt_master %>% 
  group_by(env) %>% 
  summarise(geometry = st_union(geometry))

#make a bounding box of the area which we are going to map
bbox <- st_as_sfc(st_bbox(dt_env_lvl))

#get the x and y bbox coordinates, so we can determine aspect ratio of map
xy <- st_bbox(dt_env_lvl)
asp1 <- (xy$ymax - xy$ymin)/(xy$xmax - xy$xmin)

# Creating Townsville location Point--------------------------------------------

#create a bbox that we used to retrieve osm data
dry_tropics_full <- c(-19.8145, -17.1727, 145.4625, 148.2558)
lat_range = c(dry_tropics_full[1],dry_tropics_full[2])
long_range = c(dry_tropics_full[3],dry_tropics_full[4])
osm_bbox = c(long_range[1],lat_range[1], long_range[2],lat_range[2])

#get all osm data with the "place" feature
cropped_location <- opq(osm_bbox, timeout = 100) %>% 
  add_osm_feature("place") %>% 
  osmdata_sf()

#filter to only get point data, and update crs
cropped_location_point <- st_transform(cropped_location$osm_points, crs = crs(proj_crs))

#filter to only get the point with the name Townsville, select name and geometry
townsville <- cropped_location_point %>% 
  filter(name %in% "Townsville") %>% 
  select(name, geometry)
# Creating DT base map from 3D elevation data ----------------------------------

#Use raster function to read elevation data as a raster. Take either the 100m
# data set or the 30m data set
gbr <- raster("input/elevation/gbr_100m_2020.tif")
#gbr <- raster("input/elevation/gbr_30m_2020.tif")

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

#just maggie (using for a hq render test)
maggie <- c(-19.1862, -19.0999, 146.7653, 146.8971)

#other
wet_tropics_full <- c(-18.9261, -15.1562, 144.1714, 148.1798)
mwi_full <- c(-22.3223, -19.1173, 147.2343, 152.1236)

#Overlay these onto a leaflet map to get an idea of how big each region is and
#how they overlap one another. These can be adjusted as required. Just pipe
#to repeat as many times as needed
leaflet() %>% 
  addTiles() %>% 
  addRectangles(lng1 = dry_tropics_full[3], lat1 = dry_tropics_full[1],
                lng2 = dry_tropics_full[4], lat2 = dry_tropics_full[2],
                fillColor = "transparent") %>%
  addRectangles(lng1 = dry_tropics_cu[3], lat1 = dry_tropics_cu[1],
                lng2 = dry_tropics_cu[4], lat2 = dry_tropics_cu[2],
                fillColor = "transparent")

#Pick out the boundaries of the region you would like to look at. This is where
#all subsequent lines get their extent/boundary/region from. swap in different
#values here to update everything else.
lat_range = c(dry_tropics_full[1],dry_tropics_full[2])
long_range = c(dry_tropics_full[3],dry_tropics_full[4])

#load a custom function that serves to convert the CRS of the coordinates 
#provided by Google (listed above) into the CRS of the data set (e.g. GBR)
source("src/convert_coords.R")

#Create bounding box for our chosen region using coords above and CRS from data.
location_extent <- extent(convert_coords(lat = lat_range, 
                                         long = long_range,
                                         to = crs(proj_crs)))
#Visual confirmation
location_extent

#Use crop to cut down the gbr data set to the region specified above. Run extent
#to check the output
gbr_cropped <- crop(gbr, location_extent)
extent(gbr_cropped)

#Convert the raster to a matrix. (matrix are more digestible by rayshader)
gbr_cropped_matrix <- raster_to_matrix(gbr_cropped)

#Create a 2D base map to check how things look. Each overlay (and the final base
#map) can be saved as variables to lower computing costs further down.

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

#check the dimension of the base map (see that it has 3 layers). Each of the 
#layers corresponds to a red, green, blue channel
dim(base_map)

#pull out each layer and turn it into its own raster. Use coords from earlier
layer1 <- raster(base_map[,,1], 
                 xmn = dry_tropics_full[3], xmx = dry_tropics_full[4], 
                 ymn = dry_tropics_full[1], ymx = dry_tropics_full[2],  
                 crs = proj_crs)
layer2 <- raster(base_map[,,2], 
                 xmn = dry_tropics_full[3], xmx = dry_tropics_full[4], 
                 ymn = dry_tropics_full[1], ymx = dry_tropics_full[2], 
                 crs = proj_crs)
layer3 <- raster(base_map[,,3], 
                 xmn = dry_tropics_full[3], xmx = dry_tropics_full[4], 
                 ymn = dry_tropics_full[1], ymx = dry_tropics_full[2], 
                 crs = proj_crs)

#stack the layers into a single raster stack
dt_base_map <- raster::stack(layer1, layer2, layer3)

#plot the raster stack, each layer corresponds to the rgb channels, but values
#have a max of 1, so adjust max to that
tm_shape(dt_base_map) +
  tm_rgb(r = 1, g = 2, b = 3, max.value = 1)

# DT Full Boundaries Map at env level (legend inside) --------------------------

#read in shapefile data
dt_master <- st_read(dsn = "input/shapefiles", 
                     layer = "dt_master_layer")

#set crs
dt_master <- st_transform(dt_master, proj_crs)

#group geometries at an env level
dt_env_lvl <- dt_master %>% 
  group_by(env) %>% 
  summarise(geometry = st_union(geometry))

#make a bounding box of the area which we are going to map
bbox <- st_as_sfc(st_bbox(dt_env_lvl))

#get the x and y bbox coordinates, so we can determine aspect ratio of map
xy <- st_bbox(dt_env_lvl)
asp1 <- (xy$ymax - xy$ymin)/(xy$xmax - xy$xmin)

#load a basic Aus outline 
aus <- st_read(dsn = "input/shapefiles",
               layer = "Aus")
aus <- st_transform(aus, proj_crs)

#load a basic qld outline, use the extent to crop the aus outline
qld <- st_read(dsn = "input/shapefiles",
               layer = "qld_polygon")
qld <- st_transform(qld, proj_crs)
extent <- extent(qld)
aus_crop <- st_crop(aus, extent)

#plot the main map
mainmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(aus_crop) +
  tm_borders(col = "black") +
  tm_shape(dt_env_lvl, is.master = TRUE) +
  tm_polygons(palette = brewer.pal(4, "Accent"), alpha = 0.65,
              col = "env", title = "DT Environments") +
  tm_shape(dt_env_lvl) + 
  tm_borders(col = "black") + 
  tm_shape(townsville) +
  tm_symbols(col = "red", border.col = "black", size = 0.5) +
  tm_shape(townsville) +
  tm_text(text = "name", size = 0.7, xmod = -1.8, ymod = 0.1, shadow = TRUE) +
  tm_compass(size = 1, position = c(0.92, 0.92)) + 
  tm_scale_bar(position = c(0.01, 0), width = 0.1) +
  tm_logo(file = "input/dt_logo.png", position = c(-0.01, 0.91), height = 1.7) +
  tm_layout(legend.outside = FALSE, legend.title.size = 1.2, 
            legend.text.size = 1.1, legend.frame = TRUE,
            legend.position = c(0.985, 0.11),
            legend.just = c("right", "top"), legend.width = -0.2, 
            legend.height = -0.1, legend.bg.color = "white",
            bg.color = "grey70", frame = TRUE,
            inner.margins = c(0.01, 0.01, 0.01, 0.01),
            outer.margins = c(0.01, 0.01, 0.01, 0.01))

#view the main map
mainmap

#get the x and y coordinates, of our inset map so we can determine aspect ratio
xy <- st_bbox(aus_crop)
asp2 <- (xy$ymax - xy$ymin)/(xy$xmax - xy$xmin)

#plot the inset map, overlay the bbox of the main map
insetmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(bbox) + tm_borders(lw=1, col="red") +
  tm_layout(inner.margins = c(0,0,0,0), outer.margins=c(0,0,0,0),
            bg.color = "white")

#view the inset map
insetmap

#create the viewport for the inset map. width = width of legend in main map. 
#height is calculated by using the aspect ration of the inset map
#x for viewport is x for legend of main map minus the inner margin
w <- 0.2
h <- asp2*w
vp <- viewport(x = 0.975, y = 0.38, width = w, height = h, just = c("right", "top"))

#save the main map, inset the second map. Height and width of final image is
#determined using the aspect ratio of the main map
tmap_save(mainmap, 
          filename = "output/technical_report_maps/dry_tropics_full_boundaries.png",
          dpi = 300, asp = 0, insets_tm = insetmap, insets_vp = vp,
          height = asp1*100, width = 100, units = "mm")



# DT Full Boundaries Map at env level (legend outside) -------------------------

#read in shapefile data
dt_master <- st_read(dsn = "input/shapefiles", 
                     layer = "dt_master_layer")

#set crs
dt_master <- st_transform(dt_master, proj_crs)

#group geometries at an env level
dt_env_lvl <- dt_master %>% 
  group_by(env) %>% 
  summarise(geometry = st_union(geometry))

#make a bounding box of the area which we are going to map
bbox <- st_as_sfc(st_bbox(dt_env_lvl))

#get the x and y bbox coordinates, so we can determine aspect ratio of map
xy <- st_bbox(dt_env_lvl)
asp1 <- (xy$ymax - xy$ymin)/(xy$xmax - xy$xmin)

#load a basic Aus outline 
aus <- st_read(dsn = "input/shapefiles",
               layer = "Aus")
aus <- st_transform(aus, proj_crs)

#load a basic qld outline, use the extent to crop the aus outline
qld <- st_read(dsn = "input/shapefiles",
               layer = "qld_polygon")
qld <- st_transform(qld, proj_crs)
extent <- extent(qld)
aus_crop <- st_crop(aus, extent)

#plot the main map
mainmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(aus_crop) +
  tm_borders(col = "black") +
  tm_shape(dt_env_lvl, is.master = TRUE) +
  tm_polygons(palette = brewer.pal(4, "Accent"),
              col = "env", title = "Dry Tropics Environments") +
  tm_shape(dt_env_lvl) + 
  tm_borders(col = "black") + 
  tm_shape(townsville) +
  tm_symbols(col = "red", border.col = "black", size = 0.5) +
  tm_shape(townsville) +
  tm_text(text = "name", size = 0.7, xmod = -1.8, ymod = 0.1, shadow = TRUE) +
  tm_compass(size = 1, position = c(0.92, 0.92)) + 
  tm_scale_bar(position = c(0.01, 0), width = 0.1) +
  tm_logo(file = "input/dt_logo.png", position = c(-0.01, 0.91), height = 1.7) +
  tm_layout(legend.outside = TRUE, legend.title.size = 1, 
            legend.text.size = 0.7, legend.frame = TRUE,
            legend.outside.position = "right",
            legend.position = c(0.02, 1),
            legend.just = c("left", "top"), legend.bg.color = "white",
            bg.color = "grey85", frame = TRUE,
            inner.margins = c(0.01, 0.01, 0.01, 0.01),
            outer.margins = c(0.01, 0.01, 0.01, 0.01))

#view the main map
#mainmap

#get the x and y coordinates, of our inset map so we can determine aspect ratio
xy <- st_bbox(aus_crop)
asp2 <- (xy$ymax - xy$ymin)/(xy$xmax - xy$xmin)

#plot the inset map, overlay the bbox of the main map
insetmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(aus_crop) +
  tm_borders(col = "black") +
  tm_shape(bbox) + tm_borders(lw=1, col="red") +
  tm_layout(inner.margins = c(0,0,0,0), outer.margins=c(0,0,0,0),
            bg.color = "white")

#view the inset map
#insetmap

#get the height and width for the map
main_h <- asp1*100
main_w <- main_h*1.5

#create the viewport for the inset map. width = width of legend in main map. 
#height is calculated by using the aspect ration of the inset map
#x for viewport is x for legend of main map minus the inner margin
w <- 0.2
h <- asp2*w
vp <- viewport(x = 0.64, y = 0.275, width = w, height = h, just = c("right", "top"))

#save the main map, inset the second map. Height and width of final image is
#determined using the aspect ratio of the main map
tmap_save(mainmap, 
          filename = "output/technical_report_maps/dry_tropics_full_boundaries.png",
          dpi = 300, insets_tm = insetmap, insets_vp = vp,
          height = main_h, width = main_w, units = "mm")

# DT Full Boundaries Map at zone level -----------------------------------------

#read in shapefile data
dt_master <- st_read(dsn = "input/shapefiles", 
                     layer = "dt_master_layer")

#set crs
dt_master <- st_transform(dt_master, proj_crs)

#group geometries at an env level
dt_zone_lvl <- dt_master %>% 
  group_by(zone, env) %>% 
  summarise(geometry = st_union(geometry))

#make a bounding box of the area which we are going to map
bbox <- st_as_sfc(st_bbox(dt_zone_lvl))

#get the x and y bbox coordinates, so we can determine aspect ratio of map
xy <- st_bbox(dt_zone_lvl)
asp1 <- (xy$ymax - xy$ymin)/(xy$xmax - xy$xmin)

#load a basic Aus outline 
aus <- st_read(dsn = "input/shapefiles",
               layer = "Aus")
aus <- st_transform(aus, proj_crs)

#load a basic qld outline, use the extent to crop the aus outline
qld <- st_read(dsn = "input/shapefiles",
               layer = "qld_polygon")
qld <- st_transform(qld, proj_crs)
extent <- extent(qld)
aus_crop <- st_crop(aus, extent)

#plot the main map
mainmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(aus_crop) +
  tm_borders(col = "black") +
  tm_shape(dt_zone_lvl, is.master = TRUE) +
  tm_polygons(palette = brewer.pal(4, "Accent"),
              col = "zone", title = "Dry Tropics Zones") +
  tm_shape(dt_zone_lvl) + 
  tm_borders(col = "black") + 
  tm_shape(townsville) +
  tm_symbols(col = "red", border.col = "black", size = 0.5) +
  tm_shape(townsville) +
  tm_text(text = "name", size = 0.7, xmod = -1.8, ymod = 0.1, shadow = TRUE) +
  tm_compass(size = 1, position = c(0.92, 0.92)) + 
  tm_scale_bar(position = c(0.01, 0), width = 0.1) +
  tm_logo(file = "input/dt_logo.png", position = c(-0.01, 0.91), height = 1.7) +
  tm_layout(legend.outside = TRUE, legend.title.size = 1, 
            legend.text.size = 0.7, legend.frame = TRUE,
            legend.outside.position = "right",
            legend.position = c(0.02, 1),
            legend.just = c("left", "top"), legend.bg.color = "white",
            bg.color = "grey85", frame = TRUE,
            inner.margins = c(0.01, 0.01, 0.01, 0.01),
            outer.margins = c(0.01, 0.01, 0.01, 0.01))

#view the main map
#mainmap

#get the x and y coordinates, of our inset map so we can determine aspect ratio
xy <- st_bbox(aus_crop)
asp2 <- (xy$ymax - xy$ymin)/(xy$xmax - xy$xmin)

#plot the inset map, overlay the bbox of the main map
insetmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(aus_crop) +
  tm_borders(col = "black") +
  tm_shape(bbox) + tm_borders(lw=1, col="red") +
  tm_layout(inner.margins = c(0,0,0,0), outer.margins=c(0,0,0,0),
            bg.color = "white")

#view the inset map
#insetmap

#get the height and width for the map
main_h <- asp1*100
main_w <- main_h*1.5

#create the viewport for the inset map. width = width of legend in main map. 
#height is calculated by using the aspect ration of the inset map
#x for viewport is x for legend of main map minus the inner margin
w <- 0.2
h <- asp2*w
vp <- viewport(x = 0.64, y = 0.275, width = w, height = h, just = c("right", "top"))

#save the main map, inset the second map. Height and width of final image is
#determined using the aspect ratio of the main map
tmap_save(mainmap, 
          filename = "output/technical_report_maps/dry_tropics_zones.png",
          dpi = 300, insets_tm = insetmap, insets_vp = vp,
          height = main_h, width = main_w, units = "mm")

# DT Full Boundaries Map at sub_zone level -------------------------------------

#read in shapefile data
dt_master <- st_read(dsn = "input/shapefiles", 
                     layer = "dt_master_layer")

#set crs
dt_master <- st_transform(dt_master, proj_crs)

#group geometries at an env level
dt_sub_zone_lvl <- dt_master %>% 
  group_by(sub_zone, zone, env) %>% 
  summarise(geometry = st_union(geometry))

#make a bounding box of the area which we are going to map
bbox <- st_as_sfc(st_bbox(dt_sub_zone_lvl))

#get the x and y bbox coordinates, so we can determine aspect ratio of map
xy <- st_bbox(dt_sub_zone_lvl)
asp1 <- (xy$ymax - xy$ymin)/(xy$xmax - xy$xmin)

#load a basic Aus outline 
aus <- st_read(dsn = "input/shapefiles",
               layer = "Aus")
aus <- st_transform(aus, proj_crs)

#load a basic qld outline, use the extent to crop the aus outline
qld <- st_read(dsn = "input/shapefiles",
               layer = "qld_polygon")
qld <- st_transform(qld, proj_crs)
extent <- extent(qld)
aus_crop <- st_crop(aus, extent)

#plot the main map
mainmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(aus_crop) +
  tm_borders(col = "black") +
  tm_shape(dt_sub_zone_lvl, is.master = TRUE) +
  tm_polygons(palette = brewer.pal(4, "Accent"),
              col = "sub_zone", title = "Dry Tropics Sub_Zones") +
  tm_shape(dt_sub_zone_lvl) + 
  tm_borders(col = "black") + 
  tm_shape(townsville) +
  tm_symbols(col = "red", border.col = "black", size = 0.5) +
  tm_shape(townsville) +
  tm_text(text = "name", size = 0.7, xmod = -1.8, ymod = 0.1, shadow = TRUE) +
  tm_compass(size = 1, position = c(0.92, 0.92)) + 
  tm_scale_bar(position = c(0.01, 0), width = 0.1) +
  tm_logo(file = "input/dt_logo.png", position = c(-0.01, 0.91), height = 1.7) +
  tm_layout(legend.outside = TRUE, legend.title.size = 1, 
            legend.text.size = 0.7, legend.frame = TRUE,
            legend.outside.position = "right",
            legend.position = c(0.02, 1),
            legend.just = c("left", "top"), legend.bg.color = "white",
            bg.color = "grey85", frame = TRUE,
            inner.margins = c(0.01, 0.01, 0.01, 0.01),
            outer.margins = c(0.01, 0.01, 0.01, 0.01))

#view the main map
#mainmap

#get the x and y coordinates, of our inset map so we can determine aspect ratio
xy <- st_bbox(aus_crop)
asp2 <- (xy$ymax - xy$ymin)/(xy$xmax - xy$xmin)

#plot the inset map, overlay the bbox of the main map
insetmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(aus_crop) +
  tm_borders(col = "black") +
  tm_shape(bbox) + tm_borders(lw=1, col="red") +
  tm_layout(inner.margins = c(0,0,0,0), outer.margins=c(0,0,0,0),
            bg.color = "white")

#view the inset map
#insetmap

#get the height and width for the map
main_h <- asp1*100
main_w <- main_h*1.5

#create the viewport for the inset map. width = width of legend in main map. 
#height is calculated by using the aspect ration of the inset map
#x for viewport is x for legend of main map minus the inner margin
w <- 0.2
h <- asp2*w
vp <- viewport(x = 0.64, y = 0.275, width = w, height = h, just = c("right", "top"))

#save the main map, inset the second map. Height and width of final image is
#determined using the aspect ratio of the main map
tmap_save(mainmap, 
          filename = "output/technical_report_maps/dry_tropics_sub_zones.png",
          dpi = 300, insets_tm = insetmap, insets_vp = vp,
          height = main_h, width = main_w, units = "mm")

# DT Full Boundaries Map at WQO level ------------------------------------------

#read in shapefile data
dt_master <- st_read(dsn = "input/shapefiles", 
                     layer = "dt_master_layer")

#set crs
dt_master <- st_transform(dt_master, proj_crs)

#group geometries at an env level
dt_ID_lvl <- dt_master %>% 
  group_by(MI_ID, sub_zone, zone, env) %>% 
  summarise(geometry = st_union(geometry))

#make a bounding box of the area which we are going to map
bbox <- st_as_sfc(st_bbox(dt_ID_lvl))

#get the x and y bbox coordinates, so we can determine aspect ratio of map
xy <- st_bbox(dt_ID_lvl)
asp1 <- (xy$ymax - xy$ymin)/(xy$xmax - xy$xmin)

#load a basic Aus outline 
aus <- st_read(dsn = "input/shapefiles",
               layer = "Aus")
aus <- st_transform(aus, proj_crs)

#load a basic qld outline, use the extent to crop the aus outline
qld <- st_read(dsn = "input/shapefiles",
               layer = "qld_polygon")
qld <- st_transform(qld, proj_crs)
extent <- extent(qld)
aus_crop <- st_crop(aus, extent)

#plot the main map
mainmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(aus_crop) +
  tm_borders(col = "black") +
  tm_shape(dt_ID_lvl, is.master = TRUE) +
  tm_polygons(palette = brewer.pal(4, "Accent"),
              col = "MI_ID", title = "Dry Tropics WQO ID") +
  tm_shape(dt_ID_lvl) + 
  tm_borders(col = "black") + 
  tm_shape(townsville) +
  tm_symbols(col = "red", border.col = "black", size = 0.5) +
  tm_shape(townsville) +
  tm_text(text = "name", size = 0.7, xmod = -1.8, ymod = 0.1, shadow = TRUE) +
  tm_compass(size = 1, position = c(0.92, 0.92)) + 
  tm_scale_bar(position = c(0.01, 0), width = 0.1) +
  tm_logo(file = "input/dt_logo.png", position = c(-0.01, 0.91), height = 1.7) +
  tm_layout(legend.outside = TRUE, legend.title.size = 1, 
            legend.text.size = 0.7, legend.frame = TRUE,
            legend.outside.position = "right",
            legend.position = c(0.02, 1),
            legend.just = c("left", "top"), legend.bg.color = "white",
            bg.color = "grey85", frame = TRUE,
            inner.margins = c(0.01, 0.01, 0.01, 0.01),
            outer.margins = c(0.01, 0.01, 0.01, 0.01))

#view the main map
#mainmap

#get the x and y coordinates, of our inset map so we can determine aspect ratio
xy <- st_bbox(aus_crop)
asp2 <- (xy$ymax - xy$ymin)/(xy$xmax - xy$xmin)

#plot the inset map, overlay the bbox of the main map
insetmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(aus_crop) +
  tm_borders(col = "black") +
  tm_shape(bbox) + tm_borders(lw=1, col="red") +
  tm_layout(inner.margins = c(0,0,0,0), outer.margins=c(0,0,0,0),
            bg.color = "white")

#view the inset map
#insetmap

#get the height and width for the map
main_h <- asp1*100
main_w <- main_h*1.5

#create the viewport for the inset map. width = width of legend in main map. 
#height is calculated by using the aspect ration of the inset map
#x for viewport is x for legend of main map minus the inner margin
w <- 0.2
h <- asp2*w
vp <- viewport(x = 0.64, y = 0.275, width = w, height = h, just = c("right", "top"))

#save the main map, inset the second map. Height and width of final image is
#determined using the aspect ratio of the main map
tmap_save(mainmap, 
          filename = "output/technical_report_maps/dry_tropics_wqo.png",
          dpi = 300, insets_tm = insetmap, insets_vp = vp,
          height = main_h, width = main_w, units = "mm")


# DT Ross Freshwater Map at sub_zone level -----------------------------------------

#read in shapefile data
dt_master <- st_read(dsn = "input/shapefiles", 
                     layer = "dt_master_layer")

#set crs
dt_master <- st_transform(dt_master, proj_crs)

#zoom into the specific zone we care about, and group by sub_zone
dt_ross_fw_zone <- dt_master %>% 
  filter(zone == "ross basin") %>% 
  group_by(sub_zone, zone, env) %>% 
  summarise(geometry = st_union(geometry))

#group geometries  for our background
temp_land <- dt_master %>% 
  filter(env %in% c("freshwater", "estuarine")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "land", .before = geometry)

temp_water <- dt_master %>% 
  filter(env %in% c("inshore", "offshore")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "water", .before = geometry)

dt_background <- rbind(temp_land, temp_water)

#load a basic Aus outline 
aus <- st_read(dsn = "input/shapefiles",
               layer = "Aus")
aus <- st_transform(aus, proj_crs)

#load a basic qld outline, use the extent to crop the aus outline
qld <- st_read(dsn = "input/shapefiles",
               layer = "qld_polygon")
qld <- st_transform(qld, proj_crs)
extent <- extent(qld)
aus_crop <- st_crop(aus, extent)

#plot the main map
mainmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(aus_crop) +
  tm_borders(col = "black") +
  tm_shape(dt_background) +
  tm_polygons(palette = c("khaki4", "lightblue"), alpha = 0.5,
              col = "name", legend.show = T, title = "Dry Tropics Region") +
  tm_shape(dt_background) +
  tm_borders(col = "black") +
  tm_shape(dt_ross_fw_zone, is.master = TRUE) +
  tm_polygons(palette = brewer.pal(4, "Accent"),
              col = "sub_zone", title = "Ross Freshwater Sub_Zones") +
  tm_shape(dt_ross_fw_zone) + 
  tm_borders(col = "black") + 
  tm_shape(townsville) +
  tm_symbols(col = "red", border.col = "black", size = 0.5) +
  tm_shape(townsville) +
  tm_text(text = "name", size = 0.7, xmod = -1.8, ymod = 0.1, shadow = TRUE) +
  tm_compass(size = 1, position = c(0.92, 0.92)) + 
  tm_scale_bar(position = c(0.01, 0), width = 0.1) +
  tm_logo(file = "input/dt_logo.png", position = c(-0.01, 0.91), height = 1.7) +
  tm_layout(legend.outside = TRUE, legend.title.size = 1, 
            legend.text.size = 0.7, legend.frame = TRUE,
            legend.outside.position = "right",
            legend.position = c(0.02, 1),
            legend.just = c("left", "top"), legend.bg.color = "white",
            bg.color = "grey85", frame = TRUE,
            inner.margins = c(0.01, 0.01, 0.01, 0.01),
            outer.margins = c(0.01, 0.01, 0.01, 0.01))

#view the main map
#mainmap

#get the height and width for the map
main_h <- asp1*100
main_w <- main_h*1.5

#save the main map, inset the second map. Height and width of final image is
#determined using the aspect ratio of the main map
tmap_save(mainmap, 
filename = "output/technical_report_maps/dt_ross_freshwater.png",
          dpi = 300, height = main_h, width = main_w, units = "mm")

# DT Ross Estuary Map at sub_zone level ----------------------------------------

#read in shapefile data
dt_master <- st_read(dsn = "input/shapefiles", 
                     layer = "dt_master_layer")

#set crs
dt_master <- st_transform(dt_master, proj_crs)

#zoom into the specific zone we care about, and group by sub_zone
dt_ross_est_zone <- dt_master %>% 
  filter(zone == "ross estuary") %>% 
  group_by(sub_zone, zone, env) %>% 
  summarise(geometry = st_union(geometry))

#group geometries  for our background
temp_land <- dt_master %>% 
  filter(env %in% c("freshwater", "estuarine")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "land", .before = geometry)

temp_water <- dt_master %>% 
  filter(env %in% c("inshore", "offshore")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "water", .before = geometry)

dt_background <- rbind(temp_land, temp_water)

#load a basic Aus outline 
aus <- st_read(dsn = "input/shapefiles",
               layer = "Aus")
aus <- st_transform(aus, proj_crs)

#load a basic qld outline, use the extent to crop the aus outline
qld <- st_read(dsn = "input/shapefiles",
               layer = "qld_polygon")
qld <- st_transform(qld, proj_crs)
extent <- extent(qld)
aus_crop <- st_crop(aus, extent)

#plot the main map
mainmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(aus_crop) +
  tm_borders(col = "black") +
  tm_shape(dt_background) +
  tm_polygons(palette = c("khaki4", "lightblue"), alpha = 0.5,
              col = "name", legend.show = T, title = "Dry Tropics Region") +
  tm_shape(dt_background) +
  tm_borders(col = "black") +
  tm_shape(dt_ross_est_zone, is.master = TRUE) +
  tm_polygons(palette = brewer.pal(4, "Accent"),
              col = "sub_zone", title = "Ross Estuary Sub_Zones") +
  tm_shape(dt_ross_est_zone) + 
  tm_borders(col = "black") + 
  tm_shape(townsville) +
  tm_symbols(col = "red", border.col = "black", size = 0.5) +
  tm_shape(townsville) +
  tm_text(text = "name", size = 0.7, xmod = -1.8, ymod = 0.1, shadow = TRUE) +
  tm_compass(size = 1, position = c(0.92, 0.92)) + 
  tm_scale_bar(position = c(0.01, 0), width = 0.1) +
  tm_logo(file = "input/dt_logo.png", position = c(-0.01, 0.90), height = 1.7) +
  tm_layout(legend.outside = TRUE, legend.title.size = 1, 
            legend.text.size = 0.7, legend.frame = TRUE,
            legend.outside.position = "right",
            legend.position = c(0.02, 1),
            legend.just = c("left", "top"), legend.bg.color = "white",
            bg.color = "grey85", frame = TRUE,
            inner.margins = c(0.01, 0.01, 0.01, 0.01),
            outer.margins = c(0.01, 0.01, 0.01, 0.01))

#view the main map
#mainmap

#get the height and width for the map
main_h <- asp1*100
main_w <- main_h*1.5

#save the main map, inset the second map. Height and width of final image is
#determined using the aspect ratio of the main map
tmap_save(mainmap, 
          filename = "output/technical_report_maps/dt_ross_estuary.png",
          dpi = 300, height = main_h, width = main_w, units = "mm")


# DT Black Freshwater Map at sub_zone level ------------------------------------

#read in shapefile data
dt_master <- st_read(dsn = "input/shapefiles", 
                     layer = "dt_master_layer")

#set crs
dt_master <- st_transform(dt_master, proj_crs)

#zoom into the specific zone we care about, and group by sub_zone
dt_black_fw_zone <- dt_master %>% 
  filter(zone == "black basin") %>% 
  group_by(sub_zone, zone, env) %>% 
  summarise(geometry = st_union(geometry))

#group geometries  for our background
temp_land <- dt_master %>% 
  filter(env %in% c("freshwater", "estuarine")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "land", .before = geometry)

temp_water <- dt_master %>% 
  filter(env %in% c("inshore", "offshore")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "water", .before = geometry)

dt_background <- rbind(temp_land, temp_water)

#load a basic Aus outline 
aus <- st_read(dsn = "input/shapefiles",
               layer = "Aus")
aus <- st_transform(aus, proj_crs)

#load a basic qld outline, use the extent to crop the aus outline
qld <- st_read(dsn = "input/shapefiles",
               layer = "qld_polygon")
qld <- st_transform(qld, proj_crs)
extent <- extent(qld)
aus_crop <- st_crop(aus, extent)



#plot the main map
mainmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(aus_crop) +
  tm_borders(col = "black") +
  tm_shape(dt_background) +
  tm_polygons(palette = c("khaki4", "lightblue"), alpha = 0.5,
              col = "name", legend.show = T, title = "Dry Tropics Region") +
  tm_shape(dt_background) +
  tm_borders(col = "black") +
  tm_shape(dt_black_fw_zone, is.master = TRUE) +
  tm_polygons(palette = brewer.pal(4, "Accent"),
              col = "sub_zone", title = "Black Freshwater Sub_Zones") +
  tm_shape(dt_black_fw_zone) + 
  tm_borders(col = "black") + 
  tm_shape(townsville) +
  tm_symbols(col = "red", border.col = "black", size = 0.5) +
  tm_shape(townsville) +
  tm_text(text = "name", size = 0.7, xmod = -1.8, ymod = 0.1, shadow = TRUE) +
  tm_compass(size = 1, position = c(0.92, 0.92)) + 
  tm_scale_bar(position = c(0.01, 0), width = 0.1) +
  tm_logo(file = "input/dt_logo.png", position = c(-0.01, 0.90), height = 1.7) +
  tm_layout(legend.outside = TRUE, legend.title.size = 1, 
            legend.text.size = 0.7, legend.frame = TRUE,
            legend.outside.position = "right",
            legend.position = c(0.02, 1),
            legend.just = c("left", "top"), legend.bg.color = "white",
            bg.color = "grey85", frame = TRUE,
            inner.margins = c(0.01, 0.01, 0.01, 0.01),
            outer.margins = c(0.01, 0.01, 0.01, 0.01))

#view the main map
#mainmap

#get the height and width for the map
main_h <- asp1*100
main_w <- main_h*1.5

#save the main map, inset the second map. Height and width of final image is
#determined using the aspect ratio of the main map
tmap_save(mainmap, 
          filename = "output/technical_report_maps/dt_black_freshwater.png",
          dpi = 300, height = main_h, width = main_w, units = "mm")


# DT Black Estuary Map at sub_zone level ---------------------------------------

#read in shapefile data
dt_master <- st_read(dsn = "input/shapefiles", 
                     layer = "dt_master_layer")

#set crs
dt_master <- st_transform(dt_master, proj_crs)

#zoom into the specific zone we care about, and group by sub_zone
dt_black_est_zone <- dt_master %>% 
  filter(zone == "black estuary") %>% 
  group_by(sub_zone, zone, env) %>% 
  summarise(geometry = st_union(geometry))

#group geometries  for our background
temp_land <- dt_master %>% 
  filter(env %in% c("freshwater", "estuarine")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "land", .before = geometry)

temp_water <- dt_master %>% 
  filter(env %in% c("inshore", "offshore")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "water", .before = geometry)

dt_background <- rbind(temp_land, temp_water)
#load a basic Aus outline 
aus <- st_read(dsn = "input/shapefiles",
               layer = "Aus")
aus <- st_transform(aus, proj_crs)

#load a basic qld outline, use the extent to crop the aus outline
qld <- st_read(dsn = "input/shapefiles",
               layer = "qld_polygon")
qld <- st_transform(qld, proj_crs)
extent <- extent(qld)
aus_crop <- st_crop(aus, extent)



#plot the main map
mainmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(aus_crop) +
  tm_borders(col = "black") +
  tm_shape(dt_background) +
  tm_polygons(palette = c("khaki4", "lightblue"), alpha = 0.5,
              col = "name", legend.show = T, title = "Dry Tropics Region") +
  tm_shape(dt_background) +
  tm_borders(col = "black") +
  tm_shape(dt_black_est_zone, is.master = TRUE) +
  tm_polygons(palette = brewer.pal(4, "Accent"),
              col = "sub_zone", title = "Black Estuary Sub_Zones") +
  tm_shape(dt_black_est_zone) + 
  tm_borders(col = "black") + 
  tm_shape(townsville) +
  tm_symbols(col = "red", border.col = "black", size = 0.5) +
  tm_shape(townsville) +
  tm_text(text = "name", size = 0.7, xmod = -1.8, ymod = 0.1, shadow = TRUE) +
  tm_compass(size = 1, position = c(0.92, 0.92)) + 
  tm_scale_bar(position = c(0.01, 0), width = 0.1) +
  tm_logo(file = "input/dt_logo.png", position = c(-0.01, 0.90), height = 1.7) +
  tm_layout(legend.outside = TRUE, legend.title.size = 1, 
            legend.text.size = 0.7, legend.frame = TRUE,
            legend.outside.position = "right",
            legend.position = c(0.02, 1),
            legend.just = c("left", "top"), legend.bg.color = "white",
            bg.color = "grey85", frame = TRUE,
            inner.margins = c(0.01, 0.01, 0.01, 0.01),
            outer.margins = c(0.01, 0.01, 0.01, 0.01))

#view the main map
#mainmap

#get the height and width for the map
main_h <- asp1*100
main_w <- main_h*1.5

#save the main map, inset the second map. Height and width of final image is
#determined using the aspect ratio of the main map
tmap_save(mainmap, 
          filename = "output/technical_report_maps/dt_black_estuary.png",
          dpi = 300, height = main_h, width = main_w, units = "mm")


# DT Cleveland Bay Map at sub_zone level ---------------------------------------

#read in shapefile data
dt_master <- st_read(dsn = "input/shapefiles", 
                     layer = "dt_master_layer")

#set crs
dt_master <- st_transform(dt_master, proj_crs)

#zoom into the specific zone we care about, and group by sub_zone
dt_cleveland_inshore_zone <- dt_master %>% 
  filter(zone == "Cleveland Bay") %>% 
  group_by(sub_zone, zone, env) %>% 
  summarise(geometry = st_union(geometry))

#group geometries  for our background
temp_land <- dt_master %>% 
  filter(env %in% c("freshwater", "estuarine")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "land", .before = geometry)

temp_water <- dt_master %>% 
  filter(env %in% c("inshore", "offshore")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "water", .before = geometry)

dt_background <- rbind(temp_land, temp_water)
#load a basic Aus outline 
aus <- st_read(dsn = "input/shapefiles",
               layer = "Aus")
aus <- st_transform(aus, proj_crs)

#load a basic qld outline, use the extent to crop the aus outline
qld <- st_read(dsn = "input/shapefiles",
               layer = "qld_polygon")
qld <- st_transform(qld, proj_crs)
extent <- extent(qld)
aus_crop <- st_crop(aus, extent)

#plot the main map
mainmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(aus_crop) +
  tm_borders(col = "black") +
  tm_shape(dt_background) +
  tm_polygons(palette = c("khaki4", "lightblue"), alpha = 0.5,
              col = "name", legend.show = T, title = "Dry Tropics Region") +
  tm_shape(dt_background) +
  tm_borders(col = "black") +
  tm_shape(dt_cleveland_inshore_zone, is.master = TRUE) +
  tm_polygons(palette = brewer.pal(4, "Accent"),
              col = "sub_zone", title = "Cleveland Bay Sub_Zones") +
  tm_shape(dt_cleveland_inshore_zone) + 
  tm_borders(col = "black") + 
  tm_shape(townsville) +
  tm_symbols(col = "red", border.col = "black", size = 0.5) +
  tm_shape(townsville) +
  tm_text(text = "name", size = 0.7, xmod = -1.8, ymod = 0.1, shadow = TRUE) +
  tm_compass(size = 1, position = c(0.92, 0.92)) + 
  tm_scale_bar(position = c(0.01, 0), width = 0.1) +
  tm_logo(file = "input/dt_logo.png", position = c(-0.01, 0.90), height = 1.7) +
  tm_layout(legend.outside = TRUE, legend.title.size = 1, 
            legend.text.size = 0.7, legend.frame = TRUE,
            legend.outside.position = "right",
            legend.position = c(0.02, 1),
            legend.just = c("left", "top"), legend.bg.color = "white",
            bg.color = "grey85", frame = TRUE,
            inner.margins = c(0.01, 0.01, 0.01, 0.01),
            outer.margins = c(0.01, 0.01, 0.01, 0.01))

#view the main map
#mainmap

#get the height and width for the map
main_h <- asp1*100
main_w <- main_h*1.5

#save the main map, inset the second map. Height and width of final image is
#determined using the aspect ratio of the main map
tmap_save(mainmap, 
          filename = "output/technical_report_maps/dt_cleveland_inshore.png",
          dpi = 300, height = main_h, width = main_w, units = "mm")

# DT Halifax Bay Map at sub_zone level -----------------------------------------

#read in shapefile data
dt_master <- st_read(dsn = "input/shapefiles", 
                     layer = "dt_master_layer")

#set crs
dt_master <- st_transform(dt_master, proj_crs)

#zoom into the specific zone we care about, and group by sub_zone
dt_halifax_inshore_zone <- dt_master %>% 
  filter(zone == "Halifax Bay") %>% 
  group_by(sub_zone, zone, env) %>% 
  summarise(geometry = st_union(geometry))

#group geometries  for our background
temp_land <- dt_master %>% 
  filter(env %in% c("freshwater", "estuarine")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "land", .before = geometry)

temp_water <- dt_master %>% 
  filter(env %in% c("inshore", "offshore")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "water", .before = geometry)

dt_background <- rbind(temp_land, temp_water)
#load a basic Aus outline 
aus <- st_read(dsn = "input/shapefiles",
               layer = "Aus")
aus <- st_transform(aus, proj_crs)

#load a basic qld outline, use the extent to crop the aus outline
qld <- st_read(dsn = "input/shapefiles",
               layer = "qld_polygon")
qld <- st_transform(qld, proj_crs)
extent <- extent(qld)
aus_crop <- st_crop(aus, extent)

#plot the main map
mainmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(aus_crop) +
  tm_borders(col = "black") +
  tm_shape(dt_background) +
  tm_polygons(palette = c("khaki4", "lightblue"), alpha = 0.5,
              col = "name", legend.show = T, title = "Dry Tropics Region") +
  tm_shape(dt_background) +
  tm_borders(col = "black") +
  tm_shape(dt_halifax_inshore_zone, is.master = TRUE) +
  tm_polygons(palette = brewer.pal(4, "Accent"),
              col = "sub_zone", title = "Halifax Bay Sub_Zones") +
  tm_shape(dt_halifax_inshore_zone) + 
  tm_borders(col = "black") + 
  tm_shape(townsville) +
  tm_symbols(col = "red", border.col = "black", size = 0.5) +
  tm_shape(townsville) +
  tm_text(text = "name", size = 0.7, xmod = -1.8, ymod = 0.1, shadow = TRUE) +
  tm_compass(size = 1, position = c(0.92, 0.92)) + 
  tm_scale_bar(position = c(0.01, 0), width = 0.1) +
  tm_logo(file = "input/dt_logo.png", position = c(-0.01, 0.90), height = 1.7) +
  tm_layout(legend.outside = TRUE, legend.title.size = 1, 
            legend.text.size = 0.7, legend.frame = TRUE,
            legend.outside.position = "right",
            legend.position = c(0.02, 1),
            legend.just = c("left", "top"), legend.bg.color = "white",
            bg.color = "grey85", frame = TRUE,
            inner.margins = c(0.01, 0.01, 0.01, 0.01),
            outer.margins = c(0.01, 0.01, 0.01, 0.01))

#view the main map
#mainmap

#get the height and width for the map
main_h <- asp1*100
main_w <- main_h*1.5

#save the main map, inset the second map. Height and width of final image is
#determined using the aspect ratio of the main map
tmap_save(mainmap, 
          filename = "output/technical_report_maps/dt_halifax_inshore.png",
          dpi = 300, height = main_h, width = main_w, units = "mm")
# DT Offshore Map at sub_zone level --------------------------------------------

#read in shapefile data
dt_master <- st_read(dsn = "input/shapefiles", 
                     layer = "dt_master_layer")

#set crs
dt_master <- st_transform(dt_master, proj_crs)

#zoom into the specific zone we care about, and group by sub_zone
dt_offshore_zone <- dt_master %>% 
  filter(zone == "offshore_zone") %>% 
  group_by(sub_zone, zone, env) %>% 
  summarise(geometry = st_union(geometry))

#group geometries  for our background
temp_land <- dt_master %>% 
  filter(env %in% c("freshwater", "estuarine")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "land", .before = geometry)

temp_water <- dt_master %>% 
  filter(env %in% c("inshore", "offshore")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "water", .before = geometry)

dt_background <- rbind(temp_land, temp_water)

#load a basic Aus outline 
aus <- st_read(dsn = "input/shapefiles",
               layer = "Aus")
aus <- st_transform(aus, proj_crs)

#load a basic qld outline, use the extent to crop the aus outline
qld <- st_read(dsn = "input/shapefiles",
               layer = "qld_polygon")
qld <- st_transform(qld, proj_crs)
extent <- extent(qld)
aus_crop <- st_crop(aus, extent)



#plot the main map
mainmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(aus_crop) +
  tm_borders(col = "black") +
  tm_shape(dt_background) +
  tm_polygons(palette = c("khaki4", "lightblue"), alpha = 0.5,
              col = "name", legend.show = T, title = "Dry Tropics Region") +
  tm_shape(dt_background) +
  tm_borders(col = "black") +
  tm_shape(dt_offshore_zone, is.master = TRUE) +
  tm_polygons(palette = brewer.pal(4, "Accent"),
              col = "sub_zone", title = "Offshore Sub_Zones") +
  tm_shape(dt_offshore_zone) + 
  tm_borders(col = "black") + 
  tm_shape(townsville) +
  tm_symbols(col = "red", border.col = "black", size = 0.5) +
  tm_shape(townsville) +
  tm_text(text = "name", size = 0.7, xmod = -1.8, ymod = 0.1, shadow = TRUE) +
  tm_compass(size = 1, position = c(0.92, 0.92)) + 
  tm_scale_bar(position = c(0.01, 0), width = 0.1) +
  tm_logo(file = "input/dt_logo.png", position = c(-0.01, 0.90), height = 1.7) +
  tm_layout(legend.outside = TRUE, legend.title.size = 1, 
            legend.text.size = 0.7, legend.frame = TRUE,
            legend.outside.position = "right",
            legend.position = c(0.02, 1),
            legend.just = c("left", "top"), legend.bg.color = "white",
            bg.color = "grey85", frame = TRUE,
            inner.margins = c(0.01, 0.01, 0.01, 0.01),
            outer.margins = c(0.01, 0.01, 0.01, 0.01))

#view the main map
#mainmap

#get the height and width for the map
main_h <- asp1*100
main_w <- main_h*1.5

#save the main map, inset the second map. Height and width of final image is
#determined using the aspect ratio of the main map
tmap_save(mainmap, 
          filename = "output/technical_report_maps/dt_offshore.png",
          dpi = 300, height = main_h, width = main_w, units = "mm")






# DT Ross Freshwater Map at WQO level -----------------------------------------

#read in shapefile data
dt_master <- st_read(dsn = "input/shapefiles", 
                     layer = "dt_master_layer")

#set crs
dt_master <- st_transform(dt_master, proj_crs)

#zoom into the specific zone we care about, and group by sub_zone
dt_ross_fw_zone <- dt_master %>% 
  filter(zone == "ross basin") %>% 
  group_by(MI_ID, sub_zone, zone, env) %>% 
  summarise(geometry = st_union(geometry))

#group geometries  for our background
temp_land <- dt_master %>% 
  filter(env %in% c("freshwater", "estuarine")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "land", .before = geometry)

temp_water <- dt_master %>% 
  filter(env %in% c("inshore", "offshore")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "water", .before = geometry)

dt_background <- rbind(temp_land, temp_water)

#load a basic Aus outline 
aus <- st_read(dsn = "input/shapefiles",
               layer = "Aus")
aus <- st_transform(aus, proj_crs)

#load a basic qld outline, use the extent to crop the aus outline
qld <- st_read(dsn = "input/shapefiles",
               layer = "qld_polygon")
qld <- st_transform(qld, proj_crs)
extent <- extent(qld)
aus_crop <- st_crop(aus, extent)

#plot the main map
mainmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(aus_crop) +
  tm_borders(col = "black") +
  tm_shape(dt_background) +
  tm_polygons(palette = c("khaki4", "lightblue"), alpha = 0.5,
              col = "name", legend.show = T, title = "Dry Tropics Region") +
  tm_shape(dt_background) +
  tm_borders(col = "black") +
  tm_shape(dt_ross_fw_zone, is.master = TRUE) +
  tm_polygons(palette = brewer.pal(4, "Accent"),
              col = "MI_ID", title = "Ross Freshwater WQO ID") +
  tm_shape(dt_ross_fw_zone) + 
  tm_borders(col = "black") + 
  tm_shape(townsville) +
  tm_symbols(col = "red", border.col = "black", size = 0.5) +
  tm_shape(townsville) +
  tm_text(text = "name", size = 0.7, xmod = -1.8, ymod = 0.1, shadow = TRUE) +
  tm_compass(size = 1, position = c(0.92, 0.92)) + 
  tm_scale_bar(position = c(0.01, 0), width = 0.1) +
  tm_logo(file = "input/dt_logo.png", position = c(-0.01, 0.91), height = 1.7) +
  tm_layout(legend.outside = TRUE, legend.title.size = 1, 
            legend.text.size = 0.7, legend.frame = TRUE,
            legend.outside.position = "right",
            legend.position = c(0.02, 1),
            legend.just = c("left", "top"), legend.bg.color = "white",
            bg.color = "grey85", frame = TRUE,
            inner.margins = c(0.01, 0.01, 0.01, 0.01),
            outer.margins = c(0.01, 0.01, 0.01, 0.01))

#view the main map
#mainmap

#get the height and width for the map
main_h <- asp1*100
main_w <- main_h*1.5

#save the main map, inset the second map. Height and width of final image is
#determined using the aspect ratio of the main map
tmap_save(mainmap, 
          filename = "output/technical_report_maps/dt_ross_freshwater_wqo.png",
          dpi = 300, height = main_h, width = main_w, units = "mm")

# DT Ross Estuary Map at WQO level ----------------------------------------

#read in shapefile data
dt_master <- st_read(dsn = "input/shapefiles", 
                     layer = "dt_master_layer")

#set crs
dt_master <- st_transform(dt_master, proj_crs)

#zoom into the specific zone we care about, and group by sub_zone
dt_ross_est_zone <- dt_master %>% 
  filter(zone == "ross estuary") %>% 
  group_by(MI_ID, sub_zone, zone, env) %>% 
  summarise(geometry = st_union(geometry))

#group geometries  for our background
temp_land <- dt_master %>% 
  filter(env %in% c("freshwater", "estuarine")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "land", .before = geometry)

temp_water <- dt_master %>% 
  filter(env %in% c("inshore", "offshore")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "water", .before = geometry)

dt_background <- rbind(temp_land, temp_water)

#load a basic Aus outline 
aus <- st_read(dsn = "input/shapefiles",
               layer = "Aus")
aus <- st_transform(aus, proj_crs)

#load a basic qld outline, use the extent to crop the aus outline
qld <- st_read(dsn = "input/shapefiles",
               layer = "qld_polygon")
qld <- st_transform(qld, proj_crs)
extent <- extent(qld)
aus_crop <- st_crop(aus, extent)

#plot the main map
mainmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(aus_crop) +
  tm_borders(col = "black") +
  tm_shape(dt_background) +
  tm_polygons(palette = c("khaki4", "lightblue"), alpha = 0.5,
              col = "name", legend.show = T, title = "Dry Tropics Region") +
  tm_shape(dt_background) +
  tm_borders(col = "black") +
  tm_shape(dt_ross_est_zone, is.master = TRUE) +
  tm_polygons(palette = brewer.pal(4, "Accent"),
              col = "MI_ID", title = "Ross Estuary WQO ID") +
  tm_shape(dt_ross_est_zone) + 
  tm_borders(col = "black") + 
  tm_shape(townsville) +
  tm_symbols(col = "red", border.col = "black", size = 0.5) +
  tm_shape(townsville) +
  tm_text(text = "name", size = 0.7, xmod = -1.8, ymod = 0.1, shadow = TRUE) +
  tm_compass(size = 1, position = c(0.92, 0.92)) + 
  tm_scale_bar(position = c(0.01, 0), width = 0.1) +
  tm_logo(file = "input/dt_logo.png", position = c(-0.01, 0.90), height = 1.7) +
  tm_layout(legend.outside = TRUE, legend.title.size = 1, 
            legend.text.size = 0.7, legend.frame = TRUE,
            legend.outside.position = "right",
            legend.position = c(0.02, 1),
            legend.just = c("left", "top"), legend.bg.color = "white",
            bg.color = "grey85", frame = TRUE,
            inner.margins = c(0.01, 0.01, 0.01, 0.01),
            outer.margins = c(0.01, 0.01, 0.01, 0.01))

#view the main map
#mainmap

#get the height and width for the map
main_h <- asp1*100
main_w <- main_h*1.5

#save the main map, inset the second map. Height and width of final image is
#determined using the aspect ratio of the main map
tmap_save(mainmap, 
          filename = "output/technical_report_maps/dt_ross_estuary_wqo.png",
          dpi = 300, height = main_h, width = main_w, units = "mm")


# DT Black Freshwater Map at WQO level ------------------------------------

#read in shapefile data
dt_master <- st_read(dsn = "input/shapefiles", 
                     layer = "dt_master_layer")

#set crs
dt_master <- st_transform(dt_master, proj_crs)

#zoom into the specific zone we care about, and group by sub_zone
dt_black_fw_zone <- dt_master %>% 
  filter(zone == "black basin") %>% 
  group_by(MI_ID, sub_zone, zone, env) %>% 
  summarise(geometry = st_union(geometry))

#group geometries  for our background
temp_land <- dt_master %>% 
  filter(env %in% c("freshwater", "estuarine")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "land", .before = geometry)

temp_water <- dt_master %>% 
  filter(env %in% c("inshore", "offshore")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "water", .before = geometry)

dt_background <- rbind(temp_land, temp_water)

#load a basic Aus outline 
aus <- st_read(dsn = "input/shapefiles",
               layer = "Aus")
aus <- st_transform(aus, proj_crs)

#load a basic qld outline, use the extent to crop the aus outline
qld <- st_read(dsn = "input/shapefiles",
               layer = "qld_polygon")
qld <- st_transform(qld, proj_crs)
extent <- extent(qld)
aus_crop <- st_crop(aus, extent)



#plot the main map
mainmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(aus_crop) +
  tm_borders(col = "black") +
  tm_shape(dt_background) +
  tm_polygons(palette = c("khaki4", "lightblue"), alpha = 0.5,
              col = "name", legend.show = T, title = "Dry Tropics Region") +
  tm_shape(dt_background) +
  tm_borders(col = "black") +
  tm_shape(dt_black_fw_zone, is.master = TRUE) +
  tm_polygons(palette = brewer.pal(4, "Accent"),
              col = "MI_ID", title = "Black Freshwater WQO ID") +
  tm_shape(dt_black_fw_zone) + 
  tm_borders(col = "black") + 
  tm_shape(townsville) +
  tm_symbols(col = "red", border.col = "black", size = 0.5) +
  tm_shape(townsville) +
  tm_text(text = "name", size = 0.7, xmod = -1.8, ymod = 0.1, shadow = TRUE) +
  tm_compass(size = 1, position = c(0.92, 0.92)) + 
  tm_scale_bar(position = c(0.01, 0), width = 0.1) +
  tm_logo(file = "input/dt_logo.png", position = c(-0.01, 0.90), height = 1.7) +
  tm_layout(legend.outside = TRUE, legend.title.size = 1, 
            legend.text.size = 0.7, legend.frame = TRUE,
            legend.outside.position = "right",
            legend.position = c(0.02, 1),
            legend.just = c("left", "top"), legend.bg.color = "white",
            bg.color = "grey85", frame = TRUE,
            inner.margins = c(0.01, 0.01, 0.01, 0.01),
            outer.margins = c(0.01, 0.01, 0.01, 0.01))

#view the main map
#mainmap

#get the height and width for the map
main_h <- asp1*100
main_w <- main_h*1.5

#save the main map, inset the second map. Height and width of final image is
#determined using the aspect ratio of the main map
tmap_save(mainmap, 
          filename = "output/technical_report_maps/dt_black_freshwater_wqo.png",
          dpi = 300, height = main_h, width = main_w, units = "mm")


# DT Black Estuary Map at WQO level ---------------------------------------

#read in shapefile data
dt_master <- st_read(dsn = "input/shapefiles", 
                     layer = "dt_master_layer")

#set crs
dt_master <- st_transform(dt_master, proj_crs)

#zoom into the specific zone we care about, and group by sub_zone
dt_black_est_zone <- dt_master %>% 
  filter(zone == "black estuary") %>% 
  group_by(MI_ID, sub_zone, zone, env) %>% 
  summarise(geometry = st_union(geometry))

#group geometries  for our background
temp_land <- dt_master %>% 
  filter(env %in% c("freshwater", "estuarine")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "land", .before = geometry)

temp_water <- dt_master %>% 
  filter(env %in% c("inshore", "offshore")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "water", .before = geometry)

dt_background <- rbind(temp_land, temp_water)
#load a basic Aus outline 
aus <- st_read(dsn = "input/shapefiles",
               layer = "Aus")
aus <- st_transform(aus, proj_crs)

#load a basic qld outline, use the extent to crop the aus outline
qld <- st_read(dsn = "input/shapefiles",
               layer = "qld_polygon")
qld <- st_transform(qld, proj_crs)
extent <- extent(qld)
aus_crop <- st_crop(aus, extent)



#plot the main map
mainmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(aus_crop) +
  tm_borders(col = "black") +
  tm_shape(dt_background) +
  tm_polygons(palette = c("khaki4", "lightblue"), alpha = 0.5,
              col = "name", legend.show = T, title = "Dry Tropics Region") +
  tm_shape(dt_background) +
  tm_borders(col = "black") +
  tm_shape(dt_black_est_zone, is.master = TRUE) +
  tm_polygons(palette = brewer.pal(4, "Accent"),
              col = "MI_ID", title = "Black Estuary WQO ID") +
  tm_shape(dt_black_est_zone) + 
  tm_borders(col = "black") + 
  tm_shape(townsville) +
  tm_symbols(col = "red", border.col = "black", size = 0.5) +
  tm_shape(townsville) +
  tm_text(text = "name", size = 0.7, xmod = -1.8, ymod = 0.1, shadow = TRUE) +
  tm_compass(size = 1, position = c(0.92, 0.92)) + 
  tm_scale_bar(position = c(0.01, 0), width = 0.1) +
  tm_logo(file = "input/dt_logo.png", position = c(-0.01, 0.90), height = 1.7) +
  tm_layout(legend.outside = TRUE, legend.title.size = 1, 
            legend.text.size = 0.7, legend.frame = TRUE,
            legend.outside.position = "right",
            legend.position = c(0.02, 1),
            legend.just = c("left", "top"), legend.bg.color = "white",
            bg.color = "grey85", frame = TRUE,
            inner.margins = c(0.01, 0.01, 0.01, 0.01),
            outer.margins = c(0.01, 0.01, 0.01, 0.01))

#view the main map
#mainmap

#get the height and width for the map
main_h <- asp1*100
main_w <- main_h*1.5

#save the main map, inset the second map. Height and width of final image is
#determined using the aspect ratio of the main map
tmap_save(mainmap, 
          filename = "output/technical_report_maps/dt_black_estuary_wqo.png",
          dpi = 300, height = main_h, width = main_w, units = "mm")


# DT Cleveland Bay Map at WQO level ---------------------------------------

#read in shapefile data
dt_master <- st_read(dsn = "input/shapefiles", 
                     layer = "dt_master_layer")

#set crs
dt_master <- st_transform(dt_master, proj_crs)

#zoom into the specific zone we care about, and group by sub_zone
dt_cleveland_inshore_zone <- dt_master %>% 
  filter(zone == "Cleveland Bay") %>% 
  group_by(MI_ID, sub_zone, zone, env) %>% 
  summarise(geometry = st_union(geometry))

#group geometries  for our background
temp_land <- dt_master %>% 
  filter(env %in% c("freshwater", "estuarine")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "land", .before = geometry)

temp_water <- dt_master %>% 
  filter(env %in% c("inshore", "offshore")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "water", .before = geometry)

dt_background <- rbind(temp_land, temp_water)
#load a basic Aus outline 
aus <- st_read(dsn = "input/shapefiles",
               layer = "Aus")
aus <- st_transform(aus, proj_crs)

#load a basic qld outline, use the extent to crop the aus outline
qld <- st_read(dsn = "input/shapefiles",
               layer = "qld_polygon")
qld <- st_transform(qld, proj_crs)
extent <- extent(qld)
aus_crop <- st_crop(aus, extent)

#plot the main map
mainmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(aus_crop) +
  tm_borders(col = "black") +
  tm_shape(dt_background) +
  tm_polygons(palette = c("khaki4", "lightblue"), alpha = 0.5,
              col = "name", legend.show = T, title = "Dry Tropics Region") +
  tm_shape(dt_background) +
  tm_borders(col = "black") +
  tm_shape(dt_cleveland_inshore_zone, is.master = TRUE) +
  tm_polygons(palette = brewer.pal(4, "Accent"),
              col = "MI_ID", title = "Cleveland Bay WQO ID") +
  tm_shape(dt_cleveland_inshore_zone) + 
  tm_borders(col = "black") + 
  tm_shape(townsville) +
  tm_symbols(col = "red", border.col = "black", size = 0.5) +
  tm_shape(townsville) +
  tm_text(text = "name", size = 0.7, xmod = -1.8, ymod = 0.1, shadow = TRUE) +
  tm_compass(size = 1, position = c(0.92, 0.92)) + 
  tm_scale_bar(position = c(0.01, 0), width = 0.1) +
  tm_logo(file = "input/dt_logo.png", position = c(-0.01, 0.90), height = 1.7) +
  tm_layout(legend.outside = TRUE, legend.title.size = 1, 
            legend.text.size = 0.7, legend.frame = TRUE,
            legend.outside.position = "right",
            legend.position = c(0.02, 1),
            legend.just = c("left", "top"), legend.bg.color = "white",
            bg.color = "grey85", frame = TRUE,
            inner.margins = c(0.01, 0.01, 0.01, 0.01),
            outer.margins = c(0.01, 0.01, 0.01, 0.01))

#view the main map
#mainmap

#get the height and width for the map
main_h <- asp1*100
main_w <- main_h*1.5

#save the main map, inset the second map. Height and width of final image is
#determined using the aspect ratio of the main map
tmap_save(mainmap, 
          filename = "output/technical_report_maps/dt_cleveland_inshore_wqo.png",
          dpi = 300, height = main_h, width = main_w, units = "mm")

# DT Halifax Bay Map at WQO level -----------------------------------------

#read in shapefile data
dt_master <- st_read(dsn = "input/shapefiles", 
                     layer = "dt_master_layer")

#set crs
dt_master <- st_transform(dt_master, proj_crs)

#zoom into the specific zone we care about, and group by sub_zone
dt_halifax_inshore_zone <- dt_master %>% 
  filter(zone == "Halifax Bay") %>% 
  group_by(MI_ID, sub_zone, zone, env) %>% 
  summarise(geometry = st_union(geometry))

#group geometries  for our background
temp_land <- dt_master %>% 
  filter(env %in% c("freshwater", "estuarine")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "land", .before = geometry)

temp_water <- dt_master %>% 
  filter(env %in% c("inshore", "offshore")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "water", .before = geometry)

dt_background <- rbind(temp_land, temp_water)
#load a basic Aus outline 
aus <- st_read(dsn = "input/shapefiles",
               layer = "Aus")
aus <- st_transform(aus, proj_crs)

#load a basic qld outline, use the extent to crop the aus outline
qld <- st_read(dsn = "input/shapefiles",
               layer = "qld_polygon")
qld <- st_transform(qld, proj_crs)
extent <- extent(qld)
aus_crop <- st_crop(aus, extent)

#plot the main map
mainmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(aus_crop) +
  tm_borders(col = "black") +
  tm_shape(dt_background) +
  tm_polygons(palette = c("khaki4", "lightblue"), alpha = 0.5,
              col = "name", legend.show = T, title = "Dry Tropics Region") +
  tm_shape(dt_background) +
  tm_borders(col = "black") +
  tm_shape(dt_halifax_inshore_zone, is.master = TRUE) +
  tm_polygons(palette = brewer.pal(4, "Accent"),
              col = "MI_ID", title = "Halifax Bay WQO ID") +
  tm_shape(dt_halifax_inshore_zone) + 
  tm_borders(col = "black") + 
  tm_shape(townsville) +
  tm_symbols(col = "red", border.col = "black", size = 0.5) +
  tm_shape(townsville) +
  tm_text(text = "name", size = 0.7, xmod = -1.8, ymod = 0.1, shadow = TRUE) +
  tm_compass(size = 1, position = c(0.92, 0.92)) + 
  tm_scale_bar(position = c(0.01, 0), width = 0.1) +
  tm_logo(file = "input/dt_logo.png", position = c(-0.01, 0.90), height = 1.7) +
  tm_layout(legend.outside = TRUE, legend.title.size = 1, 
            legend.text.size = 0.7, legend.frame = TRUE,
            legend.outside.position = "right",
            legend.position = c(0.02, 1),
            legend.just = c("left", "top"), legend.bg.color = "white",
            bg.color = "grey85", frame = TRUE,
            inner.margins = c(0.01, 0.01, 0.01, 0.01),
            outer.margins = c(0.01, 0.01, 0.01, 0.01))

#view the main map
#mainmap

#get the height and width for the map
main_h <- asp1*100
main_w <- main_h*1.5

#save the main map, inset the second map. Height and width of final image is
#determined using the aspect ratio of the main map
tmap_save(mainmap, 
          filename = "output/technical_report_maps/dt_halifax_inshore_wqo.png",
          dpi = 300, height = main_h, width = main_w, units = "mm")
# DT Offshore Map at WQO level --------------------------------------------

#read in shapefile data
dt_master <- st_read(dsn = "input/shapefiles", 
                     layer = "dt_master_layer")

#set crs
dt_master <- st_transform(dt_master, proj_crs)

#zoom into the specific zone we care about, and group by sub_zone
dt_offshore_zone <- dt_master %>% 
  filter(zone == "offshore_zone") %>% 
  group_by(MI_ID, sub_zone, zone, env) %>% 
  summarise(geometry = st_union(geometry))

#group geometries  for our background
temp_land <- dt_master %>% 
  filter(env %in% c("freshwater", "estuarine")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "land", .before = geometry)

temp_water <- dt_master %>% 
  filter(env %in% c("inshore", "offshore")) %>% 
  summarise(geometry = st_union(geometry)) %>% 
  mutate(name = "water", .before = geometry)

dt_background <- rbind(temp_land, temp_water)

#load a basic Aus outline 
aus <- st_read(dsn = "input/shapefiles",
               layer = "Aus")
aus <- st_transform(aus, proj_crs)

#load a basic qld outline, use the extent to crop the aus outline
qld <- st_read(dsn = "input/shapefiles",
               layer = "qld_polygon")
qld <- st_transform(qld, proj_crs)
extent <- extent(qld)
aus_crop <- st_crop(aus, extent)



#plot the main map
mainmap <- tm_shape(aus_crop) +
  tm_polygons(col = "grey50") +
  tm_shape(aus_crop) +
  tm_borders(col = "black") +
  tm_shape(dt_background) +
  tm_polygons(palette = c("khaki4", "lightblue"), alpha = 0.5,
              col = "name", legend.show = T, title = "Dry Tropics Region") +
  tm_shape(dt_background) +
  tm_borders(col = "black") +
  tm_shape(dt_offshore_zone, is.master = TRUE) +
  tm_polygons(palette = brewer.pal(4, "Accent"),
              col = "MI_ID", title = "Offshore WQO ID") +
  tm_shape(dt_offshore_zone) + 
  tm_borders(col = "black") + 
  tm_shape(townsville) +
  tm_symbols(col = "red", border.col = "black", size = 0.5) +
  tm_shape(townsville) +
  tm_text(text = "name", size = 0.7, xmod = -1.8, ymod = 0.1, shadow = TRUE) +
  tm_compass(size = 1, position = c(0.92, 0.92)) + 
  tm_scale_bar(position = c(0.01, 0), width = 0.1) +
  tm_logo(file = "input/dt_logo.png", position = c(-0.01, 0.90), height = 1.7) +
  tm_layout(legend.outside = TRUE, legend.title.size = 1, 
            legend.text.size = 0.7, legend.frame = TRUE,
            legend.outside.position = "right",
            legend.position = c(0.02, 1),
            legend.just = c("left", "top"), legend.bg.color = "white",
            bg.color = "grey85", frame = TRUE,
            inner.margins = c(0.01, 0.01, 0.01, 0.01),
            outer.margins = c(0.01, 0.01, 0.01, 0.01))

#view the main map
#mainmap

#get the height and width for the map
main_h <- asp1*100
main_w <- main_h*1.5

#save the main map, inset the second map. Height and width of final image is
#determined using the aspect ratio of the main map
tmap_save(mainmap, 
          filename = "output/technical_report_maps/dt_offshore_wqo.png",
          dpi = 300, height = main_h, width = main_w, units = "mm")













