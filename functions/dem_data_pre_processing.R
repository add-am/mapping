#inputs: 
#SpatVec - the spatial vector used to perform additional cropping
#name - the name used to save any additional outputs
#save - the path to the save location for any additional outputs
#resolution - if creating additional outputs, what size do you want?
#reload - does the user want to reload data if it exists?

dem_data_pre_processing <- function(SpatVec = NA, name = NA, save = NA, resolution = NA, reload = FALSE){

  #----------------------------------------
  #Part 1: Creating the full N3 30m dataset
  #----------------------------------------
  
  #create paths to cut down versions of each dataset
  path_30m <- here("data/n3_dem/gbr_30m.nc")
  path_100m <- here("data/n3_dem/gbr_100m.nc")
  
  if (file.exists(path_30m) & suppressWarnings(is.na(SpatVec))){#if the cut down n3 30m version exists and no extra cropping has been requested
    
    #read and assign
    assign("n3_30m_dem", rast(path_30m), envir =  globalenv())
    
    print("Pre-processed N3 30m Digital Elevation Model read from storage and loaded to the global environment with the name 'n3_30m_dem'.")
    
  } else if (file.exists(path_30m) & suppressWarnings(!is.na(SpatVec))) {#if the cut down n3 30m version exists, and extra cropping has been requested do nothing (we will use the later dataset)
    
    print ("Pre-processed N3 30m Digital Elevation Model exists but has not been requested.")
    
  } else {#otherwise the cut down n3 30m dataset does not exists and thus it must be made
    
    for (i in 1:4){#read in each of the separate files (each named "A" through "D")
      
      print(glue("Creating N3 30m Digital Elevation Model. Progress: File {i} of 4."))
      
      #read file
      temp_data <- rast(glue("{here()}/data/n3_dem/great_barrier_reef_bathymetry_30m/great_barrier_reef_30m_{letters[i]}.tif"))
      
      #force origin (top right) to be 0 - some are very slightly off, e.g. 0.001
      origin(temp_data) <- 0
      
      #give the object a simple name (A through D)
      assign(glue("{letters[i]}"), temp_data)
      
    }
    
    print("Merging files.")
    
    #merge the data rasters - this will take a long time. Then update the crs
    gbr_30m_merge <- merge(a, b, c, d) |> project(proj_crs)
    
    #read in the northern three spatial files and create a bounding box in the spatial Vector format
    n3_box <- st_as_sfc(st_bbox(st_read(here("data/n3_region-builder/n3_region.gpkg")))) |> vect() 
    
    #trim and mask to a bounding box of the Northern Three region. mask = everything outside box is now NA, trim = remove NA
    n3_30m_dem <- trim(mask(gbr_30m_merge, n3_box))
    
    #save the merged output - this will take a long time. 
    writeCDF(n3_30m_dem, path_30m, overwrite = T)
    
    #now we know the cut down 30m version exists (we just made it)
    if (suppressWarnings(is.na(SpatVec))){#if no extra cropping has been requested
      
      #read and assign
      assign("n3_30m_dem", rast(path_30m), envir = globalenv())
      
      print("Pre-processed N3 30m Digital Elevation Model created and loaded to the global environment with the name 'n3_30m_dem'.")
      
    } else if (suppressWarnings(!is.na(SpatVec))) {#if extra cropping has been requested
      
      print ("Pre-processed N3 30m Digital Elevation Model has now been created but has not been requested.")
      
    }
  }
  
  #----------------------------------------
  #Part 2: Creating the full N3 100m dataset
  #----------------------------------------

  if (file.exists(path_100m) & suppressWarnings(is.na(SpatVec))){#if the cut down n3 100m version exists, and no extra cropping has been requested
    
    #read and assign
    assign("n3_100m_dem", rast(path_100m), envir =  globalenv())
    
    print("Pre-processed N3 100m Digital Elevation Model read from storage and loaded to the global environment with the name 'n3_100m_dem'.")
    
  } else if (file.exists(path_100m) & suppressWarnings(!is.na(SpatVec))) {#if the cut down n3 100m version exists, and extra cropping has been requested, do nothing (we will use a later dataset)
    
    print ("Pre-processed N3 100m Digital Elevation Model exists but has not been requested.")
    
  } else {#otherwise the cut down n3 100m dataset does not exists and thus it must be made
    
    print(glue("Creating N3 100m Digital Elevation Model."))
    
    gbr_100m_dem <- rast(here("data/n3_dem/great_barrier_reef_bathymetry_100m/great_barrier_reef_100m.tif"))
    
    #update the crs
    gbr_100m_dem <- project(gbr_100m_dem, proj_crs)
    
    #read in the northern three spatial files and create a bounding box in the spatial Vector format
    n3_box <- st_as_sfc(st_bbox(st_read(here("data/n3_region-builder/n3_region.gpkg")))) |> vect() 
    
    #trim and mask to a bounding box of the Northern Three region. mask = everything outside box is now NA, trim = remove NA
    n3_100m_dem <- trim(mask(gbr_100m_dem, n3_box))
    
    #save the merged output - this will take a long time. 
    writeCDF(n3_100m_dem, path_100m, overwrite = T)
    
    #now we know the cut down 100m version exists (we just made it)
    if (suppressWarnings(is.na(SpatVec))){#if extra cropping has not been requested
      
      #read and assign
      assign("n3_100m_dem", rast(path_100m), envir = globalenv())
      
      print("Pre-processed N3 100m Digital Elevation Model created and loaded to the global environment with the name 'n3_100m_dem'.")
      
    } else if (suppressWarnings(!is.na(SpatVec))) {#if extra cropping has been requested
      
      print ("Pre-processed N3 100m Digital Elevation Model has now been created but has not been requested.")
      
    }
  }
  
  #--------------------------------------------------------------------------
  #Part 3: Creating the additional cut down version of the data (if requested)
  #--------------------------------------------------------------------------
  
  if (suppressWarnings(is.na(SpatVec))){#if SpatVec is NA then we obvious can't/don't need to continue
    
    #it is important to note here that reload = F is not a tell. Reload could be false because the user wants to make a new version of the data.
    
  } else {
  
    #clean up the name variable
    name <- str_replace_all(str_to_lower(name), " |-", "_")
    
    #clean up the resolution variable
    resolution <- as.character(resolution)
    
    #create a path
    extra_crop <- glue("{save}/{name}_{resolution}m.nc")
    
    if (file.exists(extra_crop) & reload == T){#if the file exists and reload is true we can read it in and be done
      
      #read and assign
      assign(glue("{name}_dem"), rast(extra_crop), envir = globalenv())
      
      print(glue("Additional custom area read from storage and loaded to the global environment with the name '{name}_dem'."))
      
    } else if (!file.exists(extra_crop) | reload == F){#if the file doesn't exist or the users wants to overwrite
      
      #load in data
      #target_dem <- rast(get(glue("path_{resolution}m")))
      
      #update crs if required
      #if (!is.na(provided_crs)){target_dem <- project(target_dem, provided_crs)}
      
      #crop the full n3 version down to the additional request
      custom <- trim(mask(rast(get(glue("path_{resolution}m"))), SpatVec))
      
      #save the output
      writeCDF(custom, extra_crop, overwrite = T)
      
      #assign
      assign(glue("{name}_dem"), custom, envir =  globalenv())
      
      print(glue("Additional custom area created and loaded to the global environment with the name '{name}_dem'."))
    
    }
  }
}
   
