#This function is used to download and install all required packages needed in the spatial-analysis repository. 
#The reason that this function exists is detailed in [issue 85](https://github.com/Northern-3/spatial-analyses/issues/85).
#INPUT:
#x = package name (can be supplied one at a time or in a vector, ie. c())

package_handling <- function(){
  
  #first check for devtools (as this is required to get the special packages)
  if (!require("devtools", character.only = TRUE)){install.packages("devtools", dep = TRUE)}#install the devtools package if it wasn't already
  
  #then check for, and install, each special package from its unique address
  if (!require("rayshader", character.only = TRUE)){devtools::install_github("tylermorganwall/rayshader")}
  if (!require("gisaimsr", character.only = TRUE)){devtools::install_github("https://github.com/open-AIMS/gisaimsr")}
  if (!require("ereefs", character.only = TRUE)){devtools::install_github("https://github.com/open-AIMS/ereefs")}
  if (!require("dataaimsr", character.only = TRUE)){devtools::install_github("ropensci/dataaimsr")}
  
  #whitebox has a weird triple step
  if (!require("whitebox", character.only = TRUE)){
    devtools::install_github("giswqs/whiteboxR")
    whitebox::install_whitebox()
    whitebox::wbt_init()
  }

  #lastly check for, and install, nngeo as this is silently used in the background of several scripts
  if (!require("nngeo", character.only = TRUE)){install.packages("nngeo", dep = TRUE)}#install if needed
  
}
