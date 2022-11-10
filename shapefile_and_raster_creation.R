#Rainfall and elevation data preparation script.
#This script is currently in progress
#Created: 30/07/2022
#Author: Adam Shand
#Updated: 29/08/2022

# set wd, install and load packages --------------------------------------------

#Basic version of setting working directory correctly. Most likely updated with
#rollout of DIMS
if(file.exists('shapefile_and_raster_creation.R')) {
  setwd(c("../", getwd()))
  message("Directory set to script location, proceed")
} else if (file.exists("src")){
  setwd(getwd())
  message("Directory set to script location, proceed")
} else {
  stop("Directory not set to script location, update directory.")  
}

library(rayshader) #Y
library(raster) #Y
library(tmap) #Y
library(sf) #Y
library(osmdata) #Y
library(av) #Y
library(gifski) #Y
library(leaflet) #Y
library(maptools) #Y
library(rayrender) #Y
library(tidyverse) #Y
library(stringr) #Y
library(rgdal) #M
library(dplyr) #Y

# Set Project CRS and turn of spherical Geometry -------------------------------
#NOTE
#The inshore and offshore zones for the dry tropic region are hand crafted. No
#complete version of them exists online. This pipeline attempts to create each
#shapefile using the most amount of online resources possible - and minimize the
#use of custom shapefiles that may get lost or irreparably damaged.
#For EPP layers:
#https://qldspatial.information.qld.gov.au/catalogue/custom/index.page


#before starting any shapefile work we need to a) set a project crs
proj_crs <- crs("EPSG:4326")

# and b) turn of spherical geometry - it creates overlaps and self intersections
sf_use_s2(FALSE)

# Create Zones and sub zones for land parts of DT ------------------------------
#The first thing I want to do is establish our catchment and sub catchment
#boundaries for the land portion of our region.

#Import the entire Environmental Protection Policy env value zones layer
EPP_water_env_value <- st_read(dsn = "input/shapefiles", 
                               layer = "EPP_Water_Env_Value_Zones_Qld")

#grab everything that has Townsville for its Project_NA. Remove Halifax and 
#Cleveland Bay because we only want land for this part
EPP_water_env_value_crop <- EPP_water_env_value %>% 
  dplyr::filter(PROJECT_NA == "Townsville Region") %>% 
  dplyr::filter(ENV_VALUE_ != "Halifax & Cleveland Bay")

#clean up text, I think these indicate new lines in the original names
EPP_water_env_value_crop$ENV_VALUE_ <- gsub("\r\n", "", as.character(
  EPP_water_env_value_crop$ENV_VALUE_))

#create a custom function. This function will summarize the value, basin name
#and shape area based on the ENV_VALUE_ names you give it. The output then needs
#to have its geometry reattached. This is done by creating a second df using the
#same filter criteria and summarizing the geometry, then putting the two together
my_func <- function(df, name_list){
  df1 <- df %>% 
    dplyr::filter(str_detect(ENV_VALUE_, name_list)) %>% 
    st_drop_geometry() %>%
    summarise_at(vars(ENV_VALUE_), 
                 funs(ENV_VALUE_ = paste(unique(ENV_VALUE_), collapse = ", "), 
                      BASIN_NAME = first(BASIN_NAME),
                      SHAPE_Area = sum(SHAPE_Area)))
  df2 <- df %>% 
    dplyr::filter(str_detect(ENV_VALUE_, name_list)) %>% 
    summarise(geometry = st_union(geometry))
  cbind(df1, df2)
}

#create a list that contain the names I want to combine, groupings are:
list <- c("Two|Christmas", "Deep Creek|Althaus|Healy", "Alick|Black R|Log C|Canal|Alice",
          "Town C|Pall", "Middle B|(lower)", "Round|Plum|Six|One|Toon",
          "Anthill|Slippery|Alligator|Killymoon|Crocodile|Cape",
          "below dam|Mt Stuart|Sachs", "Stuart C|State|Sandfly|Whites",
          "Bay|Retreat|China|Duck|Ned|Butlers|Gustav|Petersen|Magnetic|Gorge|Endeavour")

