#inputs: 
#no inputs required
#pulls data from the current_fyear and the following 4 years and saves

n3_get_sst_data <- function(){

  #create start of url (will split depending on year targeted)
  start_url <- "https://www.star.nesdis.noaa.gov/pub/sod/mecb/crw/data/5km/v3.1_op/nc/v1.0/monthly/"
  
  #create save path for data in case this is first time running
  dir.create("data/climate_sea-surface-temperature/")
  
  #create an empty vector for file naming
  fname <- vector()
  
  #create empty raster for file storing
  sst <- terra::rast()
  
  #create empty vector of layer names
  lyr_names <- vector()
  
  #for a vector of numbers from 1985 to current
  for (i in 1985:current_fyear){
    
    n = i-1984
    
    #build month tracker
    for (ii in 1:12){
      
      #if it has a single digit
      if (ii <= 9){
        
        #add a zero to the front of it
        month <- paste0("0", ii)
        
      } else {
        
        #otherwise do nothing
        month <- ii
        
      }
      
      #finish the file name
      fname <- glue::glue("data/climate_sea-surface-temperature/sst_{i}{month}.nc")
      
      #finish the url
      url <- glue::glue("{start_url}{i}/ct5km_sst-mean_v3.1_{i}{month}.nc")
      
      #if the file is already downloaded
      if (file.exists(fname)){
        
        #open it from source and add it to the raster
        sst <- c(sst, terra::rast(fname) |> terra::subset(1))
        
      } else {
        #otherwise download the file using the url
        download.file(url, fname, mode = "wb")
        
        #then append to the raster
        sst <- c(sst, terra::rast(fname) |> terra::subset(1))
        
      }
      
      #keep track of layer names
      lyr_names <- append(lyr_names, glue::glue("sst_{i}{month}"))
      
    }
  }
  
  
  #set crs
  terra::crs(sst) <- proj_crs
    
  #add names
  names(sst) <- lyr_names
  
  #assign the variable to the global environment
  assign("sst", sst, envir =  globalenv())
  
  #send update message
  print("SST Data added to data/sst/ folder and loaded to globalenv, data processing complete")
  
}

