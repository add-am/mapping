#inputs: 
#supplied_sf = REQUIRED. The main sf object that will define the area of interest
#stream_order = the variable used to define the stream order(s)
#lines = T/F does the user want to include water lines (streams, rivers, etc) 
#areas = T/F does the user want to include water polygons (lakes etc)
#fast = T/F does the user want to attempt the fast method? This involves filtering using region, env, basin, sub_basin
#region = the variable used to define the region(s)
#environment =the variable used to define the environment(s)
#basin_or_zone = the variable used to define the basin or zone(s)
#sub_basin_or_sub_zone = the variable used to define the sub basin or sub zone(s)

maps_water_layer <- function(supplied_sf, stream_order = NA, water_lines = T, water_polygons = T, fast = F,
                             region = NA, enviro = NA, basin_or_zone = NA, sub_basin_or_sub_zone = NA){
  
  #create a vector of package dependencies
  package_vec <- c("tmap", "tidyverse", "glue", "sf", "here")

  #apply the function "require" to the vector of packages to install and load dependencies
  lapply(package_vec, require, character.only = T)
  
  #turn off spherical geometry
  sf_use_s2(F)
  
  #load the n3_watercourse_mapping dataset/check if it was already loaded
  if (!exists("n3_watercourse_mapping")) {
    
    n3_watercourse_mapping <- st_read(here("data/n3_prep_watercourse-builder/n3_watercourse.gpkg"))
    
    #put it into the global environment, so if this function gets used in a loop it doesn't reload the dataset each loop
    assign("n3_watercourse_mapping", n3_watercourse_mapping, envir = globalenv())
    
    #print the message updating the user
    message("\nThe variable 'n3_watercourse_mapping' was assigned to the global environment to enhance function speed within loops.\n")
    
  } else {message("\nThe variable 'n3_watercourse_mapping' was loaded from the global environment.\n")}
  
  #for some reason (im not smart enough to know why, if user gives these as NA they don't actually come through as NA) so we need to check for this
  if (!exists("stream_order") || any(is.na(stream_order))){stream_order <- NA}
  if (!exists("region") || any(is.na(region))){region <- NA}
  if (!exists("enviro") || is.na(enviro)){enviro <- NA}
  if (!exists("basin_or_zone") || is.na(basin_or_zone)){basin_or_zone <- NA}
  if (!exists("sub_basin_or_sub_zone") || is.na(sub_basin_or_sub_zone)){sub_basin_or_sub_zone <- NA}

  #rename variables internally to avoid confusion when reading this script
  internal_stream_order <- stream_order
  internal_region <- region
  internal_environment <- enviro
  internal_basin_or_zone <- basin_or_zone
  internal_sub_basin_or_sub_zone <- sub_basin_or_sub_zone
  
  if (fast){
    
    #print the message updating the user
    message("\nYou are trying the fast method. This relies on filters being correctly provided to the n3_watercourse dataset.\n")
    
    #combine filterable variables into a list
    filt_vars <- list(internal_region = internal_region, internal_environment = internal_environment,
                      internal_basin_or_zone = internal_basin_or_zone, internal_sub_basin_or_sub_zone = internal_sub_basin_or_sub_zone)
    
    #check each of the filterable variables to help the user
    if (all(!all(filt_vars[[1]] %in% n3_watercourse_mapping$Region) & !is.na(filt_vars[[1]]))){
      stop(glue("\nAt least one filter supplied to the '{names(filt_vars[1])}' variable does not exist in the spatial file. Options available are: 
               {paste(unique(n3_watercourse_mapping$Region), collapse = ', ')}.
                You supplied {filt_vars[1]}.\n"))
    }
    if (all(!all(filt_vars[[2]] %in% n3_watercourse_mapping$Environment) & !is.na(filt_vars[[2]]))){
      stop(glue("\nAt least one filter supplied to the '{names(filt_vars[2])}' variable does not exist in the spatial file. Options available are: 
               {paste(unique(n3_watercourse_mapping$Environment), collapse = ', ')}.
                You supplied {filt_vars[2]}.\n"))
    }
    if (all(!all(filt_vars[[3]] %in% n3_watercourse_mapping$BasinOrZone) & !is.na(filt_vars[[3]]))){
      stop(glue("\nAt least one filter supplied to the '{names(filt_vars[3])}' variable does not exist in the spatial file. Options available are: 
               {paste(unique(n3_watercourse_mapping$BasinOrZone), collapse = ', ')}.
                You supplied {filt_vars[3]}.\n"))
    }
    if (all(!all(filt_vars[[4]] %in% n3_watercourse_mapping$SubBasinOrSubZone) & !is.na(filt_vars[[4]]))){
      stop(glue("\nAt least one filter supplied to the '{names(filt_vars[4])}' variable does not exist in the spatial file. Options available are: 
               {paste(unique(n3_watercourse_mapping$SubBasinOrSubZone), collapse = ', ')}.
                You supplied {filt_vars[4]}.\n"))
    }
  }

  #check if stream order can be parsed
  if (all(!any(internal_stream_order %in% n3_watercourse_mapping$StreamOrder) & !is.na(internal_stream_order))){
    stop(glue("\nFilter(s) supplied to the 'stream_order' variable do not exist in the spatial file. Options available are: 
               {paste(unique(n3_watercourse_mapping$stream_order), collapse = ', ')}.
                You supplied {internal_stream_order}.\n"))
  }
  
  #check the length of stream order is either 1 or 2
  if (length(internal_stream_order) > 2) {
    
    stop("\nThe variable 'stream_order' must be of length 1 or 2. 
        A length of 1 will filter for streams greater than or equal to the supplied stream_order variable, e.g. '>= 3'.
        A length of 2 is used to supply the upper and lower stream order bounds, e.g. 'c(4,9)'.\n")
  }
  
  if (fast){#if user wants to try the fast method, attempt to filter the watercourse dataset
    
    #these are mutually exclusive and can be run as a "pick one" situtation
    focus_water <- n3_watercourse_mapping |> 
      filter(if (!is.na(filt_vars[4])) {SubBasinOrSubZone %in% filt_vars[[4]]} #filter any sub basin/zone
             else if (!is.na(filt_vars[3])) {BasinOrZone %in% filt_vars[[3]]} #filter any basin/zone
             else if (!is.na(filt_vars[1])) {Region %in% filt_vars[[1]]}) #filter any region
    
    #this needs to be done seperately as it can work in tandem with the above filters
    focus_water <- focus_water |> 
      filter(if (!is.na(filt_vars[2])) {Environment %in% filt_vars[[2]]}) #filter any environment
             
    
  } else {#otherwise do the safe method that cuts (spatially) the dataset
  
    #cut the full watercourse dataset down to the focus area as defined by the supplied sf object
    focus_water <- st_intersection(n3_watercourse_mapping, st_union(supplied_sf))
  }
  
  #split the water dataset into a lines dataset and filter by stream order
  if (any(str_detect(unique(st_geometry_type(focus_water)), "LINE"))){
    
    focus_water_lines <- focus_water |> 
      st_collection_extract("LINESTRING") |> 
      filter(if (all(!is.na(internal_stream_order) & length(internal_stream_order) == 1)) 
        {StreamOrder >= internal_stream_order}
             else if (all(!is.na(internal_stream_order) & length(internal_stream_order) == 2)) 
               {StreamOrder %in% internal_stream_order[1]:internal_stream_order[2]}
        else {StreamOrder %in% StreamOrder})
  }
  
  if (any(str_detect(unique(st_geometry_type(focus_water)), "POLY"))){
  
    #and a polygon dataset
    focus_water_areas <- st_collection_extract(focus_water, "POLYGON")
  }
  
  #check if lines exists and notify the user
  if (all(!exists("focus_water_lines") & water_lines == T)){
    
    warning("\nThere are no water related, line type, geometry features in the targetted area. Lines will not be included.")
    
    water_lines <- F
    
  }
  
  #check if polygons exists and notify the user
  if (all(!exists("focus_water_areas") & water_polygons == T)){
    
    warning("\nThere are no water related, polygon type, geometry features in the targetted area. Polygons will not be included.")
    
    water_polygons <- F
    
  }
  
  #if neither exists, warn and notify what will happen
  if (!water_lines & !water_polygons){
    
    warning("\nThere are no water related geometry features in the targetted area. The water map will be empty.")
  
  #otherwise construct the map as per the users request  
  } else if (water_lines & water_polygons){#if the user wants both and both exists, create a map with both
    
    water_map <- tm_shape(focus_water_lines, is.master = T) +
      tm_lines(col = "dodgerblue", lwd = 0.5) +
      tm_shape(focus_water_areas) +
      tm_polygons(col = "aliceblue", border.col = "dodgerblue", lwd = 0.5)
    
  } else if (water_lines){#if only lines exist, create a map with only lines
      
      water_map <- tm_shape(focus_water_lines, is.master = T) +
        tm_lines(col = "dodgerblue", lwd = 0.5)

  } else if (water_polygons){#if only areas exists, create a map with only polygons
    
    water_map <- tm_shape(focus_water_areas, is.master = T) +
      tm_polygons(col = "aliceblue", border.col = "dodgerblue", lwd = 0.5)
    
  }
  
  #assign water map to the global environment
  assign("water_map", water_map, envir = globalenv())
  
  message("\nThe water map layer has been assigned to the global environment with the name 'water_map'.\n")
  
}