#these groupings were decided by inspecting the layer in QGIS and matching sub
#catchments that were a) too small to warrant their own section, and/or b)
#similar enough to the surround catchments. This is a subjective process and 
#will most likely be changed as time goes on.

#next we want to run the function on each of the name groups in the list. To 
#make this easier we use a simple for loop.

#set up an empty df
temp_df <- data.frame()

#run a for loop that applies the custom function to each element of our list.
#this uses the index of the loop to get a new element from the list each loop.
#we bind this onto our temp df for each loop. When we get to the final loop (we
#know its last loop if i = list length, we convert the temp df into our final
#sf object. We also clean up the temp df and 'i'.
for (i in 1:length(list)) {
  temp_df <- rbind(temp_df, my_func(EPP_water_env_value_crop, list[i]))
    if (i == length(list)) {
       output <- st_as_sf(temp_df)
       rm(temp_df, i)
    }
  }

#clean up, we no longer need the original EPP data
rm(EPP_water_env_value)

#the next thing we need to do is attach everything from the original df that 
#didn't need to be merged.

#take the list created before and collapse it into a single string
list <- paste(list, collapse = "|")

#create a df that is everything that isn't in our list.
temp <- EPP_water_env_value_crop %>% 
  dplyr::filter(!str_detect(ENV_VALUE_, list)) %>% 
  select(ENV_VALUE_, BASIN_NAME, SHAPE_Area)

#bind the two together and clean up
b_r_sub_zone <- rbind(output, temp)
rm(output, temp, list)

#add a crs to the sf
b_r_sub_zone <- st_transform(b_r_sub_zone, crs = proj_crs)

#plot to double check things look how we want
tm_shape(b_r_sub_zone) +
  tm_polygons()

#some of the ENV_value col is a bit too big to work with effectively. this 
#column is renamed as 'area_contains' and new names assigned to a column called
#'sub_zone'

list <- c("Sleeper Log Creek", "Althaus Creek", "Black River", "Town Common",
          "Lower Bohle River", "Upper Ross River", "Alligator & Crocodile Creek",
          "Lower Ross River", "Townsville State Development Area", 
          "Magnetic Island", "Station Creek", "Rollingstone Creek", "Ross Creek",
          "Bluewater Creek", "Lorna, Ollera, Scrubby & Hencamp Creeks",
          "Surveyors & Wild Boar Creeks", "Crystal Creek", "Leichhardt Creek",
          "Camp Oven & Cassowary Creeks", "Upper Bohle River", "Louisa Creek",
          "Ross River Dam", "Saltwater Creek")

#clean up the df a bit
b_r_sub_zone <- b_r_sub_zone %>% 
  rename(contains = ENV_VALUE_,
         zone = BASIN_NAME,
         area = SHAPE_Area) %>% 
  mutate(sub_zone = list, .after = contains) %>% 
  mutate(zone = case_when(
    str_detect(zone, "Black") ~ "black basin",
    str_detect(zone, "Ross") ~ "ross basin"))

#next we are looking to add the fresh or estuary designation
b_r_sub_zone <- b_r_sub_zone %>% 
  dplyr::select(zone, sub_zone, geometry) 

#have a quick look
tm_shape(b_r_sub_zone) +
  tm_polygons(col = "zone")

#Import the entire Environmental Protection Policy water types layer
EPP_water_types <- st_read(dsn = "input/shapefiles",
                           layer = "EPP_Water_water_types_Qld")

#set the crs
EPP_water_types <- st_transform(EPP_water_types, proj_crs)

#crop and filter to the desired region to increase processing speeds
EPP_water_types_crop <- st_crop(EPP_water_types, b_r_sub_zone) %>% 
  filter(PROJECT_NA %in% c("Townsville Region"))

