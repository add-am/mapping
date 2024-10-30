# Spatial Analyses: Northern Three (N3)

Written by [Adam Shand.](https://github.com/add-am)

This README provides a guide to the spatial analysis repo, there are multiple components to the README:

- [1. Setup](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#1-get-started) (How to get started).
- [2. Repo Layout](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#2-repo-layout) (Repo structure and overview).
- [3. Rules for Contribution](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#3-rules-for-contribution) (How to contribute to this repo).
- [4. Scripts](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#4-scripts) (The most important notes for scripts).
- [5. Data](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#5-data) (Where to find data and how to store it correctly).
- [6. Additional Resources](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#6-additional-resources) (Extra information).

# 1. Set Up

## 1.1 GitHub and Cloning

To use this repo you must know how to use GitHub, and how to clone a repository. Our Tech Officer Brie Sherow has created a training resource to 
[learn the basics](https://netorgft4508071.sharepoint.com/:p:/r/sites/TechnicalOfficersTeam/_layouts/15/Doc.aspx?action=edit&sourcedoc=%7Bf631565b-a90c-4255-acff-378e9746c774%7D&wdOrigin=TEAMS-WEB.teamsSdk.openFilePreview&wdExp=TEAMS-CONTROL&web=1) 
(also found under "Technical Officers Team/File Sharing/GitHub team training.pptx"). If you get stuck, the GitHub website has a short guide for 
[installation and configuration.](https://docs.github.com/en/desktop/overview/getting-started-with-github-desktop) and a step-by-step method for 
[cloning a repository.](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) The website 
[Medium](https://medium.com/mindorks/what-is-git-commit-push-pull-log-aliases-fetch-config-clone-56bc52a3601c) has a extensive guide on Git (which underlies GitHub).

> [!Note]
> You should make sure to also install the [GitHub desktop application](https://desktop.github.com/), it is important to understand that this is distinct from the GitHub that you are viewing through the web browser.


## 1.2 R and Rstudio

The scripts in this repo run on R, you will need to install [R](https://cran.r-project.org/) and [RStudio](https://posit.co/products/open-source/rstudio/). [Hands-On Programming with R](https://rstudio-education.github.io/hopr/starting.html#starting) explains this well. 
You can then install most packages from the [CRAN](https://cran.r-project.org/web/packages/available_packages_by_name.html) using the function: `install.packages("examplepackage")`. 
Packages are listed at the start of the script and you can install packages on a per-script basis.

## 1.3 RTools

All scripts in this repo rely on additional, specialised, packages that are not directly avaiable on the CRAN. To install these packages we need to install the 
[RTools](https://cran.r-project.org/bin/windows/Rtools/rtools42/rtools.html) application, selecting the default options everywhere.

Once RTools has been downloaded and installed on your computer a custom function has been written: `package_handling.R` that will handling the download and installation of any further packages. For more information, 
[Issue 85](https://github.com/Northern-3/spatial-analyses/issues/85) was raised to address this component.

> Installing packages can cause a headache, if the custom function breaks, this [blog post](https://www.dataquest.io/blog/install-package-r/) explains the steps quite well.

## 1.4 QGIS

Several datasets need their file type to be converted for the script to work, you will need to install [QGIS](https://www.qgis.org/en/site/forusers/download.html) for this. QGIS is a 
free program. Conversion of data types is covered in more detail under [5. Data](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#5-data).

## 1.5 Quarto

This project is built on the Quarto framework, the new version of RMarkdown. If you are not familar with Quarto or RMarkdown please review the 
[Quarto](https://quarto.org/docs/guide/) guide to get acquainted, with emphasis on [projects](https://quarto.org/docs/projects/quarto-projects.html) and 
[HTML basics](https://quarto.org/docs/output-formats/html-basics.html).

# 2. Repo Layout

After cloning this repository the folder and file layout should look something like this:

![Top Level Folder Example](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/repo_layout_example.png?raw=true)

Below we will provide a brief explanation of each component. 

## 2.1 .quarto

Contains system files, do not touch. To learn more about quarto, review the pages provided in [1.5 Quarto.](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#15-quarto)

## 2.2 data

Contains all data, we will cover this in much more detail at [5. Data.](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#5-data)

## 2.3 functions

Chunks of code that are utilised across multiple scripts are stored here as functions. There is no need to touch unless you would like to create your own function, or a function breaks.

## 2.4 outputs

If a script produces an output, it will be stored here. The following code chunk is used to do this:

```R
#create the file path. Important: the folder name after "outputs/" should match the script name.
save_path <- here("outputs/n3_habitat_broad-vegetation-groups/")

#create the directory
dir.create(save_path)
```
## 2.5 references 

Contains all additional information/images/documents. Some of these documents are automatically referenced by scripts, others are for a human to read. The most important documents 
in this folder are:

- docx_style_guide (used for .docx renders, don't move or rename this file).
- file_naming_style_guide (used in [3. Rules for Contribution](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#3-rules-for-contribution)).
- spatial_naming_style_guide (used generally - provides context for all spatial terminology used).
- script_mindmap (used in [4.3 Scripts](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#43-script-order)).
- wq_aggregation_mindmap (isualises the workflow used for water quality analysis).

> There is plenty more reference material that may be of interest that can be found in this folder.

## 2.6 renders

Scripts in this repository can be "rendered" into html or word version of themselves and saved in this folder. These "rendered" documents are an easy-to-read version of the script
that allows new users to understand the script purpose. It is recommend that before running a script for the first time the rendered version is reviewed. To learn more about rendering,
review the pages provided in [1.5 Quarto.](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#15-quarto) To render a script, use the render button at the top of the 
RStudio UI:

![Render Example](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/render_example.png?raw=true)

## 2.7 scripts

Contains all scripts, we will cover this in much more detail at [4. Scripts.](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#4-scripts)

## 2.8 .gitignore 

Tells github what files to upload and what files to ignore, this is important for files >100mb as they cannot be uploaded to GitHub and must be ignored. 
To learn more go to [git-scm.](https://git-scm.com/docs/gitignore)

## 2.9 n3_spatial-analysis

This is the R project that every script is run through, more on this at [Posit.](https://support.posit.co/hc/en-us/articles/200526207-Using-RStudio-Projects)

## 2.10 _quarto.yml 

Contains script metadata/styling/formatting. There is no need to touch this. To learn more about quarto, review the pages provided in [1.5 Quarto.](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#15-quarto)

## 2.11 README 

This is the file right here that you are reading, learn about README documents [here.](https://www.freecodecamp.org/news/how-to-write-a-good-readme-file/)

# 3. Rules for Contribution

A personal project can be organised or disorganised however that person likes. But shared repositories require some semblance of structure. In this repo the following rules apply for 
naming folders and files:
1. **Never use capitals.** Many softwares are case sensitive and capitals can cause subtle errors (e.g. I vs l).
2. **Never use spaces.** Some softwares recognise spaces, some delete spaces, some mark spaces. Instead:
	- Use underscores "_" to seperate broad ideas. E.g. "n3_climate".
	- Use dashes "-" to seperate multiple words within the same idea. E.g. "sea-surface-temperature".
	- **Exception:** functions use **__ONLY__** underscores. (Look at "Names and Identifiers" in [R Objects](https://stat.ethz.ch/R-manual/R-devel/library/base/html/Quotes.html)).
3. **Scripts** follow the naming convention of **"who_broad-theme_specific-theme_order/context"** where:
	- who = who is the script relevant to? e.g. "n3", "dt", "mwi", "wt".
	- broad-theme = the overarching grouping of the script. Use this to group similar topics. E.g. "climate".
	- specific-theme (optional) = a subset of the broad-theme, useful for larger topics. E.g. "rainfall".
	- order/context (optional) = the order of the scripts + context of what the stage is. Used if a theme has multiple steps. E.g. "s1-analysis". (s = script).
4. **Top level data folders** follow the naming convention of **"who_broad-theme_specific-theme_order/context"** where:
	- who = who is the script relevant to? e.g. "n3", "dt", "mwi", "wt".
	- broad-theme = the overarching grouping of the script. Use this to group similar topics. E.g. "climate".
	- specific-theme (optional) = a subset of the broad-theme, useful for larger topics. E.g. "rainfall".
		+ **Exception:** data shared between scripts is named at the lowest common denominator. E.g. "n3_dem".
	- order/context (optional) = the order of the scripts + context of what the stage is. Used if a theme has multiple steps. E.g. "s1-analysis". (s = script).
5. **Output folders** follow the naming convention of **"who_broad-theme_order_specific-theme_order/context"** where:
	- "who_broad-theme_order_specific-theme_order/context" exactly matches the script that produces the output.
6. **Functions**, **datasets**, **reference information**, and **sub level data folders** all adhere to rules 1 and 2, plus:
	- Only the essentials are used for the name, and **no dashes are used** (see [R Objects](https://stat.ethz.ch/R-manual/R-devel/library/base/html/Quotes.html)).

> For unfinished scripts use the suffix "(WIP)", (WIP = Work in Progress).

> [!Note]
> A powerpoint is provided in the repo under **"spatial-analysis/reference/naming_style_guide.pptx"** with examples of naming conventions.

> [!Note]
> External corroboration of the importance of naming has been written by [Jenny Bryan.](https://docplayer.net/55248970-Naming-things-prepared-by-jenny-bryan-for-reproducible-science-workshop.html)

> [!Note]
> These rules are not manditory for naming objects within an R script (i.e. sometimes object names are capitilised) but it is a good idea to also follow these rules within the code to maintain consistency.

# 4. Scripts

By now you should have this repo on your computer, you should have your R environment setup (and special packages installed), you should have a good understanding of the layout, and 
you should understand the naming rules and conventions that are required. If so, there is only three more things to know before running/creating scripts:

## 4.1 Data

Each script requires its own set of data to work, we will cover this in [5. Data](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#5-data).

## 4.2 YAML

All scripts contain a yaml header which should look something like this:

![YAML Example](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/yaml_example.png?raw=true)

In the YAML there are several key components that can change the outcome of the script:

- title: Whatever you want, this becomes the title of the render that the script produces.
- author: The author of the script, this is also added to the top of the render.
- date: `r format(Sys.time(), '%d, %B, %Y')` will print the run date, appears at the top of the render.
- format: **html** or **docx**. This changes the file type the script renders.
- params: Can create whatever [params](https://quarto.org/docs/computations/parameters#knitr) you want, useful for global/important variables. Commonly used params:
	- target_fyear: The **financial** year you are targetting, i.e. target_fyear = 2022 means 2021-2022.
	- disagg_factor: The level of disaggregation to apply to raster data (increases resolution).
	- project_crs: The Coordinate Reference System (CRS) used.

> [!Note]
> The key point of the yaml is that broad sweeping changes can be made directly from here. Want to change the financial year that you target? No need to laborously edit
> the whole script. Just change the "target_fyear" param.

## 4.3 Script Order

Script order is very important, several scripts cannot be run without first running another script. A mindmap of all scripts and their relation to one another is stored in the 
[2.5 references](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#25-references) folder, and a screenshot is provided below. Find the script you want to run
and then traced back to the very top. This will identify any scripts that need to be completed first.

![script mindmap](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/script_mindmap_example.png?raw=true)

# 5. Data

Almost every script in this repo contains code that reads in data from the data folder when run (the exception is for scripts that either a) download all data fron online, or, b) don't require any external data at all). When creating 
new scripts this same code should be used to maintain consistency and connection between script and output: 

```R
#create a path to the data folder location. Noting that the folder name should match the script file name
data_path <- here("data/n3_habitat_broad-vegetation-groups/")

#create the folder. Noting that in most cases the folder should already exists and a warning will confirm this.
dir.create(data_path)
```
> [!Note]
> In most cases the folder name after "data/" matches the script name, however there are a few exceptions. For more information see the powerpoint at "spatial-analysis/reference/naming_style_guide.pptx"
> For more on naming conventions go to [Naming Conventions](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#naming-conventions) which sits under
> [3. Contributing](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#3-contributing).

## Dataset Directory

The first time a script is run on a new machine the relevant data must be downloaded. This is because most datasets are too large to be stored on the repo.[^3] Download and storage instructions for each folder are detailed below:

> [!Note]
> Some data may not have download instructions, this data is custom and is marked as such. It should not be edited unless a copy is made.

[^3]: Please note, that although some files are technically small enough to be stored on the repo, we have decided to require all files to be downloaded from source - regardless of their size. This ensures a consistent methodology 
when running a new script for the first time, and also improves understanding of all components of the script and how to access data for future contributions. The exception to this rule is for datasets that cannot be directly downloaded. 
Some datasets used in this repo are custom works that have no online equivalent. Thankfully all of these custom datasets are small enough to be stored on the repo and can be immediately found in the relevant data storage folder. More 
problematically is that some datasets are not available for free, and even worse, are also too large to be stored on the repo. To access these datasets you must contact the  current custodian of this repo: 
[Adam Shand](https://github.com/add-am) (to@drytropicshealthywaters.org). 

|Data Folder|Data Folder|
|:---|:---|
|[archives](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#archives)| |
|[dt_experiments_climate_cyclones](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_experiments_climate_cyclones)|[dt_experiments_habitat_cots](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_experiments_habitat_cots)|
|[dt_experiments_habitat_hlw-method](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_experiments_habitat_hlw-method)|[dt_experiments_habitat_wt-method](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_experiments_habitat_wt-method)|
|[dt_experiments_tables](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_experiments_tables)|[dt_experiments_water-quality_burdekin](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_experiments_water-quality_burdekin)|
|[dt_experiments_water-quality_chla](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_experiments_water-quality_chla)|[dt_experiments_water-quality_ph](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_experiments_water-quality_ph)|
|[dt_fish](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_fish)|[dt_habitat_coral_inshore](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_habitat_coral_inshore)|
|[dt_habitat_coral_offshore](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_habitat_coral_offshore)|[dt_habitat_fish-barriers](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_habitat_fish-barriers)|
|[dt_habitat_impoundment-length](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_habitat_impoundment-length)|[dt_habitat_seagrass](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_habitat_seagrass)|
|[dt_human-dimensions](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_human-dimensions)|[dt_maps](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_maps)|
|[dt_maps_bohle-population](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_maps_bohle-population)|[dt_maps_burdekin-ea](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_maps_burdekin-ea)|
|[dt_maps_burdekin-lga-postcode-suburb](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_maps_burdekin-lga-postcode-suburb)|[dt_maps_rrc-boundaries](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_maps_rrc-boundaries)|
|[dt_maps_school-sub-basin](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_maps_school-sub-basin)|[dt_maps_to-boundaries](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_maps_to-boundaries)|
|[dt_water-quality_estuarine](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_water-quality_estuarine)|[dt_water-quality_freshwater](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_water-quality_freshwater)|
|[dt_water-quality_inshore](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_water-quality_inshore)|[n3_climate_air-temperature](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_climate_air-temperature)|
|[n3_climate_dhw](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_climate_dhw)|[n3_climate_land-use](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_climate_land-use)|
|[n3_climate_rainfall](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_climate_rainfall)|[n3_climate_sea-surface-temperature](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_climate_sea-surface-temperature)|
|[n3_dem](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_dem)|[n3_ereefs](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_ereefs)|
|[n3_habitat](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_habitat)|[n3_habitat_broad-vegetation-groups](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_habitat_broad-vegetation-groups)|
|[n3_habitat_freshwater-wetlands](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_habitat_freshwater-wetlands)|[n3_habitat_mangroves-and-saltmarshes](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_habitat_mangroves-and-saltmarshes)|
|[n3_habitat_riparian-vegetation](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_habitat_riparian-vegetation)|[n3_litter](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_litter)|
|[n3_prep_region-builder](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_prep_region-builder)|[n3_prep_watercourse-builder](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_prep_watercourse-builder)|

## archives

A fairly self explanatory data folder, this is an archive of old datasets that we don't want to delete or lose track of. Please note that this data is not currently being used but has been kept in the archive as it can offer
critical insight into historical works completed by the n3 partnerships. Currently in the archive data folder there should be:

- original_des_geometry/
	+ des_re_boundaries.gdb
	+ des_black_riparian_area_50m.gpkg
	+ des_ross_riparian_area_50m.gpkg
- mwi_marine.gpkg
- nqdt_fish_barriers.kml
- wt_full_marine.gpkg
- wt_inshore_marine.gpkg

And the data folders should look like this:

![archives 1](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/archives_example_1.png?raw=true)

![archives 2](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/archives_example_2.png?raw=true)

## dt_experiments_climate_cyclones

> [!Note]
> The nature of experiment folders are that they are changing all the time, the below information may not be 100% up-to-date.

Currently the data that should be found in this folder is a follows:

- [qld_cyclones.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#qld_cyclonescsv)

And the data folder should look like this:

![dt experiments climate cyclones](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_experiments_climate_cyclones_example.png?raw=true)

### qld_cyclones.csv

Queensland cyclone tracks data is downloaded from the [Bureau of Meterology's Tropical Cyclone Knowledge Centre](http://www.bom.gov.au/cyclone/tropical-cyclone-knowledge-centre/databases/).

- Simply click the link named "Database of past tropical cyclone tracks" on the database page.
- The download will start automatically
- rename the csv to "qld_cyclones" 
- save as dt_experiments/cyclones_data/qld_cyclones.csv

## dt_experiments_habitat_cots

> [!Note]
> The nature of experiment folders are that they are changing all the time, the below information may not be 100% up-to-date.

Currently the data that should be found in this folder is a follows:

- [cots_manta_tows.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#cots_manta_towscsv)

And the data folder should look like this:

![dt experiments habitat cots](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_experiments_habitat_cots_example.png?raw=true)

### cots_manta_tows.csv

COTS (Crowns-of-Thorns Starfish) data is downloaded from the AIMS data repository, to access data:

- go to [AIMS Long-Term Monitoring Program: Crown-Of-Thorns Starfish And Benthos Manta Tow Data (Great Barrier Reef)](https://apps.aims.gov.au/metadata/view/5bb9a340-4ade-11dc-8f56-00008a07204e)
- scroll down to the data downloads section
- click on "Data Summarised to reef - Zip folder containing CSV and text file"
- fill out the pop up box and submit to download
- unzip the folder and extract the csv
- save the csv as dt_experiments/cots_data/cots_manta_tows.csv

## dt_experiments_habitat_hlw-method

> [!Note]
> The nature of experiment folders are that they are changing all the time, the below information may not be 100% up-to-date.

> [!Note]
> HLW = Healthy Land and Water, this is the South East QLD partnership

This data folder contains the data used by HLW and to conduct their vegetation analsis, with the notable exception of the Bio Condition dataset. This is because the Bio Condition dataset does not extent all the way to the northern
extent of the N3 regions, so there is no reason to store the data.

The data that should be found in the hlw data folder is as follows:

- [slats_extent_2021.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#slats_extent_2021gpkg)
- [slats_change_2020_2021.gdb](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#slats_change_2020_2021gdb)

And the data folder should look like this: 

![dt experiments habitat hlw method](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_experiments_habitat_hlw_method_example.png?raw=true)

### slats_extent_2021.gpkg

Data was downloaded from QSpatial, to obtain the data:

- head to [QSpatial](https://qldspatial.information.qld.gov.au/catalogue/custom/index.page)
- Search for:
	- "Statewide Landcover And Trees Study (SLATS) Sentinel-2 - 2021 woody vegetation extent - Queensland - by area of interest"
- Add the dataset your list (just above the download button)
- Navigate to "My List" in the tool bar across the top
- Click "View/extract in map"
- Select the dataset using the check box on the right
- Extract/download data using the following options:
	- Select Area of interest = Choose an area
	- Selection Method = Custom, Rectangle
		- Click and drag a box that comfortably encompasses all of the N3 regions
	- Output format = GeoPackage 1.0 - GEOPACKAGE_1.0 - .gpkg
	- Output projection = GDA2020 geographic 2D (EPSG:7844)
- Once downloaded, save the .gpkg file as:
	- data/dt_experiemnts/hlw_data/slats_extent_2021.gpkg"

### slats_change_2020_2021.gdb

Data was downloaded from QSpatial, to obtain the data:

- head to [QSpatial](https://qldspatial.information.qld.gov.au/catalogue/custom/index.page)
- Search for:
	- "Statewide Landcover And Trees Study (SLATS) Sentinel-2 - 2020 to 2021 woody vegetation change - Queensland".
- Download in the only format available (zipped shapefile)
- Unzip the folder and store the entire folder as:
	- "data/dt_experiments/hlw_data/slats_change_2020_2021/
	- dont change the name of the files inside the folder

## dt_experiments_habitat_wt-method

> [!Note]
> The nature of experiment folders are that they are changing all the time, the below information may not be 100% up-to-date.

Currently the data that should be found in this folder is a follows:

- individual_basins/ (custom)
	+ [Barron_riparianArea_50m.bdf](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#Barron_riparianArea_50m.shp)
	+ [Barron_riparianArea_50m.prj](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#Barron_riparianArea_50m.shp)
	+ [Barron_riparianArea_50m.shp](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#Barron_riparianArea_50m.shp)
	+ [Barron_riparianArea_50m.shx](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#Barron_riparianArea_50m.shp)
	+ etc.
- [high_value_regrowth.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#high_value_regrowthgpkg)

And the data folders should look like this:

![dt experiments habitat wt method 1](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_experiments_habitat_wt_method_example_1.png?raw=true)

![dt experiments habitat wt method 2](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_experiments_habitat_wt_method_example_2.png?raw=true)

## Barron_riparianArea_50m.shp

This data is stored on the repo due to its lack of online equivalent. The original data was provided by Richard Hunt, whom received the data from the DESI team (Al Healy, Dan Tindall).

### high_value_regrowth.gpkg

- head to [QSpatial](https://qldspatial.information.qld.gov.au/catalogue/custom/index.page)
- Search for:
	- "High Value Regrowth 2021 - Queensland".
- Download in the only format available (zipped shapefile)
- Unzip the folder and store the entire folder as:
	- "data/dt_experiments/hlw_data/slats_change_2020_2021/
	- dont change the name of the files inside the folder

## dt_experiments_tables

> [!Note]
> The nature of experiment folders are that they are changing all the time, the below information may not be 100% up-to-date.

Currently the data that should be found in this folder is a follows:

- [example_table_1.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#example_table_1csv-example_table_2csv-and-example_table_3csv)
- [example_table_2.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#example_table_1csv-example_table_2csv-and-example_table_3csv)
- [example_table_3.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#example_table_1csv-example_table_2csv-and-example_table_3csv)

And the data folder should look like this:

![dt experiments tables](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_experiments_tables_example.png?raw=true)

### example_table_1.csv, example_table_2.csv, and example_table_3.csv

This data is stored on the repo due to its small size and lack of online equivalent. Nothing needs to be done regarding naming or storage for this dataset. Currently it is only required by a Dry Tropics specific script, and is not 
a dependency for any other scripts in the repo. The data was created by Adam Shand to experiment with a variety of data (table) printing options.

## dt_experiments_water-quality_burdekin

> [!Note]
> The nature of experiment folders are that they are changing all the time, the below information may not be 100% up-to-date.

Currently the data that should be found in this folder is a follows:

- [clmp_barratta.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#clmp_barrattacsv-and-clmp_sellheimcsv)
- [clmp_sellheim.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#clmp_barrattacsv-and-clmp_sellheimcsv)
- [flow_barratta.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#flow_barrattacsv-and-flow_sellheimcsv)
- [flow_sellheim_new.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#flow_barrattacsv-and-flow_sellheimcsv)
- [flow_sellheim_old.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#flow_barrattacsv-and-flow_sellheimcsv)
- [high_and_low_flow_objectives.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#high_and_low_flow_objectivescsv) (Custom)

And the data folder should look like this: 

![dt experiments water quality burdekin](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_experiments_water_quality_burdekin_example.png?raw=true)

### clmp_barratta.csv and clmp_sellheim.csv

Water quality data is downloaded from the Catchment Loads Monitoring Program's new portal "Tahbil". To obtain the data:

- head to [Tahbil](https://apps.des.qld.gov.au/water-data-portal/)
- "Explore data" (top left)
- Select the sites:
	- Haughton --> "Barratta Creek at Northcote"
	- Burdekin --> "Burdekin River at Sellheim"
- On the right, select "Concentration", and Download
- **Note: download one at a time to ensure they are in separate sheets**
- Save each file as:
	- "data/dt_experiments/burdekin_wq_data/clmp_barratta.csv"
	- "data/dt_experiments/burdekin_wq_data/clmp_sellheim.csv"
		
### flow_barratta.csv and flow_sellheim.csv

Flow data is downloaded from the Queensland Water Monitoring Information Portal. To obtain the data:

- head to the [Water Monitoring Portal](https://water-monitoring.information.qld.gov.au/)
- under Streamflow Data on the left, expand the "Open stations" menu
- On the left, navigate to:
	- Haughton Basin --> "119101A Barratta Creek at Northcote"
	- Burdekin Basin --> "120002D Burdekin River at Sellheim"
- Select "Custom Outputs" at the centre of the page
- Select the "Stream Discharge (Cumecs)" dataset only
- Then:
	- Period = "All data"
	- Output = "Download"
	- Data Interval = "All points"
- And download the data
- Once downloaded, unzip and save the files as:
	- "data/dt_experiments/burdekin_wq_data/flow_barratta.csv"
	- "data/dt_experiments/burdekin_wq_data/flow_sellheim_new.csv"

Interestingly, the Sellheim site was only just recently install (in 2024), to replace the old Sellheim site (with 500m proximity), so we will also need to get the old Sellheim data as
well. Although annoying it presents a good learning opportunity:

- at the same [Water Monitoring Portal](https://water-monitoring.information.qld.gov.au/)
- under Historic Streamflow Data on the left, expand the "Closed stations" menu
- On the left, navigate to:
	- Burdekin Basin --> "120002C Burdekin River at Sellheim"
	_"note this site has "C" not "D"
- Select "Custom Outputs" at the centre of the page
- Select the "Stream Discharge (Cumecs)" dataset only
- Then:
	- Period = "All data"
	- Output = "Download"
	- Data Interval = "All points"
- And download the data
- Once downloaded, unzip and save the file as:
	- "data/dt_experiments/burdekin_wq_data/flow_sellheim_old.csv"

### high_and_low_flow_objectives.csv

This data is stored on the repo due to its small size and lack of online equivalent. Nothing needs to be done regarding naming or storage for this dataset. The original water quality
objective values were manually transcribed from the Environmental Protection (Water and Wetland Biodiversity) Policy 2019 documents. To find the specific values:

- head to the [EPP Portal](https://environment.desi.qld.gov.au/management/water/policy)
- Navigate to "Burdekin, Haughton and Don basins"
- For barratta objectives:
	- open "Haughton River Basin" (Schedule 1 - Document column)
	- find "Barratta Creek upper catchment fresh waters", "HD"
- For sellheim objectives:
	- open Burdekin River (upper) Sub-Basins" (Schedule 1 - Document column)
	- find "Burdekin River (above Dam) sub-catchment waters", "MD"

## dt_experiments_water-quality_chla

> [!Note]
> The nature of experiment folders are that they are changing all the time, the below information may not be 100% up-to-date.

Currently the data that should be found in this folder is a follows:

- [A.P1D.20230101T053000Z.aust.chl_oc3.nc](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#AP1D20230101T053000Zaustchl_oc3nc)
- [etc.](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#AP1D20230101T053000Zaustchl_oc3nc)

And the data folder should look like this: 

![dt experiments water quality chla](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_experiments_water_quality_chla_example.png?raw=true)

### A.P1D.20230101T053000Z.aust.chl_oc3.nc

The chla satellite data stored in this folder was retrived from the AODN portal and measured by the MODIS satellite. To obtain the data:

- head to the [AODN portal](https://portal.aodn.org.au/search)
- filter for the Chlorophyll paramter (under "Biological")
- filter for the Satellite platform
- select the data product titled "IMOS - SRS - MODIS - 01 day - Chlorophyll-a concentration (OC3 model)
- create a temporal subset from 2023-01-01 until 2023-03-31 (exactly 3 months of data to practice with)
- click and drag on the map to create a bounding box around the Queensland coastline
- click next, then click download as "Un-subsetted NetCDFs" (downloads quicker this way)
- extract the files from the zipped folder, do not change the names of any of the files, 
	- store the files inside the dt_experiments/chla_data/ folder

## dt_experiments_water-quality_ph

> [!Note]
> The nature of experiment folders are that they are changing all the time, the below information may not be 100% up-to-date.

Currently the data that should be found in this folder is a follows:

- [Surface_pH_1770_2000.nc](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#Surface_pH_1770_2000nc-Surface_ph_2010_2100_RCP26nc-Surface_ph_2010_2100_RCP45nc-Surface_ph_2010_2100_RCP60nc-and-Surface_ph_2010_2100_RCP85nc)
- [Surface_ph_2010_2100_RCP26.nc](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#Surface_pH_1770_2000nc-Surface_ph_2010_2100_RCP26nc-Surface_ph_2010_2100_RCP45nc-Surface_ph_2010_2100_RCP60nc-and-Surface_ph_2010_2100_RCP85nc)
- [Surface_ph_2010_2100_RCP45.nc](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#Surface_pH_1770_2000nc-Surface_ph_2010_2100_RCP26nc-Surface_ph_2010_2100_RCP45nc-Surface_ph_2010_2100_RCP60nc-and-Surface_ph_2010_2100_RCP85nc)
- [Surface_ph_2010_2100_RCP60.nc](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#Surface_pH_1770_2000nc-Surface_ph_2010_2100_RCP26nc-Surface_ph_2010_2100_RCP45nc-Surface_ph_2010_2100_RCP60nc-and-Surface_ph_2010_2100_RCP85nc)
- [Surface_ph_2010_2100_RCP85.nc](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#Surface_pH_1770_2000nc-Surface_ph_2010_2100_RCP26nc-Surface_ph_2010_2100_RCP45nc-Surface_ph_2010_2100_RCP60nc-and-Surface_ph_2010_2100_RCP85nc)

And the data folder should look like this: 

![dt experiments water quality ph](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_experiments_water_quality_ph_example.png?raw=true)

### Surface_pH_1770_2000.nc, Surface_ph_2010_2100_RCP26.nc, Surface_ph_2010_2100_RCP45.nc, Surface_ph_2010_2100_RCP60.nc, and Surface_ph_2010_2100_RCP85.nc 

The ph data is this folder is a combination of historic (1770-2000) global ocean ph levels, and future (2010-2100) levels based on four different RCP (Representative Concentration Pathways) models. To obtain the data:

- head to the [NCEI ocean archive system](https://www.ncei.noaa.gov/archive/archive-management-system/OAS/bin/prd/jquery/accession/download/206289)
	+ (or search "DOI: 10.25921/kgqr-9h49" - and click the second link).
	+ (or search for the scientific paper "Surface ocean pH and buffer capacity: past, present and future" and read the data availablility paragraph).
- once at the ocean archive system click the "download individual files" link
- navigate through the file system to: 1.2/data/0-data/Surface_pH_1770_2100/
- click on each of the files in this folder to download, there should be:
	+ Surface_pH_1770_2000.nc
	+ Surface_pH_2010_2100_RCP26.nc
	+ Surface_pH_2010_2100_RCP45.nc
	+ Surface_pH_2010_2100_RCP60.nc
	+ Surface_pH_2010_2100_RCP85.nc
- save each of these files in the dt_experiments/ph_data/ folder

## dt_fish

> [!Warning]
> All data in this folder is custom, with no online equivalent. Do not delete or make changes to these datasets.

The data that should be found in this folder is as follows:

- [fish_monitoring_sites.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#fish_monitoring_sitesgpkg) (custom)

And the data folder should look like this: 

![DT Fish Example](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_fish_example.png?raw=true)

### fish_monitoring_sites.gpkg

This data is stored on the repo due to its small size and lack of online equivalent. Nothing needs to be done regarding naming or storage for this dataset. Currently it is only required by a Dry Tropics specific script, and is not 
a dependency for any other scripts in the repo. The data was provided by David Moffatt (david.moffatt@des.qld.gov.au) sometime around 2019. This indicator is yet to be updated and should mostly be completed by David, the monitoring 
sites were only provided so that a map fitting the desired style could be created. The next update is expected around 2023/2024 with potential spatial updates as well.

## dt_habitat_coral_inshore

> [!Warning]
> All data in this folder is custom, with no online equivalent. Do not delete or make changes to these datasets.

The data that should be found in this folder is as follows:

- [custom_reefs.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#custom_reefsgpkg) (custom)
- [dt_inshore_coral_master.xlsx](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_inshore_coral_masterxlsx)

And the data folders should look like this:

![DT Coral Inshore Example 1](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_habitat_coral_inshore_example.png?raw=true)

### custom_reefs.gpkg

This dataset was created because when writing the inshore marine script, it was discovered that the main dataset used to visualise coral reefs was missing a couple of key reefs (Alma Bay Reef, Havannah North Reef, Palms West Reef (1), 
and Pandora South Reef). Adam Shand manually created an outline of the reefs to use as a visual aid when creating maps of the region. NOTE - this is not a verified and agreed upon outline, and should not be used for any analysis 
require acurate spatial representation (e.g. total area).

### dt_inshore_coral_master.xlsx

This spreadsheet is a combination of all the years of Reef Check Australia and AIMS MMP coral results. Each reporting year the new data is added to this spreadsheet. Note that the original data that is provided by each parnter is stored
seperately to this GitHub repo (over in the main DTPHW file system), this is just the collation of the bare essentials needed to run the script.

## dt_habitat_coral_offshore

Currently no data downloads are required for this script to run. The folder is created to maintain consistency between the data folder and the scripts folder. A note is stored in the folder marking this.

For clarity, this is how the folder should look:

![offshore coral example](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_habitat_coral_offshore_example.png?raw=true)

## dt_habitat_fish-barriers

The data that should be found in the fish barriers data folder is as follows:

- [dams_weirs_and_barrages.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dams_weirs_and_barragesgpkg-major_dam_wallsgpkg-minor_dam_wallsgpkg-queensland_roads_and_tracksgpkg-and-rail_networkgpkg)
- [dt_fish_barriers.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_fish_barriersgpkg-and-dt_fish_barriers_master) (custom)
- [dt_fish_barriers_master](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_fish_barriersgpkg-and-dt_fish_barriers_master) (custom)
- [major_dam_walls.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dams_weirs_and_barragesgpkg-major_dam_wallsgpkg-minor_dam_wallsgpkg-queensland_roads_and_tracksgpkg-and-rail_networkgpkg)
- [minor_dam_walls.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dams_weirs_and_barragesgpkg-major_dam_wallsgpkg-minor_dam_wallsgpkg-queensland_roads_and_tracksgpkg-and-rail_networkgpkg)
- [queensland_roads_and_tracks.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dams_weirs_and_barragesgpkg-major_dam_wallsgpkg-minor_dam_wallsgpkg-queensland_roads_and_tracksgpkg-and-rail_networkgpkg)
- [rail_network.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dams_weirs_and_barragesgpkg-major_dam_wallsgpkg-minor_dam_wallsgpkg-queensland_roads_and_tracksgpkg-and-rail_networkgpkg)

And the data folder should look like this: 

![DT Fish Barriers Example](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_habitat_fish_barriers_example.png?raw=true)

### dams_weirs_and_barrages.gpkg, major_dam_walls.gpkg, minor_dam_walls.gpkg, queensland_roads_and_tracks.gpkg, and rail_network.gpkg

These five datasets are downloaded from [QSpatial](https://qldspatial.information.qld.gov.au/catalogue/custom/index.page): 
- Search for:
	- "Bulk Water Opportunities Statement Dams weirs and barrages - 2021 - Queensland".
	- "Major dam walls - Queensland".
	- "Minor dam walls - Queensland".
	- "Queensland road and tracks"
	- "Rail network - Queensland"
- Download each as a GeoPackage 1.0 - GEOPACKAGE_1.0 - .gpkg, with GDA2020 geographic 2D (EPSG:7844).
- Extract only the .gpkg data files (metadata does not need to be stored) and,
- Store the .gpkg files as:
	- "data/dt_experiments/fish_barriers_data/dams_weirs_and_barrages.gpkg".
	- "data/dt_experiments/fish_barriers_data/major_dam_walls.gpkg".
	- "data/dt_experiments/fish_barriers_data/minor_dam_walls.gpkg".
	- "data/dt_experiments/fish_barriers_data/queensland_roads_and_tracks.gpkg".
	- "data/dt_experiments/fish_barriers_data/rail_network.gpkg".

### dt_fish_barriers.gpkg and dt_fish_barriers_master

> [!Warning]
> This data is custom, with no online equivalent. Do not delete or make changes to these datasets.

This data is stored on the repo due to its small size and lack of online equivalent. Nothing needs to be done regarding naming or storage for these datasets. Work is currently underway to conduct a second fish barriers desktop survey,
these files are where information from the second survey will be recorded.

## dt_habitat_impoundment-length

> [!Warning]
> All data in this folder is custom, with no online equivalent. Do not delete or make changes to these datasets.

The data that should be found in this folder is as follows:

- [impounded_and_not_impounded_waters.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#impounded_and_not_impounded_watersgpkg) (custom)

And the data folder should look like this: 

![DT Impoundment Length Example](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_habitat_impoundment_example.png?raw=true)

### impounded_and_not_impounded_waters.gpkg

This data is stored on the repo due to its small size and lack of online equivalent. Nothing needs to be done regarding naming or storage for this dataset. Currently it is only required by a Dry Tropics specific script, and is not 
a dependency for any other scripts in the repo. The data was provided by David Moffatt (david.moffatt@des.qld.gov.au) sometime around 2019. This indicator is yet to be updated and should mostly be completed by David, the dataset was 
only provided so that a map fitting the desired style could be created. The next update is expected around 2023/2024 with potential spatial updates as well. Note that conversations are underway between Adam Shand and David Moffatt 
to develop an internal method for this indicator - as the process is entirely desktop based it would fit well into the theme of this repo.

## dt_habitat_seagrass

> [!Warning]
> All data in this folder is custom, with no online equivalent. Do not delete or make changes to these datasets.

The data that should be found in this folder is as follows:

- [dt_seagrass_2021.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_seagrassgpkg) (custom)
- [dt_seagrass_2022.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_seagrassgpkg) (custom)

And the data folder should look like this: 

![DT Seagrass Example](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_habitat_seagrass_example.png?raw=true)

### dt_seagrass.gpkg

Data is stored on the repo due to its small size and lack of online equivalent. Nothing needs to be done regarding naming or storage for this dataset. Currently it is only required by a Dry Tropics specific script, and is not 
a dependency for any other scripts in the repo. The data was provided by TropWater so that Adam Shand could recreated a site map in the desired style. Contact Mike Rasheed (michael.rasheed@jcu.edu.au) or Skye McKenna 
(skye.mckenna@jcu.edu.au) for updated versions of this dataset if required.

## dt_human-dimensions

This folder contains all data from the SELTMP surveys. The data that should be found in this folder is as follows:

- [seltmp_2021.xlsx](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#seltmp_2021xlsx-and-seltmp_2024xlsx)
- [seltmp_2024.xlsx](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#seltmp_2021xlsx-and-seltmp_2024xlsx)

And the data folder should look like this:

![SELTMP folder example](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_human-dimensions_example.png?raw=true)

### seltmp_2021.xlsx and seltmp_2024.xlsx

Data can be stored on this repo due to its small size, however can equally be accessed online. Data is accessed via the [CSIRO SELTMP Methods Portal](https://research.csiro.au/seltmp/methods/):

- On the CSIRO SELTMP Methods Portal scroll down to the "Data" section
- Under 2024, click the link for the first dataset: "Great Barrier Reef Catchment Regional Waterway Partnerships Social Monitoring Survey (2nd iteration). v1"
	- Navigate to the "Files" tab
	- Use the Download button to download all files
	- Use the "Download all files as Zip archive" method
	- Extract the main dataset (that with the most recent date) currently "GBR-RegionalReportCards_2024-SocialSurveyDataset-DAP_v1_May2024"
	- Store the file as "data/dt_human-dimensions/seltmp_2024.xlsx
- Under 2022, click the link for the second dataset: "Great Barrier Reef Catchment Regional Waterway Partnerships Baseline Social Surveys. v3."
	- Navigate to the "Files" tab
	- Use the Download button to download all files
	- Use the "Download all files as Zip archive" method
	- Extract the main dataset (that with the most recent date) currently "FullDataset_RRC-social-survey-data-CSIRO-DAP-Version3_EC_Nov2023"
	- Store the file as "data/dt_human-dimensions/seltmp_2021.xlsx

## dt_maps

This folder is an exception to the data organisation and naming rules covered in Naming Conventions. While all other data folders share the same name as the associated script, the dt_maps folder does not 
(there is no "dt_maps" script). Instead this is a generic folder that contains data used by most "dt_maps_xxx" scripts. Each script accesses the same data, selects the pieces it needs, and save those to its own folder. Each script
may also have its own data in its own folder. This folder contains all data that pertains to making maps, specifically, maps that aren't directly attached to another script. For example, the water quality sampling site maps are of 
course map by the water quality sampling scripts. The data that should be found in this folder is as follows:

- [clmp_burdekin_sites.xlsx](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#clmp_burdekin_sitesxlsx)
- [lga.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#lgagpkgandnrm.gpkg)
- [nrm.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#lgagpkgandnrm.gpkg)

And the data folders should look like this:

![dt maps example 1](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_maps_example_1.png?raw=true)

### clmp_burdekin_sites.xlsx

This file is used by the dt_maps_burdekin_wq-sites script. The file is currently a perfect copy of the original CLMP dataset as provided by our CLMP partners. Water quality CLMP data is downloaded from the Catchment Loads Monitoring 
Program's new portal "Tahbil". To obtain the data:

- head to [Tahbil](https://apps.des.qld.gov.au/water-data-portal/)
- "Explore data" (top left)
- Select all sites of interest
- On the right, select "Concentration", and Download
- Save the file as: "data/dt_maps/clmp_burdekin_sites.csv"

### lga.gpkg and nrm.gpkg

These files are used by several mapping scripts.

All data is downloaded from [QSpatial](https://qldspatial.information.qld.gov.au/catalogue/custom/index.page): 

- Search for:
	- "Natural resource management regional boundaries - Queensland".
	- "Local government area boundaries - Queensland".
- Download as a GeoPackage 1.0 - GEOPACKAGE_1.0 - .gpkg, with GDA2020 geographic 2D (EPSG:7844).
- Extract only the .gpkg data files (metadata does not need to be stored) and,
- Store the .gpkg files as:
	- "data/dt_maps/lga.gpkg".
	- "data/dt_maps/nrm.gpkg".

## dt_maps_bohle-population

This folder contains mapping data exclusive to the bohle population script.

The data that should be found in this folder is as follows:

- [estimated_lga_population.xlsx](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#estimated_lga_populationxlsx-and-estimated_sa1_populationxlsx)
- [estimated_sa1_population.xlsx](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#estimated_lga_populationxlsx-and-estimated_sa1_populationxlsx)
- [SA1_2021_AUST_GDA2020.dbf](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#sa1_2021_aust_gda2020)
- [SA1_2021_AUST_GDA2020.prj](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#sa1_2021_aust_gda2020)
- [SA1_2021_AUST_GDA2020.shp](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#sa1_2021_aust_gda2020)
- [SA1_2021_AUST_GDA2020.shx](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#sa1_2021_aust_gda2020)

And the data folders should look like this:

![dt maps bohle population example 1](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_maps_bohle_population_example_1.png?raw=true)

### estimated_lga_population.xlsx and estimated_sa1_population.xlsx

Strangely enough, queensland population data is annoyingly difficult to find. These files can be found on the [Queensland Government Statistician's Office](https://www.qgso.qld.gov.au/statistics/theme/population/population-estimates/regions) website. 
To find the data:
- (if landing on the home page), navigate to Statistics/By theme/Population/Population estimates/Regions
- Expand the "Estimated resident population (ERP) (table)"
	+ Download the "Local government area (LGA), Queensland, 2001 to 2023p" excel file
- Expand the "Estimated resident population by Sa1 (ABS consultancy) (table)"
	+ Download the "Statistical area level 1 (SA1), Australia 2011 to 2023p (ASGS Edition 3, 2021)" excel file
- Save each file as:
	+ data/dt_maps/population/estimated_lga_population.xlsx
	+ data/dt_maps/population/estimated_sa1_population.xlsx

### SA1_2021_AUST_GDA2020

The statistical area level 1 data is downloaded from the [Australian Bureau of Statistics Digital Boundary files site](https://www.abs.gov.au/statistics/standards/australian-statistical-geography-standard-asgs-edition-3/jul2021-jun2026/access-and-downloads/digital-boundary-files):

- Scroll to "Statistical Area level 1 - 2021 - Shapefile"
- Make sure this is under the "Downloadds for BDA2020 digital boundary files" heading
- Download the zip file
- save the each of the files as: "data/dt_maps_bohle-population/SA1_2021_AUST_GDA2020.xxx"

## dt_maps_burdekin-ea

The data that should be found in this folder is as follows:

- [ea_location.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#ea_locationgpkg)

And the data folders should look like this:

![dt maps burdekin ea example 1](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_maps_burdekin_ea_example_1.png?raw=true)

### ea_location.gpkg

Environmental Authority data is downloaded from [QSpatial](https://qldspatial.information.qld.gov.au/catalogue/custom/index.page): 

- Search for:
	- "Environmental Authority Locations - Queensland".
- Download as a GeoPackage 1.0 - GEOPACKAGE_1.0 - .gpkg, with GDA2020 geographic 2D (EPSG:7844).
- Extract only the .gpkg data files (metadata does not need to be stored) and,
- Store the .gpkg file as:
	- "data/dt_maps_burdekin-ea/ea_locations.gpkg".

## dt_maps_burdekin-lga-postcode-suburb

The data that should be found in this folder is as follows:

- postcode/
	+ [postcode_shapefiles](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#postcode_shapefiles)
- [suburb.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#suburbgpkg)

And the data folders should look like this:

![dt maps burdekin lga postcode suburb example 1](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_maps_burdekin_lga_postcode_suburb_example_1.png?raw=true)

![dt maps burdekin lga postcode suburb example 2](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_maps_burdekin_lga_postcode_suburb_example_2.png?raw=true)

### postcode_shapefiles

The postcode dataset is not available from QSpatial. Instead this dataset is downloaded from the [Australian Bureau of Statistics (ABS) digital boundary files webpage](https://www.abs.gov.au/statistics/standards/australian-statistical-geography-standard-asgs-edition-3/jul2021-jun2026/access-and-downloads/digital-boundary-files).

- On the Digital Boundary Files webpage, scroll down to the Non ABS Structures subheading
- Ensure that the files are of the GDA2020 format (in the navbar on the right)
- Download the ZIP file for "Postal Areas -2021 - Shapefile"
- Unzip the folder and store the folder as "data/dt_maps/postcode/"
- Rename each file to "postcode.XXX" where XXX = file type
	+ Please note that the data is only downloadable as a shapefile, we won't worry about converting the file type or renaming the files inside the folder. We will just do this in the script since it is a minor script of low importance.

### suburb.gpkg

The suburb dataset is downloaded from [QSpatial](https://qldspatial.information.qld.gov.au/catalogue/custom/index.page): 

- Search for:
	- "Locality boundaries - Queensland".
- Download as a GeoPackage 1.0 - GEOPACKAGE_1.0 - .gpkg, with GDA2020 geographic 2D (EPSG:7844).
- Extract only the .gpkg data files (metadata does not need to be stored) and,
- Store the .gpkg file as:
	- "data/dt_maps/suburb.gpkg"

## dt_maps_rrc-boundaries

> [!Warning]
> Some data in this folder is custom, with no online equivalent. Do not delete or make changes to these datasets.

The data that should be found in this folder is as follows:

- [frhp_land_boundaries.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#frhp_land_boundariesgpkg-and-frhp_marine_boundariesgpkg) (custom)
- [frhp_marine_boundaries.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#frhp_land_boundariesgpkg-and-frhp_marine_boundariesgpkg) (custom)
- [ghhp_boundaries.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#ghhp_boundariesgpkg) (custom)

And the data folder should look like this:

![dt maps rrc boundaries example 1](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_maps_rrc_boundaries_example_1.png?raw=true)

### frhp_land_boudaries.gpkg, and frhp_marine_boundaries.gpkg

These datasets were provided by the Fitzroy River Health Partership (FRHP). They cannot be downloaded online and can only be accessed via a request to Myfina or Eva (the current project officers at FRHP).

### ghhp_boundaries.gpkg

This dataset was provided by the Gladstone Healthy Harbour Partnership (GHHP). It cannot be downloaded online and is only accessed via a request to Kirsten (the current project officer at GHHP).

## dt_maps_school-sub-basin

> [!Warning]
> Some data in this folder is custom, with no online equivalent. Do not delete or make changes to these datasets.

The data should be found this folder is as follows:

- [potential_schools_list.xlsx](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#potential_schools_listxlsx)

And the data folder should look like this:

![dt maps school sub basin example 1](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_maps_school_sub_basin_example_1.png?raw=true)

### pontential_schools_list.xlsx

This dataset was created Kara-Mae, executive officer of the Healthy Waters Partnership. It cannot be downloaded online and is only accessed via request to Kara or Adam.

## dt_maps_to-boundaries

The data that should be found in this folder is as follows:

- [cultural_heritage_party_boundary.kml](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#cultural_heritage_part_boundarykml)

And the data folder should look like this:

![dt maps rrc boundaries example 1](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_maps_to_boundaries_example_1.png?raw=true)

### cultural_heritage_part_boundary.kml

Traditional Owner boundary data is another onerous dataset to obtain. They can be found on the [ArcGIS REST Services Directory](https://spatial-gis.information.qld.gov.au/arcgis/rest/services/Boundaries/CulturalHeritageBoundaries/MapServer).
Or if the link does not work you can try google "Arc GIS REST services directory traditional owner Boundaries".

- To download the data scroll to the bottom of the page and click "Generate KML".
- Leave the document name blank
- Select the "Cultural Heritage party boundary(1)" layer
- Select "Vector layers as vectors and raster layers as images"
- and generate the .KMZ
- the .KMZ then needs to be opened in Google Earth Pro (R cannot read KMZ files)
- once open, right click the layer and "save place as"
- save the file as a **.KML** file type, with the name:
	+ data/dt_maps/to_boundaries/cultural_heritage_part_boundary.kml









## dt_water-quality_estuarine

> [!Warning]
> All data in this folder is custom, with no online equivalent. Do not delete or make changes to these datasets.

The data that should be found in this folder is as follows:

- processed/
	+ [YYYY-YYYY_estuarine_wq_all.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#YYYY-YYYY_estuarine_wq_allcsv) (custom)
- raw/
	+ [dt_wq_estuarine_data_master.xlsx](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_wq_estuarine_data_masterxlsx) (custom)
	+ [dt_wq_estuarine_metadata.xlsx](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_wq_estuarine_metadataxlsx) (custom)

And the data folders should look like this: 

![DT WQ estuarine Example 1](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_water_quality_estuarine_example_1.png?raw=true)

![DT WQ estuarine Example 2](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_water_quality_estuarine_example_2.png?raw=true)

![DT WQ estuarine Example 3](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_water_quality_estuarine_example_3.png?raw=true)

### processed

This folder will contain the output from the estuarine exploratory data analysis script (i.e. the "processed" data). Which is used by the main estuarine analysis script.

#### YYYY-YYYY_estuarine_wq_all.csv

Files are created for each reporting year (hence the generic YYYY format). The files will be automatically created from the metadata and master data spreadsheets in the raw folder. Please note that the EDA script will also perform a 
range of QA and QC checks. During these checks some data may be removed. The resulting files will be saved with the suffix "sites_removed" to distinguish these datasets.

> [!Note]
> A deliberate decision has been made to block the data in this folder from being uploaded. This forces the user to recreate the data and ensures that the data preparation script successfully runs - and that all tests pass.

To obtain this data the estuarine exploratory data analysis script must be successfully run.

### raw

This folder contains all raw data required by the suite of estuarine scripts.

#### dt_wq_estuarine_data_master.xlsx

The Dry Tropics estuarine master data set is a collation of all water quality data from all providers. Each reporting year the new data is added to this spreadsheet. Note that the original data that is provided by each partner is stored
seperately to this GitHub repo (over in the main DTPHW file system), this is just the collation of the bare essentials needed to run the script.

#### dt_wq_estuarine_metadata.xlsx

The Dry Tropics estuarine metadata spreadsheet is a collation of all metadata relevant to the water quality analysis. This includes Water Quality Objectives, Limit of Reporting, Scaling Factors, Site details, and GPS coordinates. Note
that this data has been created in house by the DTPHW team, there is no backup of this spreadsheet, or secondary location. Do not delete or edit this file without thorough understanding of the script.

## dt_water-quality_freshwater

> [!Warning]
> Some data in this folder is custom, with no online equivalent. Do not delete or make changes to these datasets.

The data that should be found in this folder is as follows:
 
- processed/
	+ [YYYY-YYYY_freshwater_wq_all.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#YYYY-YYYY_freshwater_wq_allcsv) (custom)
- rainfall/
	+ [sub_basin_rainfall.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#sub_basin_rainfallcsv)
- raw/
	+ [conversion_table_dissolved_oxygen.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#conversion_table_dissolved_oxygencsv) (custom)
	+ [dt_wq_freshwater_data_master.xlsx](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_wq_freshwater_data_masterxlsx) (custom)
	+ [dt_wq_freshwater_metadata.xlsx](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_wq_freshwater_metadataxlsx) (custom)
 
And the data folders should look like this: 

![DT WQ freshwater Example 1](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_water_quality_freshwater_example_1.png?raw=true)

![DT WQ freshwater Example 2](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_water_quality_freshwater_example_2.png?raw=true)

![DT WQ freshwater Example 3](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_water_quality_freshwater_example_3.png?raw=true)

![DT WQ freshwater Example 4](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_water_quality_freshwater_example_4.png?raw=true)

### processed

This folder will contain the output from the freshwater exploratory data analysis script (i.e. the "processed" data). Which is used by the main freshwater analysis script.

#### YYYY-YYYY_freshwater_wq_all.csv

Files are created for each reporting year (hence the generic YYYY format). The files will be automatically created from the metadata and master data spreadsheets in the raw folder. Please note that the EDA script will also perform a 
range of QA and QC checks. During these checks some data may be removed. The resulting files will be saved with the suffix "sites_removed" to distinguish these datasets.

> [!Note]
> A deliberate decision has been made to block the data in this folder from being uploaded. This forces the user to recreate the data and ensures that the data preparation script successfully runs - and that all tests pass.

To obtain this data the freshwater data preparation script must be successfully run.

### rainfall

This folder contains a spreadsheet of rainfall amounts across each of the sub basins, this is used in part of the EDA processs. 

#### sub_basin_rainfall.csv

To obtain the sub_basin_rainfall.csv dataset the script will process each of the rain_day_YYYY.nc datasets and create a rain_day_all.nc dataset, then calculate all of the sub basins values from that. The rain_day_YYYY.nc datasets 
are downloaded from the [BOM's Australian Water Outlook (AWO) portal](https://awo.bom.gov.au/)

- Click download (top right) and choose the following format: 
	- File Type = NetCDF
	- Product = Historical
	- Time Aggregation = Day
	- Values = Absolute
	- Variable = Precipitation
	- Time = YYYY (~2012 to current year)
- Store the .nc files as **data/dt_water-quality_freshwater/rainfall/rain_day_YYYY.nc**.

### raw

This folder contains all raw data required by the suite of freshwater scripts.

#### conversion_table_dissolved_oxygen.csv

The conversion table spreadsheet is unique to the freshwater water quality analysis. Some partners provide dissolved oxygen (DO) data as mg/L, whilst the partnership presents DO as % saturation. This spreadsheet contains the relationship
between DO in mg/L and DO in % Saturation that is need to convert between the two unit types.

#### dt_wq_freshwater_data_master.xlsx

The Dry Tropics freshwater master data set is a collation of all water quality data from all providers. Each reporting year the new data is added to this spreadsheet. Note that the original data that is provided by each partner is stored
seperately to this GitHub repo (over in the main DTPHW file system), this is just the collation of the bare essentials needed to run the script.

#### dt_wq_freshwater_metadata.xlsx

The Dry Tropics freshwater metadata spreadsheet is a collation of all metadata relevant to the water quality analysis. This includes Water Quality Objectives, Limit of Reporting, Scaling Factors, Site details, and GPS coordinates. Note
that this data has been created in house by the DTPHW team, there is no backup of this spreadsheet, or secondary location. Do not delete or edit this file without thorough understanding of the script.

## dt_water-quality_inshore

> [!Warning]
> All data in this folder is custom, with no online equivalent. Do not delete or make changes to these datasets.

The data that should be found in this folder is as follows:

- processed/
	+ [YYYY-YYYY_inshore_wq_all.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#YYYY-YYYY_inshore_wq_allcsv) (custom)
- raw/
	+ [dt_wq_inshore_data_master.xlsx](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_wq_inshore_data_masterxlsx) (custom)
	+ [dt_wq_inshore_metadata.xlsx](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_wq_inshore_metadataxlsx) (custom)

And the data folders should look like this: 

![DT WQ inshore Example 1](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_water_quality_inshore_example_1.png?raw=true)

![DT WQ inshore Example 2](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_water_quality_inshore_example_2.png?raw=true)

![DT WQ inshore Example 3](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/dt_water_quality_inshore_example_3.png?raw=true)

### processed

This folder will contain the output from the inshore data preparation script (i.e. the "processed" data). Which is used by the inshore data analysis script.

#### YYYY-YYYY_inshore_wq_all.csv

Files are created for each reporting year (hence the generic YYYY format). The files will be automatically created from the metadata and master data spreadsheets in the raw folder. Please note that the EDA script will also perform a 
range of QA and QC checks. During these checks some data may be removed. The resulting files will be saved with the suffix "sites_removed" to distinguish these datasets.

> [!Note]
> A deliberate decision has been made to block the data in this folder from being uploaded. This forces the user to recreate the data and ensures that the data preparation script successfully runs - and that all tests pass.

To obtain this data the inshore data preparation script must be successfully run.

### raw

This folder contains all raw data required by the suite of inshore scripts.

#### dt_wq_inshore_data_master.xlsx

The Dry Tropics inshore master data set is a collation of all water quality data from all providers. Each reporting year the new data is added to this spreadsheet. Note that the original data that is provided by each partner is stored
seperately to this GitHub repo (over in the main DTPHW file system), this is just the collation of the bare essentials needed to run the script.

#### dt_wq_inshore_metadata.xlsx

The Dry Tropics inshoremetadata spreadsheet is a collation of all metadata relevant to the water quality analysis. This includes Water Quality Objectives, Limit of Reporting, Site details, and GPS coordinates. Note
that this data has been created in house by the DTPHW team, there is no backup of this spreadsheet, or secondary location. Do not delete or edit this file without thorough understanding of the script.

## n3_climate_air-temperature

> [!Note]
> Data in this folder must be paid for, speak with [Adam Shand](https://github.com/add-am) (to@drytropicshealthywaters.org) to obtain.

The data that should be found in this folder is as follows:

- [tmax2](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#tmax2-and-tmin2)
- [tmin2](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#tmax2-and-tmin2)
- [n3_tmean_temperature.nc](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_tmean_temperature.nc)

And the data folder (and sub folders) should look like this: 

![Air temperature example1](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_climate_air_temperature_example_1.png?raw=true)

![Air temperature example2](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_climate_air_temperature_example_2.png?raw=true)

![Air temperature example3](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_climate_air_temperature_example_3.png?raw=true)

### tmax2 and tmin2

The tmax2 and tmin2 datasets are obtained from the same data request to BOM.

- Data spans the year 1910 to 2022, each year a new data request will need to be made to obtain the latest data.
- The initial request for all data was **~$270**, future requests should cost less as only one year is requested.
- The data request can be sent to the generic **climatedata@bom.gov.au** email with the following format:
	- Data: Australian Monthly Temperature Gridded Data. 
	- Time: All months for the current year, and all months for the previous year [^4].
	- Format: NetCDF.
	- Use: Create an annual climate report for the WT, DT, and MWI regions.
- Once data has been received and downloaded;
	- save the tmax2 folder under **"data/n3_climate_air-temperature/tmax2/"**
	- save the tmin2 folder under **"data/n3_climate_air-temperature/tmin2/"**
- The contents of each folder should not need to be renamed.

[^4]: This is just to make sure no data is missed, you could be more specific by checking exactly what month the previous data request got up to. Pay close attention to any potential overlaps when adding new data to the existing dataset.

Additional information regarding BOM's datasets can be found [here](http://www.bom.gov.au/climate/averages/climatology/gridded-data-info/gridded_datasets_summary.shtml), and 
[here](http://www.bom.gov.au/climate/averages/climatology/gridded-data-info/gridded-climate-data.shtml). 

### n3_tmean_temperature.nc

This data is automatically created and saved by the script, it is referenced in future renders to save processing time.

## n3_climate_dhw

> [!Note]
> This script cannot be run for the current financial year until the 5th month of the year, refer to [issue 10](https://github.com/Northern-3/spatial-analyses/issues/10).

The data that should be found in this folder is as follows:

- [dhw_world](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dhw_world)
- [n3_dhw.nc](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_dhwnc)

And the data folder (and sub folders) should look like this: 

![DHW World folder example](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_climate_dhw_example_1.png?raw=true)

![DHW file example](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_climate_dhw_example_2.png?raw=true)

### dhw_world

Degree heating week (dhw) data is provided free of charge by [NOAA](https://www.star.nesdis.noaa.gov/pub/sod/mecb/crw/data/5km/v3.1_op/nc/v1.0/annual/).
- Data is automatically downloaded within the dhw script - there is no need to download any data manually.
- If the automated data dowload works, the data will be stored inside the "dhw_world" folder.
- Data is then cropped to the n3 region and saved as [n3_dhw.nc](https://github.com/Northern-3/spatial-analyses#n3_dhwnc).
- However, if the automatic data request script fails, data can be manually retrieved from the first link above;
	- Use Ctrl+F and search for "ct5km_dhw-max_v3.1_**2022**", changing the year to the year you want.
	- Download the .nc file, not the .nc.md5 file.
	- Save each .nc file as ".../dhw_world/dhw_**2022**.nc", where the year is updated for each dataset.

Degree heating week data is used in the climate section of the technical report as a proxy for coral bleaching risk, for additional information on how the dhw product is calculated, what it is a measure of, and how to interpret
it, go to [NOAAs coralreefwatch website](https://coralreefwatch.noaa.gov/), and review [NOAAs methods](https://coralreefwatch.noaa.gov/product/5km/methodology.php).

### n3_dhw.nc

This data is automatically created and saved by the script, it is referenced in future renders to save processing time.

## n3_climate_land-use

> [!Note]
> Some data is provided in .gdb format and must be converted to .gpkg format, refer to [Convert Land Use Data](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#convert-land-use-data).

For extra information about what exactly the land use data means and what you can do with it, go [here](https://www.qld.gov.au/environment/land/management/mapping/statewide-monitoring/qlump). 

The data that should be found in this folder is as follows:

- [dt_land_use.gdb](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_land_usegdb-qld_land_usegdb-wt_land_usegdb-and-mwi_land_usegpkg)
- [qld_land_use.gdb](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_land_usegdb-qld_land_usegdb-wt_land_usegdb-and-mwi_land_usegpkg)
- [wt_land_use.gdb](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_land_usegdb-qld_land_usegdb-wt_land_usegdb-and-mwi_land_usegpkg)
- [dt_land_use_1999.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#all-converted-datasets)
- [dt_land_use_2009.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#all-converted-datasets)
- [dt_land_use_2016.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#all-converted-datasets)
- [mwi_land_use.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_land_usegdb-qld_land_usegdb-wt_land_usegdb-and-mwi_land_usegpkg)
- [mwi_land_use_1999.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#all-converted-datasets)
- [mwi_land_use_2009.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#all-converted-datasets)
- [mwi_land_use_2016.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#all-converted-datasets)
- [qld_land_use_2021.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#all-converted-datasets)
- [wt_land_use_1999.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#all-converted-datasets)
- [wt_land_use_2009.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#all-converted-datasets)
- [wt_land_use_2015.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#all-converted-datasets)

And the data folder should look like this: 

![land use example](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_climate_land_use_example.png?raw=true)

### dt_land_use.gdb, qld_land_use.gdb, wt_land_use.gdb, and mwi_land_use.gpkg

All land use data is downloaded from [QSpatial](https://qldspatial.information.qld.gov.au/catalogue/custom/index.page): 

- Search for:
	- "Land use mapping - 1999 to 2016 - Burdekin NRM".
	- "Land use mapping - 2021 - Great Barrier Reef NRM regions".
	- "Land use mapping - 1999 to 2015 - Wet Tropics NRM region".
	- "Land use mapping - 1999 to 2016 - Mackay Whitsunday NRM".
- Download as is, there are no formatting options.
- Store as: 
	- .../n3_climate_land-use/dt_land_use.gdb (.gdb files look like a folder, you must save the whole folder).
	- .../n3_climate_land-use/qld_land_use.gdb
	- .../n3_climate_land-use/wt_land_use.gdb
	- .../n3_climate_land-use/mwi_land_use.gpkg
- Use QGIS to [convert](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#convert-land-use-data) all files into 3 .gpkg files named "dt_land_use_1999.gpkg", updating the year and region.

> Wet Tropics has data from 2015 **not** 2016, this is not a typo, ensure wt data is labelled appropriately.

### All Converted Datasets

All datasets with file names ending with a specific year have to be created by [converting](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#convert-land-use-data) the original land use data using QGIS. A link to download QGIS can be 
found on the [QGIS Website](https://www.qgis.org/en/site/forusers/download.html), and a step-by-step guide on converting the files is [below](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#convert-land-use-data). [^5]

[^5]: The data must be processed by QGIS because it is only provided as a geodatabase (gdb) file by QSpatial. GDB files that are this large are cumbersome and time consuming to be read and edited in R, so we will use QGIS to convert 
the gdb files into gpkg files. Note that although the MWI data is provided as a geopackage file (no idea why), it still needs to be split into individual years of data so that the script can perform the same processes. I.e. we want to
standardised the input data.

### Convert Land Use Data

The steps to convert each file to a gpkg are as follows:
- Download and Open [QGIS](https://www.qgis.org/en/site/forusers/download.html).
- Click and drag any one of the .gdb folders into QGIS here: 

![gdb_conversion_1](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/gdb_conversion_1.png?raw=true)

- In the pop-up box, select only the layers that have the letter "lu" in their name (note the QLD dataset only has one layer so the pop-up wont occur for that dataset): 

![gdb_conversion_2](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/gdb_conversion_2.png?raw=true)

- Right click on a layer in the bottom right panel, select "export", "save features as": 

![gdb_conversion_3](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/gdb_conversion_3.png?raw=true)

- In the pop-up box ensure that:
	- Format = GeoPackage
	- File name = ".../n3_climate_land-use/dt_land_use_1999.gpkg", entering the correct year for each dataset.
	- Layer name = "dt_land_use_1999.gpkg" (this should auto fill if you complete the file name first).
	- CRS = "EPSG:7844 - GDA2020" (further instructions on how to find this below).

![gdb_conversion_4](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/gdb_conversion_4.png?raw=true)

- Save the file, and repeat for all other years and datasets.

To find the EPSG:7844 - GDA2020 CRS:
1. Click the world icon.
2. Filter for "GDA2020".
3. Use the scroll bar and go all the way to the top.
4. Select GDA2020, with the Authority ID EPSG:7844.

![gdb_conversion_5](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/gdb_conversion_5.png?raw=true)

## n3_climate_rainfall

The data that should be found in this folder is as follows:

- [monthly_rainfall.nc](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#monthly_rainfallnc)
- [n3_rainfall.nc](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_rainfallnc)

And the data folder should look like this:

![Rainfall Example](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_climate_rainfall_example.png?raw=true)

### monthly_rainfall.nc

- Rainfall is downloaded from the [BOM's Australian Water Outlook (AWO) portal](https://awo.bom.gov.au/)
- Click download (top right) and choose the following format: 
	- File Type = NetCDF
	- Product = Historical
	- Time Aggregation = Month
	- Values = Absolute
	- Variable = Precipitation
- Store the .nc file as **data/n3_climate_rainfall/monthly_rainfall.nc**.

### n3_rainfall.nc

This data is automatically created and saved by the script, it is referenced in future renders to save processing time.

## n3_climate_sea-surface-temperature

The data that should be found in this folder is as follows:

- [monthly_sst](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#monthly_sst)
- [n3_sst.nc](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_sstnc)

And the data folder (and sub folders) should look like this:

![sea surface temperature Example1](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_climate_sst_example_1.png?raw=true)

![sea surface temperature Example2](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_climate_sst_example_2.png?raw=true)

### monthly_sst

- Data is automatically downloaded within the sst script - there is no need to download any data manually.
- If the automated data dowload works, the data will be stored inside the "monthly_sst" folder.
- Data is then cropped to the n3 region and saved as n3_sst.nc.
- However, if the automatic data request script fails, data can be manually retrieved from NOAA's [CoralReefWatch](https://coralreefwatch.noaa.gov/product/5km/index.php) site;
	- Scroll down to "Data Access via HTTP Server:"
	- Click SST under NETCDF4 Data
	- Pick a year from the list.
	- Use Ctrl+F and search for "ct5km_sst-mean_v3.1_198501", changing month and year to the target.
	- Download the .nc file, not the .nc.md5 file.
	- Save each file as ".../monthly_sst/sst_198501.nc", where the month and year is updated.

For additional information go to NOAA's [CoralReefWatch](https://coralreefwatch.noaa.gov/), and review NOAA's [methods](https://coralreefwatch.noaa.gov/product/5km/methodology.php).

### n3_sst.nc

This data is automatically created and saved by the script, it is referenced in future renders to save processing time.

## n3_dem

This folder is an exception to the data organisation and naming rules covered in [Naming Conventions](https://github.com/Northern-3/spatial-analyses#naming-conventions). While all other data folders share the same name as the 
associated script, the n3_dem data folder does not (there is no "n3_dem" script). Instead this is a generic folder that contains data used by all "n3_dem_xxx" scripts. Each script accesses the same data, selects the pieces 
it needs, and save those to its own folder. 

The data that should be found in this folder is as follows:

- [great_barrier_reef_bathymetry_30m](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#great_barrier_reef_bathymetry_30m-and-great_barrier_reef_bathymetry_100m)
- [great_barrier_reef_bathymetry_100m](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#great_barrier_reef_bathymetry_30m-and-great_barrier_reef_bathymetry_100m)
- [gbr_30m.nc](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#gbr_30mnc)
- [gbr_100m.nc](https://github.com/Northern-3/spatial-analyse?tab=readme-ov-files#gbr_100mnc)

And the data folder (and sub folders) should look like this:

![N3 DEM Example](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_dem_example_1.png?raw=true)

![Great Barrier Reef 30m storage example](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_dem_example_2.png?raw=true)

![Great Barrier Reef 100m storage example](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_dem_example_3.png?raw=true)

### great_barrier_reef_bathymetry_30m and great_barrier_reef_bathymetry_100m

- GBR data is provided by [AUS SEABED](https://portal.ga.gov.au/persona/marine) as a GeoTIFF.
- Select "Layers" from the toolbar at the top of the page
- Select "Elevation and Depth" and then "Bathymetry - Compilations"
- Search for:
	- "Great Barrier Reef Bathymetry 2020 30m" and click it.
	- "Great Barrier Reef Bathymetry 2020 100m" and click it.
- Click "about", then click "More Details" (The "download here" button sometimes does not work).
- On the new page download the data from the link under "Description"
- Unzip the downloaded folder
- Save the folder as:
	- "data/n3_dem/great_barrier_reef_bathymetry_30m/"
	- "data/n3_dem/great_barrier_reef_bathymetry_100m/"
- Rename files inside the 30m folder as "great_barrier_reef_30m_**a**.tif" substituting the correct letter (a, b, c, d).
- Rename the file inside the 100m as "great_barrier_reef_100m.tif".

Bathymetry data is used to create 3D models of the northern three region. The 30m resolution data is used for final renders, the 100m resolution data is used to quickly iterate over a process.

## n3_ereefs

> [!Note]
> All information on this topic outside of data downloading specifics can be found on [issue 56](https://github.com/Northern-3/spatial-analyses/issues/56).

The data that should be found in this folder is as follows:

- raw/
	+ [chla_single.nc](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#chla_singlenc)
- validation/
	+ [all_data.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#all_datacsv-inspection_pointscsv-logger_datacsv-original_curvilinear_datacsv-pandora_daily_logger_cleancsv-pelorus_daily_logger_cleancsv-pelorus_daily_logger_cleancsv-stars_datacsv)
	+ [inspection_points.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#all_datacsv-inspection_pointscsv-logger_datacsv-original_curvilinear_datacsv-pandora_daily_logger_cleancsv-pelorus_daily_logger_cleancsv-pelorus_daily_logger_cleancsv-stars_datacsv)
	+ [logger_data.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#all_datacsv-inspection_pointscsv-logger_datacsv-original_curvilinear_datacsv-pandora_daily_logger_cleancsv-pelorus_daily_logger_cleancsv-pelorus_daily_logger_cleancsv-stars_datacsv)
	+ [original_curvilinear_data.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#all_datacsv-inspection_pointscsv-logger_datacsv-original_curvilinear_datacsv-pandora_daily_logger_cleancsv-pelorus_daily_logger_cleancsv-pelorus_daily_logger_cleancsv-stars_datacsv)
	+ [pandora_daily_logger_clean.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#all_datacsv-inspection_pointscsv-logger_datacsv-original_curvilinear_datacsv-pandora_daily_logger_cleancsv-pelorus_daily_logger_cleancsv-pelorus_daily_logger_cleancsv-stars_datacsv)
	+ [pandora_daily_logger_original.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#pandora_daily_logger_originalcsv-pelorus_daily_logger_originalcsv-pelorus_daily_logger_originalcsv)
	+ [pelorus_daily_logger_clean.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#all_datacsv-inspection_pointscsv-logger_datacsv-original_curvilinear_datacsv-pandora_daily_logger_cleancsv-pelorus_daily_logger_cleancsv-pelorus_daily_logger_cleancsv-stars_datacsv)
	+ [pelorus_daily_logger_original.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#pandora_daily_logger_originalcsv-pelorus_daily_logger_originalcsv-pelorus_daily_logger_originalcsv)
	+ [pelorus_hourly_logger_clean.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#all_datacsv-inspection_pointscsv-logger_datacsv-original_curvilinear_datacsv-pandora_daily_logger_cleancsv-pelorus_daily_logger_cleancsv-pelorus_daily_logger_cleancsv-stars_datacsv)
	+ [pelorus_hourly_logger_original.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#pandora_daily_logger_originalcsv-pelorus_daily_logger_originalcsv-pelorus_daily_logger_originalcsv)
	+ [stars_data.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#all_datacsv-inspection_pointscsv-logger_datacsv-original_curvilinear_datacsv-pandora_daily_logger_cleancsv-pelorus_daily_logger_cleancsv-pelorus_daily_logger_cleancsv-stars_datacsv)

And the data folders should look like this:

![N3 eReefs Example 1](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_ereefs_example_1.png?raw=true)

![N3 eReefs Example 2](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_ereefs_example_2.png?raw=true)

![N3 eReefs Example 3](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_ereefs_example_3.png?raw=true)

### raw

This folder contains raw data that comes straight form online sources.

#### chla_single.nc

This data is automatically created and saved by the script, no download is required.

### validation

This folder contains data that is used to validate the raw data, some of it has also been manually downloaded and edited slightly.

#### all_data.csv, inspection_points.csv, logger_data.csv, original_curvilinear_data.csv, pandora_daily_logger_clean.csv, pelorus_daily_logger_clean.csv, pelorus_daily_logger_clean.csv, stars_data.csv

This data is automatically created and saved by the script, no download is required.

#### pandora_daily_logger_original.csv, pelorus_daily_logger_original.csv, pelorus_daily_logger_original.csv

- logger data is downloaded from the [AIMS MMP program](https://apps.aims.gov.au/metadata/view/8a698de1-3fbf-48a5-b068-358b07aad35c).
- scroll down to "Data Downloads" at the bottom of the page
- select:
	- "Daily average logger data for each site"
	- "Hourly logger data for each site"
- fill out the form and submit, and the files will download
- once downloaded, unzip each folder and copy the pandora and pelorus daily, and pelorus hourly data
- rename the files as:
	- "pandora_daily_logger_original.csv"
	- "pelorus_daily_logger_original.csv"
	- "pelorus_hourly_logger_original.csv"
- and save in the n3_ereefs data folder

If you would like to compare data against more loggers, there are more availabled in the zipped folders.

## n3_habitat

This folder is an exception to the data organisation and naming rules covered in [Naming Conventions](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#naming-conventions). While all other data folders share the same name as the 
associated script, the n3_habitat folder does not (there is no "n3_habitat" script). Instead this is a generic folder that contains data used by most "n3_habitat_xxx" scripts. Each script accesses the same data, selects the pieces 
it needs, and save those to its own folder. 

The data that should be found in this folder is as follows:

- [re_raw](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#re_raw)

And the data folder (and sub folders) should look like this:

![N3 Habitat Folder Example](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_habitat_example_1.png?raw=true)

![Regional Ecosystems Raw Example](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_habitat_example_2.png?raw=true)

### re_raw

- Regional Ecosystem (RE) data is downloaded from [QSpatial](https://qldspatial.information.qld.gov.au/catalogue/custom/index.page) and consists of 2 datasets[^6]:
- Click on the "Regional Ecosystem Series" (bottom left).
- Select (on the right): 
	- "Biodiversity status of [year] remnant regional ecosystems – Queensland".
	- "Biodiversity status of pre-clearing regional ecosystems – Queensland".
- Download as a GeoPackage 1.0 - GEOPACKAGE_1.0 - .gpkg, with GDA2020 geographic 2D (EPSG:7844).
- Store the .gpkg files as:
	- "data/n3_habitat/re_raw/re_remnant_2021_v12_2.gpkg".
	- "data/n3_habitat/re_raw/re_pre_clear_v12_2.gpkg".
- For additional years of data[^8] each year must be extracted from the geodatabase file.
- A link to the file can be found [here](https://cloudstor.aarnet.edu.au/plus/s/SwWlLyDyIufXTPb) and context in the footnote[^8].
- For a guide to converting the geodatabase file to gpkg files, see [Convert Regional Ecosystem Data.](https://github.com/Northern-3/spatial-analyses#convert-regional-ecosystem-data)

### Convert Regional Ecosystem Data

The steps to convert each file to a gpkg are as follows:
- Download and Open [QGIS](https://www.qgis.org/en/site/forusers/download.html).
- Click and the .gdb folder into QGIS here: 

![gdb_conversion_1](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/gdb_conversion_1.png?raw=true)

- In the pop-up box, select all layers 
- Right click on a layer in the bottom right panel, select "export", "save features as": 

![gdb_conversion_6](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/gdb_conversion_6.png?raw=true)

- In the pop-up box ensure that:
	- Format = GeoPackage
	- File name = ".../n3_habitat/re_raw/re_remnant_1997_v12_2.gpkg", entering the correct year for each dataset.
	- Layer name = "re_remnant_1997_v12_2.gpkg" (this should auto fill if you complete the file name first).
	- CRS = "EPSG:7844 - GDA2020" (further instructions on how to find this below).

![gdb_conversion_7](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/gdb_conversion_7.png?raw=true)

- Save the file, and repeat for all other years and datasets.

To find the EPSG:7844 - GDA2020 CRS:
1. Click the world icon.
2. Filter for "GDA2020".
3. Use the scroll bar and go all the way to the top.
4. Select GDA2020, with the Authority ID EPSG:7844.

![gdb_conversion_5](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/gdb_conversion_5.png?raw=true)

[^6]: Although only the pre-clear and latest year of RE data is available to download from QSpatial, in Nov 2022 a data request was made by Adam Shand to Dale Richter (dale.richter@des.qld.gov.au) for the middle years of data. 
These were provided by link to cloudstor [here](https://cloudstor.aarnet.edu.au/plus/s/SwWlLyDyIufXTPb). If the link does not work, contact Adam Shand (to@drytropicshealthywaters.org) first, then Dale Richter if unresolved. Although 
not manditory for the technical report, nor for the script to run, this middle data can provided important context for trends over time.

To understand regional ecosystems, and descriptions, see [info 1](https://www.qld.gov.au/environment/plants-animals/plants/ecosystems/descriptions), 
[info 2](https://www.qld.gov.au/environment/plants-animals/plants/ecosystems/descriptions/download), and the [training resources](https://www.publications.qld.gov.au/dataset/training-regional-ecosystem-fwork).

## n3_habitat_broad-vegetation-groups

The data that should be found in this folder is as follows:

- [re_broad_vegetation_groups_cropped](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#re_broad_vegetation_groups_cropped)
- [broad_vegetation_groups.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#broad_vegetation_groupsgpkg)

And the data folder (and sub folders) should look like this:

![Broad Vegetation Groups Example](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_habitat_broad_vegetation_groups_example_1.png?raw=true)

![BVG Cropped Example](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_habitat_broad_vegetation_groups_example_2.png?raw=true)

### re_broad_vegetation_groups_cropped

This data is automatically created and saved by the script, however requires RE data to run, refer to [n3_habitat](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_habitat).

### broad_vegetation_groups.gpkg

This data is automatically created and saved by the script, however requires RE data to run, refer to [n3_habitat](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_habitat).

## n3_habitat_freshwater-wetlands

> [!Note]
> Insufficient wetland data is available online[^7], contact Adam Shand (to@drytropicshealthywaters.org) for access.

[^7]: Similarly to the regional ecosystem data, wetland data is only available on QSpatial for the most recent year. However, unlike the RE data, no pre-clear layer is provided so change over time cannot be calculated. Therefore, 
in March 2023 a data request was made by Adam Shand to Katharine Glanville (katharine.glanville@des.qld.gov.au) for all other years of data. All data was provided via a link to cloudstor 
[here](https://itpqld-my.sharepoint.com/personal/dale_richter_des_qld_gov_au/_layouts/15/onedrive.aspx?id=%2Fpersonal%2Fdale%5Frichter%5Fdes%5Fqld%5Fgov%5Fau%2FDocuments%2FData%20Share%2FWetlands%20Version%206&fromShare=true&ga=1). 
Please note the cloudstor link may break, if so please contact first Adam Shand, then if unresolved, Katharine Glanville.

Although this is an "n3_habitat" script, it does not use the same RE dataset, instead it uses wetland data.

The data that should be found in this folder is as follows:

- [all_qld_wetlands.gdb](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#all_qld_wetlandsgdb)
- [n3_wetlands.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_wetlandsgpkg)

And the data folder should look like this:

![Wetlands Example](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_habitat_freshwater_wetlands_example.png?raw=true)

### all_qld_wetlands.gdb

- Data is downloaded from a CloudStor link [here](https://cloudstor.aarnet.edu.au/plus/s/WJTdzoY4vaFpnUp), if unavailable see here[^9].
- Download the file and unzip data.
- Move the "Wetlands_v6.gdb/" file into the "/n3_habitat_freshwater-wetlands/" folder.
- Rename "/Wetlands_v6.gdb/" to **"/qld_wetlands.gdb/"**.
- Delete all other folders as these are no longer needed.

### n3_wetlands.gpkg

This data is automatically created and saved by the script, it is referenced in future renders to save processing time.

## n3_habitat_mangroves-and-saltmarshes

The data that should be found in this folder is as follows:

- [re_mangroves_and_saltmarshes_cropped](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#re_mangroves_and_saltmarshes_cropped)
- [mangroves_and_saltmarshes.csv](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#mangroves_and_saltmarshesgpkg-and-csv10)[^8]
- [mangroves_and_saltmarshes.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#mangroves_and_saltmarshesgpkg-and-csv10)

And the data folder (and sub folders) should look like this:

![Mangroves and Saltmarshes Example](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_habitat_mangroves_and_saltmarshes_example_1.png?raw=true)

![M&S Cropped Example](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_habitat_mangroves_and_saltmarshes_example_2.png?raw=true)

[^8]: Why are we saving a csv? The csv is created using the mangrove and saltmarsh spatial file half-way through its creation. By the time the spatial file is completed and saved the csv can no longer be calculated - thus it has to be
done (and saved) at the same time.

### mangroves_and_saltmarshes.gpkg (and .csv)[^10]

This data is automatically created and saved by the script, however requires RE data to run, refer to [n3_habitat](https://github.com/Northern-3/spatial-analyses#n3_habitat).

### re_mangroves_and_saltmarshes_cropped

This data is automatically created and saved by the script, however requires RE data to run, refer to [n3_habitat](https://github.com/Northern-3/spatial-analyses#n3_habitat).

## n3_habitat_riparian-vegetation

> [!Note]
> This script uses RE data in the n3_habitat folder, and additional datasets to define the riparian zone.

The data that should be found in this folder is as follows:

- [re_riparian_cropped](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#re_riparian_cropped)
- [riparian_area](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#riparian_corridorsgpkg-and-watercourse_linesgpkg)
	- [riparian_corridors.gdb](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#riparian_corridorsgpkg-and-watercourse_linesgpkg)
	- [n3_riparian_boundaries.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_riparian_boundariesgpkg)
	- [watercourse_lines.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#riparian_corridorsgpkg-and-watercourse_linesgpkg)

And the data folder (and sub folders) should look like this:

![Riparian Vgetation Example 1](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_habitat_riparian_vegetation_example_1.png?raw=true)

![Riparian Vgetation Example 2](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_habitat_riparian_vegetation_example_2.png?raw=true)

![Riparian Vgetation Example 3](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_habitat_riparian_vegetation_example_3.png?raw=true)

### re_riparian_cropped

This data is automatically created and saved by the script, however requires RE data to run, refer to [n3_habitat](https://github.com/Northern-3/spatial-analyses#n3_habitat).

### riparian_corridors.gpkg and watercourse_lines.gpkg

- The riparian corridors and watercourse lines datasets are downloaded from [QSpatial](https://qldspatial.information.qld.gov.au/catalogue/custom/index.page)
- Search for:
	- "Watercourse lines - North East Coast drainage division".
	- "Queensland statewide corridors".
- Download:
	- as a GeoPackage 1.0 - GEOPACKAGE_1.0 - .gpkg, with GDA2020 geographic 2D (EPSG:7844).
	- as is, there are no formatting options.
- Store:
	- the .gpkg file as .../riparian_areas/watercourse_lines.gpkg.
	- the .gdb file as .../riparian_areas/riparian_corridors.gdb.
- The metadata does not need to be stored.

### n3_riparian_boundaries.gpkg

This data is automatically created and saved by the script, however requires the original riparian boundaries to run.

## n3_litter

> [!Note]
> This folder is currently under works

- [n3_litter.csv***](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#dt_littercsv)

### n3_litter.csv***

This dataset has no online equivalent, it is stored in this repo and can be found under **data/n3_litter/n3_litter.csv**. Currently it is only required by a Dry Tropics specific script, and is not a dependency for 
any other scripts in the repo. Nothing needs to be done regarding naming or storage for this dataset.

Context: Dinny Taylor has been creating a litter metric for the RRC network, as part of this she request a map of litter sites in the Dry Tropics region and provided this file with spatial information.

## n3_prep_region-builder

> [!Note]
> The R package "gisaimsr" is required for this script to work, refer to the [gisaimsr](https://github.com/Northern-3/spatial-analyses#gisaimsr-r-package) section below.

The data that should be found in this folder is as follows:

- [extras/](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#extras)
	+ [qld_place_names.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#qld_place_namesgpkg)
- [processed/](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#processed-region-builder)
	+ [n3_epp_env.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#processed-region-builder)
	+ [n3_epp_mi.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#processed-region-builder)
	+ [n3_epp_so.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#processed-region-builder)
	+ [n3_epp_wt.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#processed-region-builder)
- [raw/](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#raw-region-builder)
	+ [drainage_basins_sub_areas.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#raw-region-builder)
	+ [drainage_basins.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#raw-region-builder)
	+ [epp_water_env_value_zones_qld.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#raw-region-builder)
	+ [epp_water_management_intent_qld.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#raw-region-builder)
	+ [epp_water_schedule_outlines_qld.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#raw-region-builder)
	+ [epp_water_water_types_qld.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#raw-region-builder)
- [n3_region.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_regiongpkg)

And the data folder (and sub folders) should look like this:

![Region Builder Example 1](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_prep_region_builder_example_1.png?raw=true)

![Region Builder Example 2](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_prep_region_builder_example_2.png?raw=true)

![Region Builder Example 3](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_prep_region_builder_example_3.png?raw=true)

![Region Builder Example 4](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_prep_region_builder_example_4.png?raw=true)

### processed (region-builder)

This data is automatically created and saved by the script, however requires the raw data to be created.

### raw (region-builder)

- All of these datasets are downloaded from [QSpatial](https://qldspatial.information.qld.gov.au/catalogue/custom/index.page), search for:
	- "Drainage Basins - Queensland" [^9]
	- "Drainage Basins sub areas - Queensland" [^10]
	- "Environmental Protection (Water and Wetland Biodiversity) Policy 2019 - Environmental Value Zones" [^11]
	- "Environmental Protection (Water and Wetland Biodiversity) Policy 2019 - Management Intent" [^11]
	- "Environmental Protection (Water and Wetland Biodiversity) Policy 2019 - Schedule Outlines" [^11]
	- "Environmental Protection (Water and Wetland Biodiversity) Policy 2019 - Water Types - Queensland" [^11]
- Download each file:
	- As a GeoPackage 1.0 - GEOPACKAGE_1.0 - .gpkg, with GDA2020 geographic 2D (EPSG:7844) if the option exists.
- Store the files as:
	- data/n3_prep_region-builder/raw/drainage_basins.gpkg
	- data/n3_prep_region-builder/raw/drainage_basin_sub_areas.gpkg
	- data/n3_prep_region-builder/raw/epp_water_env_value_zones_qld.gpkg
	- data/n3_prep_region-builder/raw/epp_water_management_intent_qld.gpkg
	- data/n3_prep_region-builder/raw/epp_water_schedule_outlines_qld.gpkg
	- data/n3_prep_region-builder/raw/epp_water_water_types_qld.gpkg

- The metadata (.html and .xml) does not need to be stored.

### extras

Data in this folder is generally used as an "extra" in almost all scripts throughout the repo. 

#### qld_place_names.gpkg

This file is a generic dataset used by multiple scripts, which makes it foundational (i.e. should be downloaded before any other script is run), and thus is stored here. The file is downloaded from [QSpatial](https://qldspatial.information.qld.gov.au/catalogue/custom/index.page):

- Search for:
	+ "Place names gazetteer - Queensland"
- Download as a GeoPackage 1.0 - GEOPACKAGE_1.0 - .gpkg, with GDA2020 geographic 2D (EPSG:7844).
- Extract only the .gpkg data file (metadata does not need to be stored) and,
- Store the .gpkg file as:
	+"data/n3_prep_region-builder/qld_place_names.gpkg

### n3_region.gpkg

This is the final output of the n3_region-builder script and is the file used by all subsequent scripts.

[^9]: The N3 region is divided into multiple basins. This dataset provides basin polygons for every basin in queensland based on the dominant water drainage pattern. Refer to 
[Issue 1](https://github.com/Northern-3/spatial-analyses/issues/1) for further discussion.

[^10]: A child of the drainage basins dataset, provides additional breakdown of basins, a key data for the Wet Tropics and Dry Tropics. Refer to [Issue 2](https://github.com/Northern-3/spatial-analyses/issues/2) for further discussion.

[^11]: EPP layers are created by DES for a wide range of environmental policy requirements, e.g., areas of "High ecological value". The Environmental Value Zones, Management Intent, and Schedule Outlines datasets are used specifically by the Dry Tropics 
region, the Water Types dataset is used across the N3 region.

## n3_prep_watercourse-builder

> [!Warning]
> Some data in this folder is custom, with no online equivalent. Do not delete or make changes to these datasets.


The data that should be found in this folder is as follows:

- [processed/](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#processed-watercourse-builder)
	+ [n3_watercourse_lines.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#processed-watercourse-builder)
- [raw/](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#raw-watercourse-builder)
	+ [riparian_corridors.gdb](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#raw-watercourse-builder)
	+ [lakes.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#raw-watercourse-builder)
	+ [lakes_ross_extra.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#raw-watercourse-builder) (custom)
	+ [watercourse_areas.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#raw-watercourse-builder)
	+ [watercourse_lines_central.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#raw-watercourse-builder)
	+ [watercourse_lines_northern.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#raw-watercourse-builder)
- [n3_watercourse.gpkg](https://github.com/Northern-3/spatial-analyses?tab=readme-ov-file#n3_watercoursegpkg)

And the data folder (and sub folders) should look like this:

![Watercourse Builder Example 1](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_prep_watercourse_builder_example_1.png?raw=true)

![Watercourse Builder Example 2](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_prep_watercourse_builder_example_2.png?raw=true)

![Watercourse Builder Example 3](https://github.com/Northern-3/spatial-analyses/blob/main/references/images/README_images/n3_prep_watercourse_builder_example_3.png?raw=true)

### processed (watercourse-builder)

This data is automatically created and saved by the script, however requires the raw data to be created.

### raw (watercourse-builder)

- Exlcuding "lakes_ross_extra.gpkg" (which is custom), all of these datasets are downloaded from [QSpatial](https://qldspatial.information.qld.gov.au/catalogue/custom/index.page), search for:
	- "Queensland statewide corridors" (this is the riparian corridors dataset)
	- "Lakes - Queensland"
	- "Watercourse areas - Queensland"
	- "Watercourse lines - North East Coast drainage division - northern section"
	- "Watercourse lines - North East Coast drainage division - central section"
- Download each file:
	- As a GeoPackage 1.0 - GEOPACKAGE_1.0 - .gpkg, with GDA2020 geographic 2D (EPSG:7844) if the option exists.
	- Or as is (for the Queensland statewide corridors dataset).
- Store the files as:
	- data/n3_prep_watercourse-builder/raw/riparian_corridors.gdb
	- data/n3_prep_watercourse-builder/raw/lakes.gpkg
	- data/n3_prep_watercourse-builder/raw/watercourse_areas.gpkg
	- data/n3_prep_watercourse-builder/raw/watercourse_lines_central.gpkg
	- data/n3_prep_watercourse-builder/raw/watercourse_lines_northern.gpkg

- The metadata (.html and .xml) does not need to be stored.

# 6. Additional Resources

Data analysis in R is an incredibly large topic with rabbitholes at every turn. Not to mention the absolute blackhole that is spatial analysis in R. Below are some of the most useful resources I have found throughout my journey,
if you are new to spatial analytics in R, this is a good place to get your bearings.

Issue Tracking (and To-Do List)
- [Issues](https://github.com/Northern-3/spatial-analyses/issues), another page on this repo that documents issues and improvements. (also acts as a to-do list).

Books:
- [Writing by the author of almost every core R spatial package](https://r-spatial.org/book/)
- [Another great option](https://r.geocompx.org/index.html)

Tutorials: the first two are from a friend of mine [Christina](https://github.com/cabuelow) who is brilliant in this area.
- [R for Mapping](https://cabuelow.quarto.pub/r-for-mapping-and-more/)
- [Calculating Areas With Vector and Raster Data](https://cabuelow.quarto.pub/calculating-areas-with-vector-and-raster-data-in-r/)
- [Using the SF package](https://r-spatial.github.io/sf/articles/)

Quarto: The new and improved Rmarkdown, documentation is from the RStudio[^12] team themselves.
- [Quick Start](https://quarto.org/docs/get-started/)
- [Main Guide](https://quarto.org/docs/guide/)

[^12]: The RStudio team is current rebranding as [Posit](https://posit.co/)

3D Models in R: this sub branch is honestly incredibly entertaining to mess around with.
- [Rayshader](https://www.rayshader.com/index.html) (don't forget to go through his tutorials and blog posts).
- [Rayrender](https://www.rayrender.net/)
- [Package Author](https://www.tylermw.com/)

Specific (and Critical) Packages For This Repo
- [here](https://here.r-lib.org/)
- [sf](https://r-spatial.github.io/sf/index.html)
- [terra](https://rspatial.github.io/terra/index.html)
- [stars](https://r-spatial.github.io/stars/index.html) (not used as frequently).
- [tidyverse](https://cran.r-project.org/web/packages/tidyverse/vignettes/paper.html)
	- of which [dplyr](https://dplyr.tidyverse.org/articles/programming.html) is the most used, but all are useful.
- [gisaimsr]
	+ [Package introduction.](https://open-aims.github.io/gisaimsr/index.html)
	+ [Indepth guide.](https://open-aims.github.io/gisaimsr/articles/examples.html)
	+ [Metadata.](httpsopen-aims.github.iogisaimsrreferencewbodies.html)
- [cheatsheets for these packages, and more](https://posit.co/resources/cheatsheets/)

Organising your Repository
- [Naming Things](https://docplayer.net/55248970-Naming-things-prepared-by-jenny-bryan-for-reproducible-science-workshop.html)
- [Best Practices](https://docs.github.com/en/issues/planning-and-tracking-with-projects/learning-about-projects/best-practices-for-projects)
- [Everything GitHub](https://docs.github.com/en)

General GIS information
- [Geographic vs Project Coordinate Systems](https://www.esri.com/arcgis-blog/products/arcgis-pro/mapping/gcs_vs_pcs/#:~:text=What%20is%20the%20difference%20between,map%20or%20a%20computer%20screen.)
- [QGIS flavor for CRS](https://docs.qgis.org/3.28/en/docs/gentle_gis_introduction/coordinate_reference_systems.html)
- [Australian focus spatial news](https://www.ga.gov.au/scientific-topics/positioning-navigation/positioning-australia)
- [Common Australian EPSG Codes](https://github.com/Northern-3/spatial-analyses/blob/main/references/other_documents/aus_epsg_codes_and_transformations.pdf)

Common Issues
- [Invalid Geometries](https://r-spatial.org/r/2017/03/19/invalid.html)
- [Or Just Search StackOverflow](https://stackoverflow.com/)

Places to Look for Spatial Data
- [QSpatial](https://qldspatial.information.qld.gov.au/catalogue/)
- [Queensland Globe](https://qldglobe.information.qld.gov.au/)
- [Australia Water Outlook](https://awo.bom.gov.au/products/historical/soilMoisture-rootZone/4,-27.528,134.209/nat,-25.609,134.362/r/d/2023-07-04)
- [ELVIS](https://elevation.fsdf.org.au/)
- [AUS SeaBed](https://portal.ga.gov.au/persona/marine) (which is a subset of [geoscience australia](https://portal.ga.gov.au/)).
- [Australian Soils](https://portal.ansis.net/)
- [Queensland WetlandInfo](https://wetlandinfo.des.qld.gov.au/wetlands/)
- [eReefs](https://www.ereefs.org.au/) (go up to the eReefs specific section for more information).
	- [via AIMS portal](https://ereefs.aims.gov.au/ereefs-aims)
	- [visualisation portal](https://portal.ereefs.info/map)
	- [The best tutorials](https://open-aims.github.io/ereefs-tutorials/)
- [Digital Earth Australia](https://www.dea.ga.gov.au/)

