n3_get_all_dhw_data <- function(){
  
  #create start of url
  start_url <- "https://www.star.nesdis.noaa.gov/pub/sod/mecb/crw/data/5km/v3.1_op/nc/v1.0/annual/"
  
  #create save path for data in case this is first time running
  dir.create("data/climate_dhw/")
  
  #create an empty vector for file naming
  fname <- vector()
  
  #create empty raster for file storing
  dhw_all <- terra::rast()
  
  #create empty vector of layer names
  lyr_names <- vector()
  
  #for a vector of numbers from 1985 to current
  for (i in 1986:current_fyear){
    
    #finish the file name
    fname <- glue::glue("data/climate_dhw/dhw_{i}.nc")
      
    #finish the url
    url <- glue::glue("{start_url}ct5km_dhw-max_v3.1_{i}.nc")
      
    #if the file is already downloaded
    if (file.exists(fname)){
        
      #open it from source and add it to the raster
      dhw_all <- c(dhw_all, terra::rast(fname) |> terra::subset(1))
        
    } else {
      
      #otherwise download the file using the url
      download.file(url, fname, mode = "wb")
        
      #then append to the raster
      dhw_all <- c(dhw_all, terra::rast(fname) |> terra::subset(1))
        
    }
      
    #keep track of layer names
    lyr_names <- append(lyr_names, glue::glue("dhw_{i}"))
      
  }
  
  #set crs
  terra::crs(dhw_all) <- proj_crs
  
  #add names
  names(dhw_all) <- lyr_names
  
  #assign the variable to the global environment
  assign("dhw_all", dhw_all, envir =  globalenv())
  
  #send update message
  print("DHW Data added to data/dhw/ folder and loaded to globalenv, data processing complete")
  
}

  
  

  

