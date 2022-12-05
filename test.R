
#mapping
library(terra)
library(sf)
library(tmap)

#extra utils
library(glue)
library(reactable)
library(tidyverse)
library(openxlsx2)


#read in regional ecosystem data
re_remnant <- st_read(dsn = "data/regional_ecosystems/re_remnant.gpkg")
re_p_clear <- st_read(dsn = "data/regional_ecosystems/re_pre_clearing.gpkg")


#set the crs
proj_crs <- "EPSG:4283"

#get path to geodatabase
path <- "data/raw/historic_re_layers_v12_2/Regional_Ecosystem_v12_2_geo.gdb"

#get list of layers in the geodatabase
layers <- st_layers(dsn = path)

#for each item in the list
for (i in 1:length(layers$name)){
  
  #load the layer
  loaded_layer <- st_read(path, layer = layers$name[i])
  
  #transform the crs to GDA2020 (the new aus crs)
  #loaded_layer <- st_transform(loaded_layer, proj_crs)
  
  #filter for row with relevant RE's
  #loaded_layer <- loaded_layer |> filter(str_detect(RE, c("7.\\d.\\d|8.\\d.\\d|11.\\d.\\d")))
  
  #create a T F list of polygons that intersect the n3 basins
  intersects <- lengths(sf::st_intersects(loaded_layer, n3_basins)) > 0
  
  #select only rows with T for intersection
  loaded_layer <- data |> dplyr::mutate(within = intersects) |> dplyr::filter(within == T)
  
  #save the file as a geopackage (this just makes the next steps easier)
  st_write(loaded_layer, dsn = glue("{(layers$name)[i]}.gpkg"))
  
}



test2 <- st_read(dsn = "data/raw/historic_re_layers_v12_2/re_remnant_2019_v12_2.gpkg")



list_of_features[[1]] <- st_transform(list_of_features[[1]], proj_crs)

#save
st_write(list_of_features[[1]], dsn = "data/raw/historic_re_layers_v12_2/test.gpkg")



#create a T F list of polygons that intersect the n3 basins
intersects <- lengths(sf::st_intersects(list_of_features[[1]], n3_basins)) > 0
