
#mapping
library(terra)
library(sf)
library(tmap)

#extra utils
library(glue)
library(reactable)
library(tidyverse)
library(openxlsx2)


#assume crs is set by the quarto doc calling this function
#proj_crs <- "EPSG:7844"

#read in basins data
basins <- sf::st_read(dsn = "data/shapefiles/Drainage_basins.shp")

#select northern three basins and combine into one large multipolygon
n3_basins <- basins |> 
  dplyr::filter(BASIN_NAME %in% c("Ross", "Black", "Don", "Proserpine", "O'Connell", "Pioneer", 
                                  "Plane", "Daintree", "Mossman", "Barron", "Johnstone", "Tully", 
                                  "Murray", "Herbert")) |> sf::st_union()

#get path to layers
path <- "data/raw/Regional_Ecosystem_Geopackage_Files/"

#get list of files in the folder without their extension
file_list <- tools::file_path_sans_ext(list.files(path))

#for each file in list
for (i in 1:length(file_list)){

  #read in the regional ecosystem layer
  re_layer <- st_read(dsn = glue("{path}{file_list[i]}.gpkg"))
  
  #filter for row with relevant RE's
  #re_layer <- re_layer |> filter(str_detect(RE, c("7.\\d.\\d|8.\\d.\\d|11.\\d.\\d")))
  
  #transform the layer
  re_layer <- st_transform(re_layer, proj_crs)
  
  #create a T F list of polygons that intersect the n3 basins
  intersects <- lengths(sf::st_intersects(re_layer, n3_basins)) > 0
  
  #select only rows with T for intersection
  re_layer <- re_layer |> dplyr::mutate(within = intersects) |> dplyr::filter(within == T)
  
  #save the file 
  sf::st_write(re_layer, dsn = glue("data/regional_ecosystems/{file_list[i]}_cropped.gpkg"),
               delete_dsn = T)
}