#get the main water types using a partial match to pick up the variants
estuary <- EPP_water_types_crop %>% 
  filter(str_detect(WATER_TYPE, "estuary"))

freshwater <- EPP_water_types_crop %>% 
  filter(!str_detect(WATER_TYPE, "coastal|estuary"))
rm(EPP_water_types, EPP_water_types_crop)

#combine all the polygons into one big polygon and return as simple feature.
#this will then be used to assign fresh or estuary.
#need install.packages("nngeo") for remove holes func
fresh_union <- freshwater %>% 
  st_union(by_feature = FALSE) %>%  
  st_combine() %>%
  nngeo::st_remove_holes() %>% 
  st_sf()

estuary_union <- estuary %>% 
  st_union(by_feature = FALSE) %>%
  st_combine() %>% 
  nngeo::st_remove_holes() %>% 
  st_sf()

#by returning only the intersection of these two sf's we return only the fresh
#water sections of each of the sub basins - while retaining sub basin boundaries
#then if we group by sub_zone, and union geometry each sub zone only has one 
#associated row and one geometry
black_ross_fresh <- st_intersection(b_r_sub_zone, fresh_union) %>% 
  mutate(env = "freshwater") %>% 
  group_by(sub_zone, zone, env) %>% 
  st_collection_extract("POLYGON") %>% 
  summarise(geometry = st_union(geometry))
rm(freshwater, fresh_union)

#do the same for estuarine sections
black_ross_estuary <- st_intersection(b_r_sub_zone, estuary_union) %>% 
  mutate(env = "estuarine") %>% 
  mutate(zone = case_when(
    str_detect(zone, "black") ~ "black estuary",
    str_detect(zone, "ross") ~ "ross estuary")) %>% 
  group_by(sub_zone, zone, env) %>% 
  st_collection_extract("POLYGON") %>% 
  summarise(geometry = st_union(geometry))
rm(estuary, estuary_union)

#visualise these different intersections and groupings
tm_shape(black_ross_estuary) +
  tm_polygons(col = "sub_zone")

#combine the two back into the main df

b_r_sub_zone <- rbind(black_ross_fresh, black_ross_estuary)
rm(black_ross_estuary, black_ross_fresh)
#and save the new catchment and subcatchment shapefile. Note that the longer
#names in area_contains will be cut off.
#We now have our land area for the region.
#dsn designated the folder, layer designates the file name. Don't specify the 
#file type - there are multiple files and types that need to be read at once.
st_write(b_r_sub_zone, "raw_data/custom_shapefiles/black_ross_subcatchments.shp",
         delete_layer = TRUE)

# Create zones and sub zones for water parts of DT --------------------------------

#read the gbr marine water types shapefile. GBRMPA has the original df if needed
gbr_mar_water_type <- st_read(dsn = "raw_data/GBRMPA Marine Water Types",
                              layer = "MarineWaterBodiesV2_4")

#check and set crs
crs(gbr_mar_water_type)
gbr_mar_water_type <- st_transform(gbr_mar_water_type, proj_crs)

#raw numbers for the Black/Halifax bay coastal boundary and Ross/Cleveland bay
#coastal boundary. Note that this is a hand drawn boundary - no online backup.
#Note that first and last lat and long coordinates match to make a circle
lon_h <- c(147.3247, 146.6656, 146.6656, 146.2960, 146.2960, 146.4415, 146.4429, 
           146.9999, 147.3247)
lat_h <- c(-17.6958, -19.2108, -19.3867, -18.9512, -18.8976, -18.8976, -18.3898,
           -17.4958, -17.6958) 

#ross/cleveland
lon_c <- c(146.6656, 147.3247, 148.0303, 147.6438, 147.0198, 147.0293, 147.0057, 
           147.0057, 146.6656, 146.6656)
lat_c <- c(-19.2108, -17.6958, -18.1305, -18.7596, -19.1927, -19.2088, -19.3004, 
           -19.3867, -19.3867, -19.2108)

