#inputs: 
#SpatRast = the SpatRaster that you want to create a 3D map for
#sea_level = the height at which water elements are drawn, defaults to 0m.
#z_scale = the ratio between the x and y spacing (which are assumed to be equal) and the z axis. 
#E.g., if the elevation is in  eters and the grid values are separated by 30 meters, 'z_scale' would
#be 30 (for realistic topography). Decrease the z_scale to exaggerate heights.
#name = the name used for all saving/storing/reading functions
#save = the path to the save location 
#resolution = either the 30m or 100m dataset can be chosen. It should match the resolution of the SpatRaster otherwise the function won't work.
#reload = if a previous version has been made, should it be loaded in to save time?
#texture = the default land colour palette to use. desert is best - check online for others
#rescale = variable used to rescale data (bigger >1 or smaller <1)

dem_base_map <- function(SpatRast, sea_level = 0, z_scale, name, save, resolution, reload = FALSE, texture = "desert", rescale = 1){
  
  pacman::p_load(magick)
  
  #clean up the name variable
  name <- str_replace_all(str_to_lower(name), " |-", "_")
  
  #clean up the resolution variable
  resolution <- as.character(resolution)
  
  #create paths to where we will/have saved the array and matrix information
  array <- glue("{save}/{name}_{resolution}m_array")
  matrix <- glue("{save}/{name}_{resolution}m_matrix")
  
  if (reload == TRUE & all(file.exists(c(array, matrix)))){#if the user wants to reload, and the files exist
    
    #read the files from save and put them in the global environment
    assign(glue("{name}_array"), readRDS(file = array), envir =  globalenv())   
    assign(glue("{name}_matrix"), readRDS(file = matrix), envir = globalenv())
    
    #print a message
    print(glue("{resolution}m array and matrix reloaded from a previous save and added to global environment as: '{name}_array' and '{name}_matrix'."))
    
  } else {#if the user doesn't want to reload and/or the files don't exist
    
    #convert the raster to a matrix
    area_matrix <- raster_to_matrix(SpatRast)
    
    #rescale the matrix if needed
    area_matrix <- resize_matrix(area_matrix, scale = rescale)
    
    #create a bathymetry version for water colours (remove everything above the sea level variable)
    area_bathymetry <- area_matrix
    area_bathymetry[area_bathymetry > sea_level] <- NA
    
    #create a water colour palettte
    bathy_palette <- colorRampPalette(c("gray5", "midnightblue", "blue4", "blue2", "blue", "dodgerblue", "lightblue"), bias = 0.5)(256)
    
    #create the core layers, a ray shade matrix, ambient shade matrix, and texture matrix
    ray_matrix <- ray_shade(area_matrix, zscale = z_scale)
    print("Rayshade matrix created.")
    
    lam_matrix <- lamb_shade(area_matrix, zscale = z_scale)
    print("Lambert shade matrix created.")
    
    amb_matrix <- ambient_shade(area_matrix, zscale = z_scale)
    print("Ambient occlusion matrix created.")
    
    tex_matrix <- texture_shade(area_matrix, detail = 1)
    print("Texture shade matrix created.")
    
    #if there is bathymetry to do, create the bathymetry information
    if (!all(is.na(area_bathymetry))){#note there is not always bathymetry, e.g. if the sea level was set to -100000, or if the target is inland.
      bath_array <- height_shade(area_bathymetry, texture = bathy_palette)
      print("Bathymetry matrix created.")
    }
    
    #combine core layers to form the area_array
    area_array <- area_matrix |> 
      sphere_shade(texture = texture, zscale = 1) |> 
      add_shadow(ray_matrix, max_darken = 0.3) |> 
      add_shadow(lam_matrix) |> 
      add_shadow(amb_matrix) |>
      add_shadow(tex_matrix)
    
    print("Core array created.")
    
    if (!all(is.na(area_bathymetry))){#same logic as bathymetry section above
      area_array <- area_array |> 
        add_overlay(generate_altitude_overlay(bath_array, area_matrix, sea_level, sea_level))
      print("Bathymetry maxtrix added.")
    }
    
    #bring the array and matrix to the global environment
    assign(glue("{name}_array"), area_array, envir = globalenv())
    assign(glue("{name}_matrix"), area_matrix, envir = globalenv())
    
    #save the array and associated matrix so they don't have to be recalculated every time
    saveRDS(area_array, glue("{save}/{name}_{resolution}m_array"))
    saveRDS(area_matrix, glue("{save}/{name}_{resolution}m_matrix"))
    
    #write a message
    print(glue("{resolution}m array and matrix saved to: '{save}/'."))
    print(glue("{resolution}m array and matrix added to global environment as: '{name}_array' and '{name}_matrix'."))
    
  }
  
}