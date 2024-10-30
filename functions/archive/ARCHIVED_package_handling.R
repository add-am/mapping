#This function is used to download and install all required packages needed in the spatial-analysis repository. 
#The reason that this function exists is detailed in [issue 85](https://github.com/Northern-3/spatial-analyses/issues/85).
#INPUT:
#x = package name (can be supplied one at a time or in a vector, ie. c())

package_handling <- function(x){
  
  for (i in x){
    
    if (!require(i, character.only = TRUE)){#check if a package needs to be downloaded, if so:
      
      if (i %in% c("rayshader", "gisaimsr", "ereefs", "dataaimsr", "whitebox")){#check if the package asked for is one of a few special packages
        
        #explicitly check for devtools (as this is required to get the special packages)
        if (!require("devtools", character.only = TRUE)){
          
          install.packages("devtools", dep = TRUE)#install the devtools package if it wasn't already
          
        }
        
        #for each of the three special packages, install it from its unique address
        if (i == "rayshader"){devtools::install_github("tylermorganwall/rayshader")}
        else if (i == "gisaimsr"){devtools::install_github("https://github.com/open-AIMS/gisaimsr")}
        else if (i == "ereefs"){devtools::install_github("https://github.com/open-AIMS/ereefs")}
        else if (i == "dataaimsr"){devtools::install_github("ropensci/dataaimsr")}
        else if (i == "whitebox"){#whitebox has a weird triple step
          devtools::install_github("giswqs/whiteboxR")
          whitebox::install_whitebox()
          whitebox::wbt_init()}
        
      }
      
      install.packages(i, dep = TRUE)#for "normal" packages, the standard install is fine
      
      if(!require(i, character.only = TRUE)){#check again if the package needs to be downloaded, if it still needs to downloaded:
        
        stop("Package not found")#there was an error, stop and send a message
        
      }
    }
  }
  
  #manually check for the nngeo package as this is used silently in the background of several scripts but never explicitly called
  if (!require("nngeo", character.only = TRUE)){#check if needed
    
    install.packages("nngeo", dep = TRUE)#install if needed
  }
}