#concatenate long and lat, make it a matrix, create a polygon by providing the
#matrix as a list, turn polygon into a simple feature class
halifax_bay <- st_sfc(st_polygon(list(matrix(c(lon_h, lat_h),,2))))
cleveland_bay <- st_sfc(st_polygon(list(matrix(c(lon_c, lat_c),,2))))

#create a simple feature by concatenating the Halifax and Cleveland polygons. 
#Assign the crs, rename the column based on index. Add a zone column before the 
#geometry column
dt_marine_rough <- st_sf(c(halifax_bay, cleveland_bay), crs = proj_crs) %>% 
  rename(geometry = 1) %>% 
  mutate(zone = c("Halifax Bay", "Cleveland Bay"), .before = "geometry")
rm(halifax_bay, cleveland_bay)

#plot to check everything worked. Should see two rough polygons sharing an edge
tm_shape(dt_marine_rough) +
  tm_borders()

#save this polygon. It is critical that this polygon or the numeric equivalent
#is never lost as there is no online equivalent.
st_write(dt_marine_rough, "raw_data/custom_shapefiles/dt_custom_rough_outline.shp", 
         delete_layer = TRUE)

#use the rough polygons to intersect over the gbr_water_types shape. This will
#assign each zone of the rough polygon a subzone
dt_mar_water_type <- st_intersection(gbr_mar_water_type, dt_marine_rough)
rm(gbr_mar_water_type, dt_marine_rough)

tm_shape(dt_mar_water_type) +
  tm_borders()

#create a shapefile of only the two offshore zones and merge them together. Add
#back the key col names that we want
temp1 <- dt_mar_water_type %>% 
  filter(MarineWate %in% "Offshore") %>% 
  summarise() %>%
  mutate(sub_zone = "offshore_sub_zone", 
         zone = "offshore_zone",
         env = "offshore", .before = geometry)

#select everything but the offshore zone. Edit col names to only have key ones
temp2 <- dt_mar_water_type %>% 
  filter(!MarineWate %in% "Offshore") %>% 
  dplyr::select(MarineWate, zone) %>% 
  rename(sub_zone = MarineWate) %>% 
  mutate(env = "inshore", .before = geometry)

#combine the two temporary shapes back into the main group. Now with a merged
#offshore zone
dt_mar_water_type <- rbind(temp1, temp2)
rm(temp1, temp2)

#group all of our geometries back up to remove unnecessary rows
dt_mar_water_type <- dt_mar_water_type %>%
  group_by(sub_zone, zone, env) %>% 
  summarize(geometry = st_union(geometry))

#plot to check how things look
tm_shape(dt_mar_water_type) +
  tm_polygons(col = "sub_zone")

#now we need to do is clean up the coastline so it fits in with the rest of the 
#shapefiles we are using.

#get a union of the shapefile
water_type_union <- dt_mar_water_type %>% 
  st_union(by_feature = FALSE) %>%  
  st_combine() %>%
  nngeo::st_remove_holes() %>% 
  st_sf() 

#edit the rough polygon to just get a section near the coast
lat_h <- c(-19.1259, lat_h[c(2,3,4,5)], -19.1259)
lon_h <- c(146.7025, lon_h[c(2,3,4,5)], 146.7025)
lat_c <- c(-19.1259,lat_c[c(5,6,7,8,9,10)], -19.1259)
lon_c <- c(146.7025,lon_c[c(5,6,7,8,9,10)], 146.7025)
poly_temp1 <- st_sfc(st_polygon(list(matrix(c(lon_h, lat_h),,2))))
poly_temp2 <- st_sfc(st_polygon(list(matrix(c(lon_c, lat_c),,2))))
dt_coast_rough <- st_sf(c(poly_temp1, poly_temp2), crs = proj_crs) %>% 
  rename(geometry = 1) %>% 
  mutate(zone = c("Halifax Bay", "Cleveland Bay"), .before = "geometry")
