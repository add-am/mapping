#A short script to ensure data is provided correctly

#------------------
#The Great Barrier Reef 30m Digital Elevation Model dataset is so large that it is provided in four 
#separate files. The code chuck below checks if a merged file exists, and if not reads the four files, 
#merges them, and saves the output.

#path to file
path <- "data/elevation/gbr_30m_2020.tif"

#loop
if (file.exists(path)) {
  
  print("File already exists in elevation folder, data processing complete.")
  
} else {
  
  #read in each file from raw folder
  gbr30mA <- raster::raster("data/raw/Great Barrier Reef Bathymetry 2020 30m/
                    Great_Barrier_Reef_A_2020_30m_MSL_cog.tif")
  gbr30mB <- raster::raster("data/raw/Great Barrier Reef Bathymetry 2020 30m/
                    Great_Barrier_Reef_B_2020_30m_MSL_cog.tif")
  gbr30mC <- raster::raster("data/raw/Great Barrier Reef Bathymetry 2020 30m/
                    Great_Barrier_Reef_C_2020_30m_MSL_cog.tif")
  gbr30mD <- raster::raster("data/raw/Great Barrier Reef Bathymetry 2020 30m/
                    Great_Barrier_Reef_D_2020_30m_MSL_cog.tif")
  
  #change the origins of each to match (changing from values such as 0.00015 to
  #have all origins as 0). This allows the merge function to combine the rasters
  origin(gbr30mA) <- 0
  origin(gbr30mB) <- 0
  origin(gbr30mC) <- 0
  origin(gbr30mD) <- 0
  
  #merge the four rasters
  gbr30m_merge <- raster::merge(gbr30mA, gbr30mB, gbr30mC, gbr30mD)
  
  #save the merged output - note this take along time. Don't run unless necessary
  writeRaster(gbr30m_merge, filename = "data/elevation/gbr_30m_2020.tif",
              format = "GTiff", overwrite = TRUE)
  
}

#clean up
rm(path)

#------------------
#Although Great Barrier Reef 100m Digital Elevation Model dataset is small enough to be downloaded 
#in one file we will still keep the original data over in the raw folder alongside the 30m dataset, 
#and create a copy for the data/elevation/ folder. The chunk below does this if a copy does not already exist.

#path to file
path_old <- "data/raw/Great Barrier Reef Bathymetry 2020 100m/Great_Barrier_Reef_2020_100m_MSL_cog.tif"
path_new <- "data/elevation/gbr_100m_2020.tif"

#loop
if (file.exists(path_new)) {
  
  print("File already exists in elevation folder, data copying complete.")
  
} else {
  
  file.copy(from = path_old, 
            to = path_new)
}

#clean up
rm(path_old, path_new)

#------------------
#Environmental Protection Policy Datasets
#The Environmental Protection Policy (EPP) datasets are shapefiles used to subdivide areas by water 
#type, management intent, environmental value, etc. These shapefiles are extremely detailed and need 
#to be restricted to the areas of interest. The code chunk below crops the shapefiles to the Northern 
#Three region and saves the output if the files do not already exist.

#create extent to use for crop
extent <- data.frame(lon = c(144.45, 151.10), lat = c(-15.76, -22.25))
extent <- extent |> sf::st_as_sf(coords = c("lon", "lat"), crs = "EPSG:7844") |>
  sf::st_bbox()  |> sf::st_as_sfc()

#get list of file names
file_names <- list("Env_Value_Zones", "water_types", "management_intent")

for (i in 1:length(file_names)){
  
  #create path to file
  path <- glue::glue("data/shapefiles/EPP_Water_{file_names[i]}_Cropped.shp")
  
  #loop
  if (file.exists(path)) {
    
    print("File already exists in shapefiles folder, data processing complete.")
    
  } else {
    
    #turn of spherical geometry
    sf::sf_use_s2(FALSE)
    
    #Import the file
    file <- sf::st_read(dsn = "data/raw/shapefiles", 
                        layer = glue::glue("EPP_Water_{file_names[i]}_Qld"))
    
    #update crs
    file <- sf::st_transform(file, "EPSG:7844")
    
    #crop the file
    file_crp <- sf::st_crop(file, extent)
    
    #save the file
    sf::st_write(file_crp, glue::glue("data/shapefiles/EPP_Water_{file_names[i]}_Cropped.shp"))
    
  }
  
}

#clean up
rm(extent, path, file_names, i)

# -------------------------
#Regional Ecosystem Biodiversity
#The Regional Ecosystem  Biodiversity (RE) datasets are downloaded as geopackage files. They are 
#extremely detailed and extend far beyond the northern three region. The code chunk below crops the
#data to only have areas that are at least partially within the n3 regions.

#read in basins data
n3_basins <- sf::st_read(dsn = "data/shapefiles/Drainage_basins.shp")

#select northern three basins and combine into one large multipolygon
n3_basins <- n3_basins |> 
  dplyr::filter(BASIN_NAME %in% c("Ross", "Black", "Don", "Proserpine", "O'Connell", "Pioneer", 
                                  "Plane", "Daintree", "Mossman", "Barron", "Johnstone", "Tully", 
                                  "Murray", "Herbert", "Mulgrave-Russell")) |> sf::st_union()

#get path to read layers
read_path <- "data/raw/Regional_Ecosystem_Geopackage_Files/"

#get path to save layers
save_path <- "data/regional_ecosystems/"

#bring that save path to life
dir.create(save_path)

#get list of files in the read folder without their extension
file_list <- tools::file_path_sans_ext(list.files(read_path))

#for each file in list
for (i in 1:length(file_list)){
  
  #if the cropped and saved version exists
  if (file.exists(glue::glue("{save_path}{file_list[i]}_cropped.gpkg"))){
    
    print("Cropped file already exists in regional ecosystems folder, layer processing complete.")
    
  } else {
    
    #read in the regional ecosystem layer
    re_layer <- sf::st_read(dsn = glue::glue("{read_path}{file_list[i]}.gpkg"))
  
    #transform the layer
    re_layer <- sf::st_transform(re_layer, "EPSG:7844")
    
    #create a T F list of polygons that intersect the n3 basins
    #intersects <- lengths(sf::st_intersects(re_layer, n3_basins)) > 0
    
    #get x within y
    re_layer <- sf::st_intersection(re_layer, n3_basins)
    
    #select only rows with T for intersection
    #re_layer <- re_layer |> dplyr::mutate(within = intersects) |> dplyr::filter(within == T)
    
    #save the file 
    sf::st_write(re_layer, dsn = glue::glue("{save_path}{file_list[i]}_cropped.gpkg"),
                 delete_dsn = T)
  }
}

 #clean up
rm(n3_basins, read_path, save_path, file_list, i, intersects, re_layer)



