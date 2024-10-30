#inputs:
#islands = do you want to include islands in the shapefile? Y or N
#reload = do you want to attempt to reload from data already prepared? Y or N

n3_basin_builder <- function(islands = F, marine = F, overwrite = F){
  
  #turn off spherical geometry
  sf_use_s2(FALSE)
  
  #set crs
  proj_crs <- "EPSG:7844"
  
  #----------- Set up packages
  packages <- c("sf", "glue", "here", "dplyr", "remotes")

  for (package in packages) {
    if (!package %in% installed.packages()) {#if package not in list, install it
      install.packages(package, dependencies = TRUE)
    }
    if (!package %in% .packages()) {#if package not in list, load it
      library(package, character.only = TRUE)
    }
  }
  #special case for gisaimsr package
  if (!"gisaimsr" %in% installed.packages()){#if package not in list, install it
    remotes::install_github("https://github.com/open-AIMS/gisaimsr")
    #library(gisaimsr)
  } 
  if (!"gisaimsr" %in% .packages()){#if package not in list, load it
    library(gisaimsr)
  }
  
  #-----------
  #----------- Check for all required files
  
  stopifnot("One or more shapefiles do not exist in the directory, review the n3_basin_builder function to check where and how files should be named and stored" = 
              file.exists(here("data/shapefiles/Drainage_basins.shp"),
                          here("data/shapefiles/Drainage_basin_sub_areas.shp"),
                          here("data/shapefiles/WT_marine.shp"),
                          here("data/shapefiles/MWI_marine.shp"),
                          here("data/dry-tropics_basin-builder_dt/Dry-Tropics-Basins-Detailed.shp")))
  
  #-----------
  #----------- Create paths to each version of the n3 basin file
  
  path1 <- here("data/shapefiles/n3_basins.gpkg")
  path2 <- here("data/shapefiles/n3_basins_marine.gpkg")
  path3 <- here("data/shapefiles/n3_basins_islands.gpkg")
  path4 <- here("data/shapefiles/n3_basins_islands_marine.gpkg")
  
  #-----------
  #----------- If overwrite is false, check against conditions for which file to load in
  
  if (overwrite == F){
    if (file.exists(path1) == T & islands == F & marine == F){
      
      n3_basins <- st_read(path1)
      .GlobalEnv$n3_basins <- n3_basins
      warning("Data has been loaded from a previous iteration, if you would like to create a new version, ensure 'overwrite=T'")
      return("The 'n3_basins' variable, with no islands or marine zone, has been added to the global environment")
      
    } else if (file.exists(path2) == T & islands == F & marine == T){
      
      n3_basins <- st_read(path2)
      .GlobalEnv$n3_basins <- n3_basins
      warning("Data has been loaded from a previous iteration, if you would like to create a new version, ensure 'overwrite=T'")
      return("The 'n3_basins' variable, with the marine zone but no islands, has been added to the global environment")
      
    } else if (file.exists(path3) == T & islands == T & marine == F){
      
      n3_basins <- st_read(path3)
      .GlobalEnv$n3_basins <- n3_basins
      warning("Data has been loaded from a previous iteration, if you would like to create a new version, ensure 'overwrite=T'")
      return("The 'n3_basins' variable, with islands but no marine zone, has been added to the global environment")
      
    } else if (file.exists(path4) == T & islands == T & marine == T){
      
      n3_basins <- st_read(path4)
      .GlobalEnv$n3_basins <- n3_basins
      warning("Data has been loaded from a previous iteration, if you would like to create a new version, ensure 'overwrite=T'")
      return("The 'n3_basins' variable, with islands and the marine zone, has been added to the global environment")
      
    }
  }
  
  #-----------
  #----------- Set up each of these components (land, marine, island)
  #----------- LAND
  
  #read the drainage basins and drainage basin sub areas and special dry tropics basins and update crs
  basins <- st_read(here("data/shapefiles/Drainage_basins.shp"), quiet = T) |> st_transform(proj_crs)
  sub_basins <- st_read(here("data/shapefiles/Drainage_basin_sub_areas.shp"), quiet = T) |> st_transform(proj_crs)
  dt_env <- st_read(here("data/dry-tropics_basin-builder_dt/Dry-Tropics-Basins-Detailed.shp"), quiet = T) |> st_transform(proj_crs)
  
  #get the dt basins (this comes from the dt specific shapefile as it also includes info on the islands (maggie, palm group))
  dt_basins <- dt_env |> filter(zone %in% c("ross", "black")) |> group_by(zone) |> summarise() |> 
    mutate(region = "Dry Tropics") |> rename(basin = zone) |> mutate(basin = str_to_title(basin))
  
  #create drainage basins list for northern three regions
  basin_list <- c("Don", "Proserpine", "O'Connell", "Pioneer", "Plane", "Daintree", "Mossman", "Barron", "Johnstone", "Tully", "Murray", "Herbert")
  
  #select northern three basins
  n3_basins <- basins |> filter(BASIN_NAME %in% basin_list)
  
  #wet tropics split mulgrave-russell into two separate sub basins, get Russell and Mulgrave River from sub_basins
  temp <- sub_basins |> filter(SUB_NAME %in% c("Russell River", "Mulgrave River")) |> 
    mutate(SUB_NAME = case_when(SUB_NAME == "Russell River" ~ "Russell", SUB_NAME == "Mulgrave River" ~ "Mulgrave")) |>  
    rename(BASIN_NAME = SUB_NAME, BASIN_NUMB = SUB_NUMBER)
  
  #add two basins onto main
  n3_basins <- rbind(n3_basins, temp)

  #remove unwanted vars and add regional context
  n3_basins <- n3_basins |> select(BASIN_NAME) |> rename(basin = BASIN_NAME)  |>  
    mutate(region = case_when(str_detect(basin, "Dain|Moss|Barr|John|Tull|Murr|Herb|Mulg|Russ") ~ "Wet Tropics",
                              str_detect(basin, "Don|Proser|O'|Pio|Plane") ~ "Mackay Whitsunday Isaac"), .after = basin)
  
  #add dry tropics
  land_sf <- rbind(n3_basins, dt_basins)
  
  #-----------
  #----------- MARINE
  
  if (marine == T){
  
    #read each regions marine data update crs, select name, geom, and a random 3rd column, change name to region and the random 3rd column to basin
    wt_marine <- st_read(here("data/shapefiles/WT_marine.shp")) |> st_transform(proj_crs) |> 
      dplyr::select(NAME, NRM_BODY, geometry) |> rename(region = NAME, basin = NRM_BODY) |> 
      mutate(basin = "Marine")
    
    mwi_marine <- st_read(here("data/shapefiles/MWI_marine.shp")) |> st_transform(proj_crs) |> 
      dplyr::select(Name, end, geometry) |> rename(region = Name, basin = end) |> 
      mutate(basin = "Marine", region = "Mackay Whitsunday Isaac") |> st_zm() |> group_by(region, basin) |> 
      summarise(geometry = st_union(geometry))
    
    dt_marine <- st_read(here("data/dry-tropics_basin-builder_dt/Dry-Tropics-Basins-Detailed.shp")) |> st_transform(proj_crs) |> 
      subset(env == "marine") |> rename(basin = zone, region = env) |> 
      mutate(basin = "Marine", region = "Dry Tropics") |> group_by(region, basin) |> summarise() |> 
      nngeo::st_remove_holes()
    
    marine_sf <- rbind(wt_marine, dt_marine, mwi_marine)
  }
 
  #-----------
  #----------- ISLANDS
  
  if (islands == T){
  
    unnamed_islands <- get(data("gbr_feat", package = "gisaimsr")) |> filter(FEAT_NAME %in% c("Island")) |> 
      filter(OBJECTID == "3271") |> st_cast("POLYGON") |> st_crop(st_bbox(n3_basins))
    
    wt_mwi_islands <- get(data("gbr_feat", package = "gisaimsr")) |> filter(FEAT_NAME %in% c("Island")) |> 
      filter(OBJECTID != "3271") |> st_transform(proj_crs) |> st_crop(st_bbox(n3_basins)) |> rbind(unnamed_islands)
    
    wt_mwi_islands$geom2 <- st_centroid(st_geometry(wt_mwi_islands))
    
    wt_mwi_islands <- wt_mwi_islands |> 
      mutate(region = case_when(st_coordinates(geom2)[,2] > -18.54 ~ "Wet Tropics",
                                st_coordinates(geom2)[,2] < -18.54 & st_coordinates(geom2)[,2] > -19.3 ~ "Dry Tropics",
                                st_coordinates(geom2)[,2] < -19.72 ~ "Mackay Whitsunday Isaac")) |> 
      filter(region != "Dry Tropics") 
    
    wt_mwi_islands <- wt_mwi_islands |> 
      mutate(remove = st_overlaps(wt_mwi_islands, n3_basins) %>% lengths > 0,
             remove2 = st_covered_by(wt_mwi_islands, n3_basins) %>% lengths > 0) |> 
      mutate(remove3 = case_when(remove == F & remove2 == F ~ F, T ~ T)) |> 
      filter(remove3 == F) |> select(-c(remove, remove2, remove3))
    
    nearest_feat <- st_nearest_feature(wt_mwi_islands, n3_basins)
    
    replace_with <- unique(n3_basins$basin)
    replace_from <- c(1:length(unique(n3_basins$basin)))
    
    wt_mwi_islands$basin <- c(replace_with, nearest_feat)[match(nearest_feat, c(replace_from, nearest_feat))]
    
    #group everything up
    islands_sf <- wt_mwi_islands |> group_by(region, basin) |> summarise(geometry = st_union(geometry))
  }

  #-----------
  #----------- Build the n3 basin based on required version
  
  if (islands == F & marine == F){
      
      st_write(land_sf, path1, append = T)
      .GlobalEnv$n3_basins <- land_sf
      return("The 'n3_basins' variable, with no islands or marine zone, has been added to the global environment")
      
    } else if (islands == F & marine == T){
      
      st_write(rbind(land_sf, marine_sf), path2, append = T)
      .GlobalEnv$n3_basins <- rbind(land_sf, marine_sf)
      return("The 'n3_basins' variable, with the marine zone but no islands, has been added to the global environment")
      
    } else if (islands == T & marine == F){
      
      st_write(rbind(land_sf, islands_sf), path3, append = T)
      .GlobalEnv$n3_basins <- rbind(land_sf, islands_sf)
      return("The 'n3_basins' variable, with islands but no marine zone, has been added to the global environment")
      
    } else if (islands == T & marine == T){
      
      st_write(rbind(land_sf, marine_sf, islands_sf), path4, append = T)
      .GlobalEnv$n3_basins <- rbind(land_sf, marine_sf, islands_sf)
      return("The 'n3_basins' variable, with islands and the marine zone, has been added to the global environment")
      
    }
}