rm(lat_h, lon_h, poly_temp1, lat_c, lon_c, poly_temp2)

#plot the rough coast over our previous shapefile to get an idea how it looks
tm_shape(dt_mar_water_type) +
  tm_borders() +
  tm_shape(dt_coast_rough) +
  tm_borders(col = "red")

#create a coast buffer by taking the difference between our rough coast poly 
#and the water type union shape. Give it the required columns + details
coast_buffer <- st_difference(dt_coast_rough, water_type_union) %>% 
  mutate(sub_zone = "Enclosed Coastal", env = "inshore",.before = zone)
rm(dt_coast_rough, water_type_union)

#join the coast buffer and the full marine shape back together
dt_mar_water_type <- rbind(dt_mar_water_type, coast_buffer)
rm(coast_buffer)

#check how it looks
tm_shape(dt_mar_water_type) +
  tm_polygons()

#group geometries to create  single multipolygons for each sub_zone. This will
#also create a buffer for the enclosed coastal sub_zone. 
dt_mar_water_type <- dt_mar_water_type %>% 
  group_by(sub_zone, zone, env) %>% 
  summarise(geometry = st_union(geometry))

#check how it looks
tm_shape(dt_mar_water_type) +
  tm_polygons()

#check things are still valid
st_is_valid(dt_mar_water_type)

#what this did was to remove the coastline from the sf, while still keeping all
#of the associated information for the enclosed/open coastal boundaries etc.
#we can then rebuild the coastline using our land sf so they fit nicely

#now the marine side is sorted we need to cut a perimeter for the coast.

#read in the shapefile we will use for our coastline. This sf was created 
#earlier, just above, as well.
b_r_sub_zone <- st_read(dsn = "raw_data/custom_shapefiles",
                      layer = "black_ross_subcatchments")

#set the crs
b_r_sub_zone <- st_transform(b_r_sub_zone, proj_crs)

#create a union to get a clean coastline cut
b_r_union <- b_r_sub_zone %>% 
  st_union(by_feature = FALSE) %>%  
  st_combine() %>%
  nngeo::st_remove_holes() %>% 
  st_sf()

#plot to see how it looks - note the overlap around coastlines.
tm_shape(b_r_union) +
  tm_borders() +
  tm_shape(dt_mar_water_type) +
  tm_borders()

#return all of x that doesn't overlap with y and grab only the polygons as 
#output. This creates our new coastline
dt_mar_water_type <- st_difference(dt_mar_water_type, b_r_union)

#plot to see how things look now
tm_shape(b_r_union) +
  tm_borders() +
  tm_shape(dt_mar_water_type) +
  tm_polygons(col = "sub_zone")
rm(b_r_union)

#save our now completed dt_marine layer. This is about as good as I can get at
#the moment. Can revisit when skills are better
st_write(dt_mar_water_type, "raw_data/custom_shapefiles/dt_marine_environments.shp", 
         delete_layer = TRUE)

# Combine land and water parts of DT -------------------------------------------

#combine the two environments together to form one core layer for the dt
#region. If only a specific variable is needed it can always been pulled out
#using dplyr::select later.
dt_all_environments <- rbind(dt_mar_water_type, b_r_sub_zone)
rm(dt_mar_water_type, b_r_sub_zone)

#visualise by colouring by different variables (sub_zone, zone, environment).
#can also facet to look at multiple variables
tm_shape(dt_all_environments) +
  tm_polygons(col = c("zone"))

#save our new all environments layer to our custom shapefiles folder
st_write(dt_all_environments, "raw_data/custom_shapefiles/dt_all_environments.shp",
         delete_layer = TRUE)

# Add Management Intent to DT Region -------------------------------------------
#we have all the major outlines in place. Now we need to introduce the EPP
#management intent layer (the HEV, MD, SD zonation).

