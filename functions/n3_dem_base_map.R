#inputs: 
#dem <- the digital elevation model data
#region <- the area which you want the map to be created. MUST BE A SHAPEFILE
#zscale <- the height "ratio", i.e. how exaggerated should the elevations be? 10 is good for
#the 30m dataset
#sealevel <- where you want the waterline to be 0 is normal water level
#highlight <- do you want the og region you selected to highlighted?


n3_dem_base_map <- function(dem, region, zscale = 10, sealevel = 0, highlight = FALSE){
  
  #get the name of the region we are working in
  regi_name <- region$region
  
  #Specify the area in which we are working. 
  buff <- st_buffer(region, units::set_units(0.01, degree))
  
  #take extent of the slightly bigger polygon (don't accidentally cut things off)
  location_extent <- extent(buff)
  
  #Use crop to cut down the data set to specified region
  dem_cropped <- crop(dem, location_extent)
  
  #Convert the raster to a matrix. (matrix are more digestible by rayshader)
  dem_cropped_matrix <- raster_to_matrix(dem_cropped)
  
  #save the matrix to the global env
  assign("dem_matrix", dem_cropped_matrix, envir = globalenv())
  
  #create simple overlays:
  #create a ray shade matrix. zscale affects shadows. Smaller num = bigger shadow
  raymat <- ray_shade(dem_cropped_matrix, zscale = zscale, lambert = TRUE)
  
  #create an ambient shade matrix. zscale affects shadows as above.
  ambmat <- ambient_shade(dem_cropped_matrix, zscale = zscale)
  
  #create a texture map for additional shadows and increased detail.
  texturemat <- texture_shade(dem_cropped_matrix, detail = 1, contrast = 10, 
                              brightness = 10)
  
  #create more complex overlays:
  #bathymetry; copy original matrix to new matrix
  bathy_matrix <- dem_cropped_matrix
  
  #cap all matrix values greater than the desired sea level to NA
  bathy_matrix[bathy_matrix > sealevel] = NA
  
  #create a colour palette suitable to the overlay (e.g. blues). Note that with
  #more zoomed in maps (i.e. with less range of bathymetry) the bias should be
  #adjusted. For large maps, small numbers, and vice versa
  bathy_palette <- colorRampPalette(c("gray5", "midnightblue", "blue4", "blue2", 
                                      "blue", "dodgerblue", "lightblue"), 
                                    bias = 2)(256)
  
  #create an overlay using the new matrix and colour palette
  bathy_elev <- height_shade(bathy_matrix, texture = bathy_palette)
  
  #Plot the base map using the layers calculated above.
  base_map <- dem_cropped_matrix %>%
    sphere_shade(zscale = zscale, texture = "desert") %>% 
    add_shadow(raymat, max_darken = 0.2) %>%
    add_shadow(ambmat, max_darken = 0.2) %>%
    add_shadow(texturemat, max_darken = 0.2) %>% 
    add_water(detect_water(dem_cropped_matrix, zscale = 1), color = "lightblue") %>% 
    add_overlay(generate_altitude_overlay(bathy_elev, dem_cropped_matrix, 0, 0))
  
  #plot the map in 3D
  plot_3d(base_map, dem_cropped_matrix, zscale = 10, soliddepth = -300,
          water = F, background = "white", shadowcolor = "grey50", 
          shadowdepth = -550, theta = 180, phi = 22, fov = 16.16, zoom = 0.46,
          windowsize = c(50, 50, 3840, 2160)) #normal 3840 2160, square 2160 2160
  
  #add water
  render_water(dem_cropped_matrix, zscale = zscale, waterdepth = sealevel, wateralpha = 0.5)
  
  #change camera location
  render_camera(theta = 180, phi = 35, zoom = 0.59, fov = 16)
  
  #sleep to allow image to render
  Sys.sleep(15)
  
  #Basic snapshot render of the current RGL view, no filename opens in view pane,
  #adding file name saves as png, can do generic things such as add title text.
  render_snapshot(width = 3840, height = 2160,
                  filename = glue("{save_path}{regi_name}"))
  
  rgl::close3d()
  
  #return the base_map
  assign("base_map", base_map, envir=globalenv())
  
  #print reminder message
  print(glue("A 3D version of the basemap has been saved to the file location:
             {save_path}{regi_name}, don't forget to check it out!"))
  
}

  
  
  
  
  