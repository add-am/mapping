#inputs: 
#no inputs required
#pulls data from the current_fyear and the following 4 years and saves

n3_get_dhw_data <- function(){

  #create empty vector
  fname <- vector()
  
  #create a second empty vector
  years <- vector()
  
  #create empty raster
  dhw_5y <- terra::rast()
  
  #create start of url
  start_url <- "https://www.star.nesdis.noaa.gov/pub/sod/mecb/crw/data/5km/v3.1"
  
  #create save path for data in case this is first time running
  dir.create("data/climate_dhw/")
  
  #get the real year to determine if targeted year is current or historic, only swap to the real year
  #if we are at least 5 months into year
    if (05 <= substr((format(Sys.time(), "%Y-%m-%d")), 6,7)){
    
    real_year <- substr((format(Sys.time(), "%Y-%m-%d")), 1,4)
    
  } else {
    
    real_year <- as.numeric(substr((format(Sys.time(), "%Y-%m-%d")), 1,4))-1
  }
  
  #create a list of save file names for the 5 years proceeding the targeted year
  for (i in 0:4){
    fname <- append(fname, glue::glue("data/climate_dhw/dhw_{current_fyear-i}.nc"))
    
    #and list of years for after the loop below, make sure it is numeric output
    years <- as.numeric(append(years, glue::glue("{current_fyear-i}")))
    
  }
  
  #for each entry in fname
  for (i in 1:length(fname)){
    
    #get a counter starting at 0
    ii <- i-1
    
    #if the targeted file already exists in our folders
    if (file.exists(fname[i])) {
      
      #and if the year of the targeted file is the same as the real year
      if ((current_fyear-ii) >= real_year){
        
        #subset the targeted file for the first layer and append it to the raster
        dhw_5y <- c(dhw_5y, terra::rast(fname[i]) |> subset(1))
        
        #otherwise if the file exists in the folders but it is not the same as the real year
      } else {
        
        #subset the targeted file for the second layer, and then append it to the raster
        dhw_5y <- c(dhw_5y, terra::rast(fname[i]) |> subset(2))
      }
      
      #if the targeted file does not exists in our folders
    } else {
      
      #and the year of the targeted file is the same as the real year
      if ((current_fyear-ii) >= real_year){
        
        #download the file using this url
        url <- glue::glue("{start_url}_op/nc/v1.0/daily/year-to-date/ct5km_dhw-max-ytd_v3.1_{current_fyear}0630.nc")
        
        #otherwise if the file does not exist, and the targeted year is different to the real year
      } else {
        
        #download the file using this url
        url <- glue::glue("{start_url}/nc/v1.0/annual/ct5km_dhw-max_v3.1_{current_fyear-ii}.nc")
      }
      
      #download the file using the url determined above and save
      download.file(url, fname[i], mode = "wb")
      
      #once the file is downloaded, check again if the targeted year is the same as the real year
      if ((current_fyear-ii) >= real_year){
        
        #if they are the same, subset for the first layer and append to the raster
        dhw_5y <- c(dhw_5y, terra::rast(fname[i]) |> subset(1))
        
        #otherwise if the year of the targeted file is different
      } else {
        
        #subset for the second layer, and append to the raster
        dhw_5y <- c(dhw_5y, terra::rast(fname[i]) |> subset(2))
      }
    }
  }
  
  #set crs
  crs(dhw_5y) <- proj_crs
  
  #add time
  time(dhw_5y) <- years
  
  #assign the variable to the global environment
  assign("dhw_5y", dhw_5y, envir =  globalenv())
  
  #assign the years list to the global environment
  assign("years", years, envir = globalenv())
  
  #send update message
  print("DHW Data added to data/dhw/ folder and loaded to globalenv, data processing complete")
  
  #cleanup
  rm(fname, start_url, url, i, ii)
}

  
