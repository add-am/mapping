#inputs: 
#dem <- the digital elevation model data
#region <- the area which you want the map to be created. MUST BE A SHAPEFILE
#zscale <- the height "ratio", i.e. how exaggerated should the elevations be? 10 is good for
#the 30m dataset
#sealevel <- where you want the waterline to be 0 is normal water level
#highlight <- do you want the og region you selected to highlighted?
#rivers <- do you want the top 50 rivers by length in the region to be highlighted?
#preload <- do you want to try preload the map from a saved matrix and array?

n3_dem_base_map <- function(dem, region, zscale = 10, sealevel = 0, highlight = FALSE, rivers = FALSE, preload = TRUE){
  
  #disable s2 geometry
  sf_use_s2(FALSE)
  
  #get the name of the region we are working in
  regi_name <- region[[1]]
  
  #mutate name for globalenv
  regi <- gsub("-", "_", regi_name)

  #get paths to files
  array <- glue("{save_path}matrixes_and_arrays/{regi_name}_3D-base-map-array_sea-level-{sealevel}m_resolution-{data_set}m")
  matrix <- glue("{save_path}matrixes_and_arrays/{regi_name}_3D-base-map-matrix_sea-level-{sealevel}m_resolution-{data_set}m")
  map <- glue("{save_path}{regi_name}_3D-base-map_sea-level-{sealevel}m_resolution-{data_set}m")
  
  #bring the new path to life
  dir.create(glue("{save_path}matrixes_and_arrays/"))
  
  if (preload == T && file.exists(array) && file.exists(matrix)){
    
    #read the files from save and put them in the global environment
    assign(glue("base_map_{names2}"), readRDS(file = array), envir =  globalenv())
    assign(glue("dem_matrix_{names2}"), readRDS(file = matrix), envir = globalenv())
    
  } else {
    
    #Specify the area in which we are working. 
    buff <- st_buffer(region, units::set_units(0.01, degree))
    
    #take extent of the slightly bigger polygon (don't accidentally cut things off)
    location_extent <- extent(buff)
    
    #Use crop to cut down the data set to specified region
    dem_cropped <- crop(dem, location_extent)
    
    #Convert the raster to a matrix. (matrix are more digestible by rayshader)
    dem_cropped_matrix <- raster_to_matrix(dem_cropped)
    
    #save the matrix back to the global env
    assign("dem_matrix", dem_cropped_matrix, envir = globalenv())
    
    #save the matrix to the output folder
    saveRDS(dem_cropped_matrix, file = matrix)
    
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
    
    if (highlight == F){
      
      #Plot the base map using the layers calculated above.
      base_map <- dem_cropped_matrix %>%
        sphere_shade(zscale = zscale, texture = "desert") %>% 
        add_shadow(raymat, max_darken = 0.2) %>%
        add_shadow(ambmat, max_darken = 0.2) %>%
        add_shadow(texturemat, max_darken = 0.2) %>% 
        add_water(detect_water(dem_cropped_matrix, zscale = 1), color = "lightblue") %>% 
        add_overlay(generate_altitude_overlay(bathy_elev, dem_cropped_matrix, 0, 0))
      
    } else if (highlight == T) { #add highlights around regions
      
        #assume that the basins dataset is freely available
        islands <- st_read(dsn = "data/shapefiles/Drainage_basins.shp")
        
        #assume that the qld dataset is freely available
        qld <- st_read(dsn = "data/shapefiles/qld.shp")
        
        #match crs
        islands <- st_transform(islands, proj_crs)
        qld <- st_transform(qld, proj_crs)
        
        #select the coral sea islands and whitsunday island
        islands <- islands %>% 
          filter(BASIN_NAME %in% c("Coral Sea", "Whitsunday Island", "Hinchinbrook Island"))
        
        #crop to the region
        islands <- st_crop(islands, location_extent)
        
        if (nrow(islands) != 0){
        
          #merge islands
          islands <- islands %>% 
            st_union(by_feature = F) %>% st_combine() %>%
            nngeo::st_remove_holes() %>% 
            st_sf() %>% 
            mutate("{colnames(region)[1]}" := "Islands", .before = geometry)
          
          #add these islands to the region
          region <- rbind(region, islands)
        }
        
        #merge everything again
        region <- region %>% 
          st_union(by_feature = F) %>% st_combine() %>%
          nngeo::st_remove_holes() %>% 
          st_sf()
        
        #get bbox of buffered region
        bbox <- st_bbox(buff)
        
        #turn bbox coords into a usable list
        border_list = list(matrix(c(bbox[1], bbox[3], bbox[3], bbox[1], bbox[1], 
                                    bbox[2], bbox[2], bbox[4], bbox[4], bbox[2]),
                                    ncol = 2))
        
        #turn list into a simple feature 
        border <- st_as_sf(st_sfc(st_polygon(border_list)))
        
        #make crs equal
        st_crs(border) <- st_crs(region)
        
        #crop qld to region of interest
        qld <- st_crop(qld, border)
        
        #drop everything but geometry and buffer slightly
        qld <- qld %>% 
          st_union(by_feature = F) %>% st_combine() %>%
          nngeo::st_remove_holes() %>% 
          st_sf()
        
        #take the difference of border and qld
        ocean <- st_difference(border, qld)
        
        #take the difference of border and main region for outer shadow
        outer <- st_difference(border, region)
        
        #take the difference of outer and ocean to keep ocean highlight
        land_outer <- st_difference(outer, ocean)
        
        #create the overlays
        overlay1 <- generate_polygon_overlay(region, extent = location_extent,
                                             heightmap = dem_cropped_matrix,
                                             palette = "transparent",
                                             linecolor = "black", linewidth = "8")
        
        overlay2 <- generate_polygon_overlay(region, extent = location_extent,
                                             heightmap = dem_cropped_matrix,
                                             palette = "transparent",
                                             linecolor = "white", linewidth = "6")
        
        overlay3 <- generate_polygon_overlay(land_outer, extent = location_extent,
                                             heightmap = dem_cropped_matrix,
                                             palette = "black",
                                             linecolor = "black", linewidth = "0")
        
        #Plot the base map using the layers calculated above and add the overlays
        base_map <- dem_cropped_matrix %>%
          sphere_shade(zscale = zscale, texture = "desert") %>% 
          add_shadow(raymat, max_darken = 0.2) %>%
          add_shadow(ambmat, max_darken = 0.2) %>%
          add_shadow(texturemat, max_darken = 0.2) %>% 
          add_water(detect_water(dem_cropped_matrix, zscale = 1), color = "lightblue") %>% 
          add_overlay(generate_altitude_overlay(bathy_elev, dem_cropped_matrix, 0, 0)) %>%  #----------------make variable by sealevel
          add_overlay(overlay1, alphalayer = 1) %>%
          add_overlay(overlay2, alphalayer = 1) %>% 
          add_overlay(overlay3, alphalayer = 0.7)
        
    } else {
        print("ERROR: highlight must be TRUE or FALSE")
    }
    
    if (rivers == T){
      
      #convert the bbox to osm friendly coords
      osm_bbox = c(bbox[1],bbox[2], bbox[3],bbox[4])
      
      #query waterways
      waterways <- opq(osm_bbox, timeout = 100) %>% 
        add_osm_feature("waterway") %>% 
        osmdata_sf()
      
      #transform and filter data to only get line data
      waterways <- st_transform(waterways$osm_lines, crs = crs(proj_crs))
      
      #filter to remove columns and NAs, and group by name
      waterways <- waterways %>% 
        select(name, waterway, geometry) %>% 
        filter(!is.na(name) & !is.na(waterway)) %>% 
        group_by(name) %>% 
        summarise(geometry = st_union(geometry)) %>% 
        ungroup()
      
      #crop waterways to only within focus region
      waterways <- st_intersection(waterways, region)
      
      #add a length of rivers
      waterways <- waterways %>% 
        mutate(length = st_length(geometry))
      
      #take the top 50 rivers to be used for mapping
      main_waterways <- waterways %>% 
        slice_max(order_by = length, n = 50)
  
      #create river overlays
      river_overlay1 <- generate_line_overlay(main_waterways, 
                                              extent = location_extent,
                                              linewidth = 6, color = "darkblue",
                                              heightmap = dem_matrix)
      
      river_overlay2 <- generate_line_overlay(main_waterways, 
                                              extent = location_extent,
                                              linewidth = 4, color = "dodgerblue",
                                              heightmap = dem_matrix)
      
      #add overlays to base_map
      base_map <- base_map %>% 
        add_overlay(river_overlay1, alphalayer = 1) %>% 
        add_overlay(river_overlay2, alphalayer = 1)
    
    } else if (rivers == F){
      
    } else {
      
      print("ERROR: rivers must be TRUE or FALSE")
      
    }
    
    w <- 1920
    h1 <- dim(dem_matrix)[1]
    h2 <- dim(dem_matrix)[2]
    h = round(w/(h1/h2), 0)
    
    #plot the map in 3D
    plot_3d(base_map, dem_cropped_matrix, zscale = zscale, soliddepth = min(dem_matrix)-200,
            water = F, background = "white", shadowcolor = "grey50", 
            shadowdepth = min(dem_matrix)-400, theta = 180, phi = 35, fov = 16, zoom = 0.6,
            windowsize = c(w, h))
    
    #add water
    render_water(dem_cropped_matrix, zscale = zscale, waterdepth = sealevel, wateralpha = 0.5)
    
    #sleep to allow image to render
    Sys.sleep(15)
    
    #Basic snapshot render of the current RGL view, no filename opens in view pane,
    #adding file name saves as png, can do generic things such as add title text.
    render_snapshot(filename = map)
    
    #close the rgl window
    rgl::close3d()
    
    #return the base_map
    assign("base_map", base_map, envir = globalenv())
    
    #save the base_map array so that it does not have to be recalculated every time
    saveRDS(base_map, file = array)
    
    #print reminder message
    print(glue("A 3D version of the basemap has been saved to the file location:
                 {save_path}{regi_name}, don't forget to check it out!"))
  }
  
  #get the location extent 
  buff <- st_buffer(region, units::set_units(0.01, degree))
  location_extent <- extent(buff)
  
  #assign to globalenv
  assign(glue("location_extent_{names2}"), location_extent, envir =  globalenv())
  
  #get the bounding box of the focus region
  bbox <- st_bbox(region)
  
  #convert the bbox to osm friendly coords
  osm_bbox = c(bbox[1],bbox[2], bbox[3],bbox[4])
  
  #use bbox to query osm database
  places <- opq(osm_bbox, timeout = 100) %>% 
    add_osm_feature("place") %>% 
    osmdata_sf()
  
  #transform data and filter for point data
  places <- st_transform(places$osm_points, crs = crs(proj_crs))
  
  #filter to remove NAs and smaller places
  places <- places %>% 
    select(name, place, geometry) %>% 
    filter(!is.na(name) & !is.na(place))
  
  #extract the coordinates from the sf data as a data frame
  town_names <- as_tibble(sf::st_coordinates(places)) %>% 
    rename("long" = "X", "lat" = "Y")
  
  #extract the names for each as a data frame
  temp <- as_tibble(places) %>% 
    dplyr::select(name)
  
  #combine the coordinates and the names
  town_names <- cbind(temp, town_names)
  
  #arrange by name
  town_names <- town_names %>% 
    arrange(name)
  
  #assign the table to the global env
  assign(glue("town_names_{names2}"), town_names, envir =  globalenv())
  
  #collate all globalenv to list
  global_list <- list(glue("base_map_{names2}"), glue("dem_matrix_{names2}"),
                      glue("town_names_{names2}"), glue("location_extent_{names2}"))
  
  #assign the list to the globalenv
  assign("global_list", global_list, envir =  globalenv())
  
}


  
  
  
  
  