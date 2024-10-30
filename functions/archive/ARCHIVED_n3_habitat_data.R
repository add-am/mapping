#inputs: no inputs required
n3_habitat_data <- function(){
  
  #read in the northern three spatial files and reduce down to only the components we need
  n3_region <- st_read(here("data/n3_region-builder/n3_region.gpkg")) |> filter(basin_or_zone != "Offshore") |> 
    group_by(region, basin_or_zone, sub_basin_or_sub_zone) |> summarise(geom = st_union(geom)) |> 
    rename(basin = basin_or_zone, sub_basin = sub_basin_or_sub_zone) |> 
    ungroup() |> st_cast() |> st_make_valid()
  
  #get path to the raw layers and the edited layers
  read_path <- here("data/n3_habitat/re_raw/")
  write_path <- here("data/n3_habitat/re_cropped/")
  
  #get list of files in the read folder that contain "re_" and .gpkg" without their extension
  file_list <- tools::file_path_sans_ext(list.files(read_path, pattern = ".gpkg"))
  
  #create a vector to track objects created
  years_loaded <- c()
  
    for (i in file_list){#for each file in list (excluding cropped versions)
      
      if (file.exists(glue("{write_path}/{i}_cropped.gpkg"))){#if the cropped version exists
        
        writeLines("\n\nCropped file exists, data loaded from storage.\n")
        
        #read it in
        re_layer <- st_read(glue("{write_path}/{i}_cropped.gpkg"))
        
        #edit the name
        i <- str_remove_all(i, "^re_|_v12_2")
        
        #keep track of the new object names
        years_loaded <- append(years_loaded, i)
        
        #assign it to the global environment
        assign(i, re_layer)
        
        } else {
          
          writeLines("\nCropped file does not exists, data will be cropped, saved, then loaded.\n")
        
          #read in the original regional ecosystem layer and transform the crs, then intersect over the n3 area
          re_layer <- st_read(glue("{read_path}/{i}.gpkg")) |> st_transform(proj_crs) |> st_intersection(n3_region)
          
          #save the file 
          st_write(re_layer, glue("{write_path}/{i}_cropped.gpkg"), append = F)
          
          #edit the name
          i <- str_remove_all(i, "^re_|_v12_2")
    
          #keep track of the new object names
          years_loaded <- append(years_loaded, i)
          
          #assign it to the global environment
          assign(i, re_layer)
        }
    }
  
  #for each dataset that was loaded in create a year column to clarify the year of the data then assign it to the correct name again
  for (i in years_loaded){
      
      data <- get(i) |> mutate(year = i) |> select(-any_of(c("OBJECTID", "Shape_Length", "Shape_Area")))
      assign(i, data)
      
      writeLines("\nAssigning layer years.")
  }
  
  writeLines("\nBinding data.\n")
  
  #create a list containing all of the datasets that were loaded in
  data_set_list <- lapply(years_loaded, function(x) get(x))
    
  #bind all datasets together
  re_data <- do.call(rbind, data_set_list)
  
  #put it into the global environment
  assign("re_data", re_data, envir = globalenv())
    
  #put the vector of the years of data loaded into the global environment
  assign("years_loaded", years_loaded, envir = globalenv())
  
  writeLines("\nDataset in the global environment as 're_data'.\n")
  writeLines("\nList of years in the dataset saved as 'years_loaded'.\n")
    
}