#read in the entire Environmental Protection Policy management intent layer
EPP_management_intent <- st_read(dsn = "input/shapefiles", 
                                 layer = "EPP_Water_management_intent_Qld")

#set the crs
EPP_management_intent <- st_transform(EPP_management_intent, proj_crs)

#first we will mask the layer using a merge of our full dt shape to get intent 
#for the whole area.

#merge our final dt sf to get the boundary
dt_boundary <- dt_all_environments %>% 
  st_union(by_feature = FALSE) %>%
  st_combine() %>% 
  nngeo::st_remove_holes() %>% 
  st_sf()

#get intersection. return all of x that intersects y
dt_master <- st_intersection(EPP_management_intent, dt_boundary) %>% 
  select(geometry, MI_TYPE, MI_ID, SCHEDULE) %>% st_collection_extract("POLYGON")
rm(EPP_management_intent)

#have a look. Note that there are some missing spots around the offshore area
tm_shape(dt_master) +
  tm_polygons()

#to fill in the missing areas we need to get creative.
#first we make a blank box around the whole area.
temp_cord <- c(-19.8145, -17.1727, 145.7625, 148.2558)
temp_lat = c(temp_cord[1], temp_cord[2], temp_cord[2], temp_cord[1], temp_cord[1])
temp_lon = c(temp_cord[3], temp_cord[3], temp_cord[4], temp_cord[4], temp_cord[3])
temp_box <- st_sfc(st_polygon(list(matrix(c(temp_lon, temp_lat),,2))))

#clean the box up a bit and add some vars that will be needed to use rbind
temp_box <- st_sf(temp_box, crs = proj_crs) %>% 
  rename(geometry = 1) %>% 
  mutate(SCHEDULE = "dt_box", MI_TYPE = "NA", MI_ID = "NA",
         .before = "geometry")

#then we merge the management intent polygons so we have a border for what we 
#already have within the area of the box
temp_merge <- dt_master %>% 
  st_union(by_feature = FALSE) %>%
  st_combine() %>% 
  nngeo::st_remove_holes() %>% 
  st_sf()

#then we return all of x that isn't in y
temp_dif <- st_difference(temp_box, temp_merge)

#plot to visualise what that means
tm_shape(temp_dif) +
  tm_polygons()

#and we bind this back onto the management intent shape
temp_bind <- rbind(temp_dif, dt_master)

#use the dt boundary to cut out what we want from this
dt_master <- st_intersection(temp_bind, dt_boundary) %>% 
  st_collection_extract("POLYGON")

#clean up temporary stuff
rm(temp_merge, temp_cord, temp_lat, temp_lon, temp_box, temp_dif, temp_bind)

#plot to check
tm_shape(dt_master) +
  tm_polygons(col = "MI_ID")

#change MI_ID to MI_TYPE if MI_ID is NA (gets rid of the false NA values)
dt_master <- dt_master %>% 
  mutate(MI_ID = case_when(
    MI_ID == "NA" ~ MI_TYPE,
    TRUE ~ MI_ID))

#now we can group by MI_ID so that each ID only has one associated row. We can 
#drop the MI_TYPE var as that is now encapsulated by ID. And we can drop the 
#schedule var as location will be provided by our other layer. 
dt_master <- dt_master %>% 
  group_by(MI_ID) %>% 
  summarise()

#take the intersection of our new management intent layer and dt overall layer
dt_master <- st_intersection(dt_all_environments, dt_master) %>% 
  st_collection_extract("POLYGON")
rm(dt_all_environments)

#that worked, but also created >2000 rows. We need to stitch all the MI_ID 
#geometries back together
dt_master <- dt_master %>% 
  group_by(MI_ID, sub_zone, zone, env) %>% 
  summarise(geometry = st_union(geometry))

#we now have a fully completed shapefile, down to the sub_zone, that has the 
#correct management intent polygons overlapped
tm_shape(dt_master) +
   tm_polygons(col = "MI_ID")

