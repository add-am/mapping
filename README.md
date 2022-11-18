# Mapping Scripts: Northern Three

The objective of this repo is to programatically generate standard maps for the Northern Three partnerships. This repo includes the creation of 2D and 3D maps.

Currently the maps generated include:
- 3D Digital Elevation Model maps (with bathymetry)

The data to run these scripts must be downloaded from their original source as files are too large to be stored on the repo. An overview on how to obtain data is provided below.

## Data Sources

Note: If this is the first time the repo is run on the machine then some of the folder structure will be missing and must be created manually. The rough structure is shown below:

```bash

├───data
│   ├───dims
│   ├───elevation
│   ├───raw
│   │   ├───Biodiversity_status_of_pre_clearing_regional_ecosystems
│   │   ├───Biodiversity_status_of_remnant_regional_ecosystems
│   │   ├───Great Barrier Reef Bathymetry 2020 100m
│   │   ├───Great Barrier Reef Bathymetry 2020 30m
│   │   ├───QLD_LANDUSE_June_2019
│   │   │   └───QLD_LANDUSE_June_2019.gdb
│   │   └───shapefiles
│   │       └───metadata
│   ├───regional_ecosystems
│   └───shapefiles
│       └───metadata
```

### Shapefiles

Shapefiles are the only files small enough to realistically be stored on the repo. They are needed for all analyses and form the backbone of each script. They are stored under *data/shapefiles/*. 

#### Basins and Sub Basins

The Northern Three reporting regions are broken into multiple basins and sub-basins. The shapefiles for these areas should already be present in the **data/shapefiles** folder, Don't change the name if they are. 
Should the files not be present, they can be found on QSpatial [here](https://qldspatial.information.qld.gov.au/catalogue/custom/index.page).

Search:

-   Drainage basins - Queensland
-   Drainage basins sub areas - Queensland

And download each in the following format:

-   Shapefile - SHP - .shp
-   GDA2020 geographic 2D (EPSG:7844)

#### Queensland Polygon

Many of the scripts in this repo also use a queensland polygon. Along with the basins, the queensland shapefile should already be present in the **data/shapefiles** folder. Dont change the name if it is. Should they not be present, 
they can be found on the Aus Gov's data site [here](https://data.gov.au/dataset/ds-dga-2dbbec1a-99a2-4ee5-8806-53bc41d038a7/distribution/dist-dga-a2440bb6-2ad2-4c20-aaab-c0ceb013033e/details?q=)
Simply click on the download button, as it is already in the GDA2020 geographic 2D (EPSG:7844) format.

> If you need to download the Queensland polygon again you will have to update the names of the files to "qld" (That includes all accompaying files: .cpg, .dbf, .prj, .shp, .shx).

#### Environmental Protection Policies

Some scripts further subdivide basins using data provided by the Environmental Protection Policy (EPP) shapefiles. These shapefiles are actually quite large and must be cropped before they can be stored on GitHub. The cropped shapefiles
Should be present in the **data/shapefiles** folder, Don't change the names if they are. Should the cropped files not be present, the original files can be found on QSpatial 
[here](https://qldspatial.information.qld.gov.au/catalogue/custom/index.page).

Search:

- Environmental Protection (Water and Wetland Biodiversity) Policy 2019 - Management Intent - Queensland
- Environmental Protection (Water and Wetland Biodiversity) Policy 2019 - Environmental Value Zones - Queensland
- Environmental Protection (Water and Wetland Biodiversity) Policy 2019 - Water Types - Queensland

And download each in the following format:

-   Shapefile - SHP - .shp
-   GDA2020 geographic 2D (EPSG:7844)

> **NOTE** The original EPP shapefiles are too large to upload to GitHub. Store them under **data/raw/shapefiles/** and run the data preprocessing script to produced the cropped files. The cropped files are small enough to upload to Github

#### GBRMPA Marine Water Bodies

Subdivisions of the marine zone are completed using the GBRMPA shapefiles (designates water body type such as enclosed, open, midshelf). The dataset is provided within the "gisaimsr" R package that can be downloaded within R. 
A guide on installing and loading this package can be found [here](https://open-aims.github.io/gisaimsr/index.html), and an introduction to the available datasets is found 
[here](https://open-aims.github.io/gisaimsr/articles/examples.html). Note that because this data is provided via a package, there is no need to actually download the files and store them in the shapefiles folder alongside the other. 
Data is provided in the GDA2020 geographic 2D (EPSG:7844) format.

### Digital Elevation Model Data

Digitial Elevation Model (DEM) data is a 3 dimension spatial dataset that provides a height (z-axis) for every cell in the x-y axis. The data used for this script is provided by AUS SEABED for free as a GeoTIFF and can be found 
[here](https://portal.ga.gov.au/persona/marine). To find the data:

-   Select "Layers" from the toolbar at the top of the page
-   Select "Elevation and Depth" and then "Bathymetry - Compilations"
-   Scroll/search for "Great Barrier Reef Bathymetry 2020 30m"
-   Click the "i" icon and click "More Details" (The download here button sometimes does not work)
-   On the new page download the data from the link under "Description"

Repeat this process for the 100m dataset. This is a courser version of the 30m dataset and can be useful to create example/trial maps at a much faster rate. Once the data has been downloaded extract each folder and save them under 
**data/raw/**, Don't change the name of the folders. 

if you inspect the 30m data you might notice that the data is split into 4 GeoTIFFs, this is due to the large size of the files. A data preprocessing script is available to combine these files, and will save the output under 
**data/elevation/** ready to be used by subsequent scripts.

### Regional Ecosystems

Regional ecosystem data is used to estimate changes in vegetation cover. These layers are updated every few (~2-3) years and are found on the QSpatial website [here](https://qldspatial.information.qld.gov.au/catalogue/custom/index.page).
For information on each re type refer to the csv spreadsheet that is available [here](https://www.qld.gov.au/environment/plants-animals/plants/ecosystems/descriptions), All links are relevant and useful. To find the data, using the
first link provided:

- Click on the "Regional Ecosystem Series" button on the bottom left of the page
- Use the related resources tabs to select "Biodiversity status of pre-clearing regional ecosystems – Queensland" (Repeat this for the "Biodiversity status of 2019 remnant regional ecosystems - Queensland").

And download the data in the following format:

- GeoPackage 1.0 - GEOPACKAGE_1.0 - .gpkg
- GDA2020 geographic 2D (EPSG:7844)

Once downloaded this data must be unzipped and stored under **data/raw/**. Each folder must be renamed to "Biodiversity_status_of_pre_clearing_regional_ecosystems" and "Biodiversity_status_of_remnant_regional_ecosystems" respectively.
The contents within the folders does not need to be renamed.

> These files are quite large and should be pre-processed to ensure efficent script runtime. Even once pre-processed they are too large to be uploaded and must be downloaded on each new machine.

