#inputs: 
#df <- every single df that is read should be passed through this function

name_cleaning <- function(df){

  #open the core libraries of this function
  library(janitor)
  
  #check if the df is an sf object and if so, apply clean names to every column but the last column
  if(inherits(df, "sf")){
    
    #convert all but the geometry column to upper camel type
    df_new <- df |> 
      st_drop_geometry() |>
      clean_names(case = "upper_camel")
    
    #extract the geometry column as it own object
    extract_geom_col <- st_geometry(df)
    
    #bind the column back on with its new name. Note that it should also be named "Geom"
    df_new <- df_new |>
      mutate(geom = extract_geom_col) |> 
      st_as_sf()
  
  } else {
    
    #convert ALL columns to upper camel type, don't have to worry about geometry
    df_new <- df |> 
      clean_names(case = "upper_camel")
    
  }

  return(df_new)
  
}