tm_shape(dt_master) +
  tm_polygons(col = "sub_zone")

tm_shape(dt_master) +
  tm_polygons(col = "zone")

tm_shape(dt_master) +
  tm_polygons(col = "env")

#unfortunately, if we want to present our map without the borders at the MI_ID
#level we need to drop the column by grouping up at a higher level. e.g.
sub_zone_lvl <- dt_master %>% 
  group_by(sub_zone, zone, env) %>% 
  summarise(geometry = st_union(geometry))

zone_lvl <- dt_master %>% 
  group_by(zone, env) %>% 
  summarise(geometry = st_union(geometry))

environment_lvl <- dt_master %>% 
  group_by(env) %>% 
  summarise(geometry = st_union(geometry))

#additionally, if we want to only select a specific sub_zone, zone, environment
#We do this
black_zone <- dt_master %>% 
  filter(zone == "black basin") %>% 
  summarise(geometry = st_union(geometry))

#swap each of the layers out to see what i mean
tm_shape(black_zone) +
  tm_polygons(col = "MI_ID")

#clean up these layers as they are only demonstrations
rm(sub_zone_lvl, zone_lvl, environment_lvl, black_zone)

#save our new management intent layer. Note that this actually has everything 
#we will need in it, and therefore im calling it the master layer
st_write(dt_master, "input/shapefiles/dt_master_layer.shp",
         delete_layer = TRUE)


# DIMS and Landuse practice ----------------------------------------------------
#our static layers should all be done. Now we need to work on making sure that
#the DIMS scores can come in a be appropriately assigned.

#below is an old example. I think i can do better now

#add the dummy DIMs grade

inshore_waters <- left_join(inshore_waters, inshore_grades, by = "subbasin_subzone")
inshore_waters$grade[is.na(inshore_waters$grade)] <- "NA"

# Create Land use map layer for Dry Tropics Region -----------------------------

#use st_layers to get all the layers from the gdb
landuse_layers <- st_layers(dsn = "raw_data/QLD_LANDUSE_June_2019/QLD_LANDUSE_June_2019.gdb")

#view the gdb to see what layers are available
landuse_layers

#pick the layer we want and now we can get it as a simple feature
landuse_current <- st_read("raw_data/QLD_LANDUSE_June_2019/QLD_LANDUSE_June_2019.gdb",
                           layer = "QLD_LANDUSE_CURRENT_X")

#currently not working. I think it has something to do with spherical geometry
#look up "Well-known text" and read this link:
#https://gdal.org/programs/ogr2ogr.html

#gdb brings in sf with the geometry column labeled "Shape". Update this. Note
#have to use special st_geom func as its a special sort of column
st_geometry(landuse_current) <- "geometry"

#update the crs
landuse_current <- st_transform(landuse_current, proj_crs)

#this is a huge file so lets crop it down immediately
dry_tropics_full <- c(-19.8145, -17.1727, 145.4625, 148.2558)
lat_range = c(dry_tropics_full[1],dry_tropics_full[2])
long_range = c(dry_tropics_full[3],dry_tropics_full[4])
source("src/convert_coords.R")
location_extent <- extent(convert_coords(lat = lat_range, 
                                         long = long_range,
                                         to = crs(proj_crs)))

landuse_current <- st_crop(landuse_current, location_extent)




#crop to the DT region, this is a huge data set that tanks processing

#read in dt master
dt_master <- st_read(dsn = "input/shapefiles",
                     layer = "dt_master_layer")

#union everything and remove holes to get the outline only
dt_border <- dt_master %>% 
  st_union(by_feature = FALSE) %>% 
  nngeo::st_remove_holes() %>% 
  st_sf()

#take the intersection of the land use and the dt border
dt_landuse <- st_intersection(landuse_current, dt_border)

landuse_c

tm_shape(landuse_current) +
  tm_polygons()

crs(landuse_current)
crs(proj_crs)
