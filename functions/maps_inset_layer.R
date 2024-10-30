#inputs: 
#supplied_sf = REQUIRED. The main sf object that will define the area of interest
#backdrop = REQUIRED. The "backdrop" aka wider region that provides context to where the main sf object is
#aspect = REQUIRED. The aspect ratio of the inset map (Height and Width). Note this should match that of the aspect used over in the main map

maps_inset_layer <- function(supplied_sf, background, aspect){
  
  #create a vector of package dependencies
  package_vec <- c("tmap", "grid", "tidyverse", "sf")

  #apply the function "require" to the vector of packages to install and load dependencies
  lapply(package_vec, require, character.only = T)
  
  #turn off spherical geometry
  sf_use_s2(F)
  
  #create a bounding box of the supplied_sf then convert it to a sfc (simple feature collection) object
  sfc_bbox <- st_as_sfc(st_bbox(supplied_sf))
   
  #read in qld outlines data from the gisaimsr package, filter for land and islands, update crs
  qld <- get(data("gbr_feat", package = "gisaimsr")) |> filter(FEAT_NAME %in% c("Mainland", "Island")) |> 
    st_transform("EPSG:7844")
  
  #qld <- st_read(here("data/n3_prep_region-builder/qld_boundary.gpkg")) |> 
   # name_cleaning()
  
  #create the map that will be put into the viewport
  inset_map <- tm_shape(qld) +
    tm_polygons(col = "grey80", border.col = "black") +
    tm_shape(background, is.master = T) +
    tm_polygons(col = "grey90", border.col = "black") +
    tm_shape(sfc_bbox) +
    tm_borders(lwd = 2, col = "red") +
    tm_layout(asp = aspect) 
  
  #figure out where to place the view port
  inset_viewport <- viewport(x = 1, y = 0.97, width = 0.2, height = aspect * 0.2, just = c("right", "top"))
  
  #assign the inset map and view port to the global environment
  assign("inset_map", inset_map, envir = globalenv())
  assign("inset_viewport", inset_viewport, envir = globalenv())
    
  message("\nThe variables 'inset_map' and 'inset_viewport' were assigned to the global environment to use for an inset map.\n")

}
