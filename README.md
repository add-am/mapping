# Mapping Scripts: Northern Three

The objective of this repo is to programatically generate standard maps for the Northern Three partnerships. This repo includes the creation of 2D and 3D maps.

Currently the maps generated include:
- 3D Digital Elevation Model maps (with bathymetry)

The data to run these scripts must be downloaded from its original source as files are too large to be stored on the repo. An overview on how to obtain data is provided below.

## Data Sources

Note: If this is the first time the repo is run on the machine, the folder structure with the data folder must be created manually. The rough structure is shown below:

```bash

├───data
│   ├───dims
│   │   ├───annual
│   │   └───monthly
│   ├───elevation
│   ├───raw
│   └───shapefiles
│       ├───metadata

```

### Shapefiles

Shapefiles are the only files small enough to realistically be stored on the repo. They are needed for all analysis and form the backbone of each script. They are stored under *data/shapefiles/*. 

#### Basins and Sub Basins

The Northern Three reporting regions are broken into multiple basins and sub-basins. The shapefiles for these areas should already be present in the **data/shapefiles** folder, Don't change the name if they are. 
Should the files not be present, they can be found on QSpatial [here](https://qldspatial.information.qld.gov.au/catalogue/custom/index.page).

Search:

-   Drainage basins - Queensland
-   Drainage basins sub areas - Queensland

And download in the following format:

-   Shapefile - SHP - .shp
-   GDA2020 geographic 2D (EPSG:7844)

#### Queensland Polygon

Many of the scripts in this repo also use a queensland polygon as reference, context, or extent. Along with the basins, the queensland shapefile should already be present in the **data/shapefiles** folder. Dont change the name if
they are. Should they not be present, they can be found on the Aus Gov's data site [here](https://data.gov.au/dataset/ds-dga-2dbbec1a-99a2-4ee5-8806-53bc41d038a7/distribution/dist-dga-a2440bb6-2ad2-4c20-aaab-c0ceb013033e/details?q=)
Simply click on the download button, as it is already in the GDA2020 geographic 2D (EPSG:7844) format.

> If you need to download the Queensland polygon again you will have to update the names of the files to "qld" (That includes all accompaying files: .cpg, .dbf, .prj, .shp, .shx).

#### TBC (marine boundaries etc.)
