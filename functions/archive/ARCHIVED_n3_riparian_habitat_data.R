#inputs: no inputs required
n3_riparian_habitat_data <- function(){
  
  #read in the northern three spatial files and reduce down to only the components we need (region, basin, sub basin)
  n3_region <- st_read(here("data/n3_region-builder/n3_region.gpkg")) |> filter(environment != "Marine") |> 
    group_by(region, environment, basin_or_zone, sub_basin_or_sub_zone) |> summarise(geom = st_union(geom)) |> 
    rename(basin = basin_or_zone, sub_basin = sub_basin_or_sub_zone) |> 
    ungroup() |> st_cast() |> st_make_valid()
  
  #create path to the northern three riparian area dataset, and to the various versions of the regional ecosystem data
  rip_path <- here("data/n3_habitat_riparian-vegetation/riparian_area/n3_riparian_boundaries.gpkg")
  re_raw_path <- here("data/n3_habitat/re_raw/")
  re_cropped_path <- here("data/n3_habitat/re_cropped/")
  re_rip_cropped_path <- here("data/n3_habitat_riparian-vegetation/re_riparian_cropped/")
  
  if (file.exists(rip_path)){ #if the riparian area dataset exists, read it in
    
    writeLines('\n\nThe riparian area file exists, the data will loaded from storage.\n')
    
    rip_boundaries <- st_read(rip_path)
    
  } else { #otherwise create and save the dataset
    
    writeLines('\n\nThe riparian area file does not exists, the data will be created and saved to storage.\n')
    
    #read in watercourse lines and drop all rows with strm_order == NA or 1, crop to the n3 region
    n3_wc_lines <- st_read(here("data/n3_habitat_riparian-vegetation/riparian_area/watercourse_lines.gpkg")) |> 
      st_transform(proj_crs) |> filter(!is.na(STRM_ORDER)) |> 
      st_intersection(n3_region) |> 
      select(region, environment, basin, sub_basin, Shape) |> 
      rename(geom = Shape)
    
    #read in the statewide corridors and filter for only the riparian layer
    n3_corridors <- st_read(here("data/n3_habitat_riparian-vegetation/riparian_area/riparian_corridors.gdb"),
                            layer = st_layers(here("data/n3_habitat_riparian-vegetation/riparian_area/riparian_corridors.gdb"))[[1]]) |> 
      st_transform(proj_crs) |> 
      st_intersection(n3_region) |> 
      select(region, environment, basin, sub_basin, Shape) |> 
      rename(geom = Shape)
    
    #combine datasets
    rip_boundaries <- rbind(n3_wc_lines, n3_corridors)
    
    #project data to a meters dataset, add the 50m buffer, project back to GDA2020
    rip_boundaries <- st_transform(rip_boundaries, "EPSG:7855") |> st_buffer(50) |> st_transform(proj_crs)
    
    #save to file
    st_write(rip_boundaries, rip_path, append = F)
    
    #clean up and force gc
    rm(n3_wc_lines, n3_corridors, rip_path)
    gc()
    
  }
 
  #get a vector of all the original files in the raw folder that contain ".gpkg"
  file_vec <- tools::file_path_sans_ext(list.files(re_raw_path, pattern = ".gpkg"))

  #create a vector to track objects created
  layers_loaded <- c()
  
  for (i in file_vec){#for each file in the vector or original files
    
    if (file.exists(glue("{re_rip_cropped_path}/{i}_riparian_cropped.gpkg"))){#if the fully riparian cropped version of the file exists
      
      writeLines('\nThe fully "riparian-cropped" file alread exists.\n')

      } else {
        
        if (file.exists(glue("{re_cropped_path}/{i}_cropped.gpkg"))){#if the n3 cropped version of the file exists
        
          writeLines('\n\nThe "N3-cropped" file exists, the data loaded from storage.')
          writeLines('\nThe fully "riparian-cropped" file will now be created and saved.\n')
          
          #read it in
          re_layer <- st_read(glue("{re_cropped_path}/{i}_cropped.gpkg"))
          
        } else { #if no cropped version of the original data exists (riparian or n3), first create the N3 version
          
          writeLines("\nNo cropped version (riparian or N3) of the original Regional Ecosystem data exists.")
          writeLines('\nThe "N3-cropped" file will be created and saved.')
          writeLines('\nThen the fully "riparian-cropped" file will be created and saved.\n')
          
          #read in the original regional ecosystem layer and transform the crs, then intersect over the n3 area
          re_layer <- st_read(glue("{re_raw_path}/{i}.gpkg")) |> st_transform(proj_crs) |> st_intersection(n3_region)
          
          #save the n3 cropped file 
          st_write(re_layer, glue("{re_cropped_path}/{i}_cropped.gpkg"), append = F)
          
        }
        
        #get a vector of all the basins present in the data
        basin_vector <- unique(re_layer$basin)
        
        #create a vector to track all the files that are created
        rip_basin_files <- c()
        
        #create a empty sf object to hold final outputs
        rip_final <- st_sf(st_sfc())
        
        for (j in basin_vector){#for each basin
          
          #filter for only that basin of RE data and take only polygons
          re_basin_layer <- re_layer |> filter(basin == j) |> st_collection_extract("POLYGON")
                
          #filter for only that basin of riparian boundaries then drop all columns except environment
          rip_basin_boundaries <- rip_boundaries |> filter(basin == j) |> select(environment)
                
          #intersect over the pair
          re_rip_basin_layer <- re_basin_layer |> st_intersection(rip_basin_boundaries)
                
          #keep track of the data that has been created
          rip_basin_files <- append(rip_basin_files, j)
          
          #assign each dataset to the global environment
          assign(j, re_rip_basin_layer)
                
        }
        
        #create a list containing all of the basin datasets that were loaded in
        basin_rip_list <- lapply(rip_basin_files, function(x) get(x))
        
        #bind all datasets together
        re_rip_data <- do.call(rbind, basin_rip_list)
        
        #pull the year from the name
        i_year <- str_remove_all(i, "^re_|_v12_2")
        
        #add year column to data
        re_rip_data <- re_rip_data |> mutate(year = i_year)
            
        #save the final rip cropped file
        st_write(re_rip_data, glue("{re_rip_cropped_path}/{i}_riparian_cropped.gpkg"), append = F)

      }

  }
  
}

