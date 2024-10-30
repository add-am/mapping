#inputs: 
#supplied_sf = the main sf object that this base map will be the background for
#regi = the variable used to define the region(s)
#enviro =the variable used to define the environment(s)
#bz = the variable used to define the basin or zone(s)
#sub_bz = the variable used to define the sub basin or sub zone(s)
#strm_ord = the variable used to define the stream order(s)
#wat_areas = T/F does the user want to include water polygons (lakes etc)
#colour = T/F does the user want to colour the background polygons?

report_base_map <- function(supplied_sf = NA, regi = NA, enviro = NA, bz = NA, sub_bz = NA, water = T, strm_ord = NA, wat_areas = T, colour = T){
  
  #create a vector of package dependencies
  package_vec <- c("tmap", "grid", "tidyverse", "glue", "sf", "here", "RColorBrewer")

  #apply the function "require" to the vector of packages to install and load dependencies
  lapply(package_vec, require, character.only = T)
  
  #turn off spherical geometry
  sf_use_s2(F)
  
  #for some reason (im not smart enough to know why, if user gives these as NA they dont actually come through as NA) so we need to check for this
  if (!exists("regi") || is.na(regi)){regi <- NA}
  if (!exists("enviro") || is.na(enviro)){enviro <- NA}
  if (!exists("bz") || is.na(bz)){bz <- NA}
  if (!exists("sub_bz") || is.na(sub_bz)){sub_bz <- NA}
  if (!exists("strm_ord") || is.na(strm_ord)){strm_ord <- NA}

  #load the n3_region_mapping and n3_watercourse_mapping datasets/check if they were already loaded
  if (!exists("n3_region_mapping")) {n3_region_mapping <- st_read(here("data/n3_prep_region-builder/n3_region.gpkg"))} 
  if (water){if (!exists("n3_watercourse_mapping")) {n3_watercourse_mapping <- st_read(here("data/n3_prep_watercourse-builder/n3_watercourse.gpkg"))}}
  
  #put them into the global environment, so if this function gets used in a loop it doesn't reload the datasets each loop
  assign("n3_region_mapping", n3_region_mapping, envir = globalenv())
  if (water){assign("n3_watercourse_mapping", n3_watercourse_mapping, envir = globalenv())}
  
  cat("\nThe variables 'n3_region_mapping' and 'n3_watercourse_mapping' were assigned to the global environment to enhance function speed within loops.")
  
  #combine filterable variables into a list
  filt_vars <- list(regi = regi, enviro = enviro, bz = bz, sub_bz = sub_bz, strm_ord = strm_ord)

  #force each filterable variable to capitals
  filt_vars <- purrr::imap(filt_vars, str_to_title)
  
  #create a custom error message to help explain the issue
  back_to_num <- function(expr){
    tryCatch(expr,
             warning = function(w){
               stop(glue("{names(filt_vars[5])} must be a numeric variable"))
             })
  }
  
  #turn stream order back to number
  filt_vars[[5]] <- back_to_num(as.numeric(filt_vars[[5]]))
  
  #check each of the filterable variables to help the user
  if (all(!all(filt_vars[[1]] %in% n3_region_mapping$region) & !is.na(filt_vars[[1]]))){
    stop(glue("\nAt least one filter supplied to the '{names(filt_vars[1])}' variable does not exist in the spatial file. Options available are: 
               {paste(unique(n3_region_mapping$region), collapse = ', ')}\n"))
  }
  if (all(!all(filt_vars[[2]] %in% n3_region_mapping$environment) & !is.na(filt_vars[[2]]))){
    stop(glue("\nAt least one filter supplied to the '{names(filt_vars[2])}' variable does not exist in the spatial file. Options available are: 
               {paste(unique(n3_region_mapping$environment), collapse = ', ')}\n"))
  }
  if (all(!all(filt_vars[[3]] %in% n3_region_mapping$basin_or_zone) & !is.na(filt_vars[[3]]))){
    stop(glue("\nAt least one filter supplied to the '{names(filt_vars[3])}' variable does not exist in the spatial file. Options available are: 
               {paste(unique(n3_region_mapping$basin_or_zone), collapse = ', ')}\n"))
  }
  if (all(!all(filt_vars[[4]] %in% n3_region_mapping$sub_basin_or_sub_zone) & !is.na(filt_vars[[4]]))){
    stop(glue("\nAt least one filter supplied to the '{names(filt_vars[4])}' variable does not exist in the spatial file. Options available are: 
               {paste(unique(n3_region_mapping$sub_basin_or_sub_zone), collapse = ', ')}\n"))
  }
  #check each of the filterable variables to help the user
  if (all(!any(filt_vars[[5]] %in% n3_watercourse_mapping$stream_order) & !is.na(filt_vars[[5]]))){
    stop(glue("\nAll filters supplied to the '{names(filt_vars[5])}' variable do not exist in the spatial file. Options available are: 
               {paste(unique(n3_watercourse_mapping$stream_order), collapse = ', ')}\n"))
  }

  #if any of the region, environment, basin_or_zone, sub_basin_or_sub_zone, variables are listed, filter the data
  #note these cant be combined into "else if" because each statement is independent of the previous one
  test <- n3_region_mapping |> 
    filter(if (!is.na(filt_vars[4])) {sub_basin_or_sub_zone %in% filt_vars[[4]]} #filter any sub basin/zone
              else {sub_basin_or_sub_zone %in% unique(n3_region_mapping$sub_basin_or_sub_zone)}, #or dont
           if (!is.na(filt_vars[3])) {basin_or_zone %in% filt_vars[[3]]} #filter any basin/zone
              else {basin_or_zone %in% unique(n3_region_mapping$basin_or_zone)}, #or dont
           if (!is.na(filt_vars[2])) {environment %in% filt_vars[[2]]} #filter any environment
              else {environment %in% unique(n3_region_mapping$environment)}, #or dont
           if (!is.na(filt_vars[1])) {region %in% filt_vars[[1]]} #filter any region
              else {region %in% unique(n3_region_mapping$region)}) #or dont
  
  #figure out the asp of the focus area and save it back to main
  xy <- st_bbox(test)
  base_asp <- (xy$ymax - xy$ymin)/(xy$xmax - xy$xmin)
  assign("base_asp", base_asp, envir = globalenv())
  
  cat("\nThe base aspect ration has been assigned to the global environment with the name 'base_asp'.\n")
  
  #create a second dataset of the region for the targeted area (map background is never smaller than region)
  background <- n3_region_mapping |> 
    filter(region == unique(test$region))
  
  if (water){
    test_2 <- n3_watercourse_mapping |> 
      filter(if (!is.na(filt_vars[4])) {sub_basin_or_sub_zone %in% filt_vars[[4]]} #filter any sub basin/zone
             else {sub_basin_or_sub_zone %in% unique(n3_watercourse_mapping$sub_basin_or_sub_zone)}, #or dont
             if (!is.na(filt_vars[3])) {basin_or_zone %in% filt_vars[[3]]} #filter any basin/zone
             else {basin_or_zone %in% unique(n3_watercourse_mapping$basin_or_zone)}, #or dont
             if (!is.na(filt_vars[2])) {environment %in% filt_vars[[2]]} #filter any environment
             else {environment %in% unique(n3_watercourse_mapping$environment)}, #or dont
             if (!is.na(filt_vars[1])) {region %in% filt_vars[[1]]} #filter any region
             else {region %in% unique(n3_watercourse_mapping$region)}) #or dont
  
    #split the watercourse data into lines and polygons and filter stream order
    water_lines <- test_2 |> st_collection_extract("LINESTRING") |> 
      filter(if (!is.na(filt_vars[5])) {stream_order >= filt_vars[[5]]} #filter any stream order
                else {stream_order %in% unique(n3_watercourse_mapping$stream_order)})#or dont
    
    #if streams exists, map the layer under a seperate name as sometimes it needs to be called distinctly
    if (nrow(water_lines) > 0){
      
      water_map <- tm_shape(water_lines) +
        tm_lines(col = "dodgerblue", lwd = 0.5)
    }
    
    if (wat_areas == T & length(unique(st_geometry_type(test_2))) > 1){#if water polygons have been request, and they exist
      
      #extract the polygons 
      water_polygons <- test_2 |> st_collection_extract("POLYGON")
      
      #and map them
      water_map <- water_map + 
        tm_shape(water_polygons) +
        tm_polygons(col = "aliceblue", border.col = "dodgerblue", lwd = 0.5)
      
    }
    
    if (exists("water_map")){#if the water map has been created

      #add it to the global environment
      assign("water_map", water_map, envir = globalenv())
      
      cat("\nThe water map layer has been assigned to the global environment with the name 'water_map'.\n")
    }
    
  }
  
  #read in qld outlines data from the gisaimsr package, filter for land and islands, update crs
  qld <- get(data("gbr_feat", package = "gisaimsr")) |> filter(FEAT_NAME %in% c("Mainland", "Island")) |> 
    st_transform("EPSG:7844")

  #if environment wasn't specified. drop it
  test <- test |> 
    select(if (is.na(filt_vars[2])) {c("region", "basin_or_zone", "sub_basin_or_sub_zone")} 
              else {c("region", "environment", "basin_or_zone", "sub_basin_or_sub_zone")})
  
  #summarise geometries of the targeted area
  test <- test |> 
    group_by(across(1:(ncol(test)-1))) |> 
    summarise(geom = st_union(geom))
  
  #start the creation of the base map wtih a full grey region background
  map <- tm_shape(qld) +
    tm_polygons(col = "grey80", border.col = "black") +
    tm_shape(background) +
    tm_polygons(col = "grey90", border.col = "black")
  
  if (colour == T){#if the background should be coloured, do it
    map <- map +
      tm_shape(test) +
      tm_polygons(col = "sub_basin_or_sub_zone", border.col = "black", alpha = 0.7, palette = "Pastel1", title = "Legend") 
      
  } else {#otherwise dont colour the background
    map <- map +
      tm_shape(test) +
      tm_polygons(col = "grey90", border.col = "black")
  }

  if (water){
    
    #add the watercourse lines
    map <- map +
      tm_shape(water_lines) +
      tm_lines(col = "dodgerblue", lwd = 0.5) +
      tm_layout(legend.bg.color = "white", legend.frame = "black", asp = 1.1, legend.position = c("left", "bottom")) 
    
    if (wat_areas == T & length(unique(st_geometry_type(test_2))) > 1){#if the watercourse areas have been requested, add them, otherwise don't
      map <- map + 
        tm_shape(water_polygons) +
        tm_polygons(col = "aliceblue", border.col = "dodgerblue", lwd = 0.5)
    }
  }
  
  if (!all(is.na(supplied_sf))){#if there was an object supplied to help orientate the map, create some target areas, otherwise don't
    
    #create a bbox and sfc object of the supplied sf area
    target_bbox <- st_bbox(supplied_sf)
    target_focus_area <- st_as_sfc(target_bbox)
    
    #create a second dataset of the region for the targeted area (inset map background is never smaller than region)
    background <- n3_region_mapping |> 
      filter(region == unique(test$region))
    
    #create an inset map
    inset_map <- tm_shape(qld) + 
      tm_polygons(col = "grey80", border.col = "black") +
      tm_shape(background, is.master = T) +
      tm_polygons(col = "grey90", border.col = "black") +
      tm_shape(target_focus_area) +
      tm_borders(lwd = 2, col = "red")
    
    #figure out the aspect of the inset map and the view port
    asp2 <- (target_bbox$ymax - target_bbox$ymin)/(target_bbox$xmax - target_bbox$xmin)
    w <- 0.2
    h <- asp2 * w
    vp <- viewport(x = 0.98, y = 0.97, width = w, height = h, just = c("right", "top"))
    
    #assign the inset map and view port to the global environment
    assign("base_inset", inset_map, envir = globalenv())
    assign("base_vp", vp, envir = globalenv())
    
    cat("\nThe variables 'base_inset' and 'base_vp' were assigned to the global environment to use for an inset map.\n")

  }
  
  #assign the base map to the global environment
  assign("base_map", map, envir = globalenv())
  
  cat("\nThe base map has been assigned to the global environment with the name 'base_map'.\n")

}










