#inputs: 
#df <- any tbl or data.frame - although this function will obviously only work with the monthly climate tables
#file name <- whatever you want the output file to be named
#indicator <- can chose from three options: rainfall, air_temperature, or sea_surface_temperature (changes the colour scheme)

cond_form_climate <- function(df, file_name, indicator){

  #open the core libraries of this function
  library(openxlsx2)

  #make lowercase and clean up the indicator variable
  indicator <- str_to_lower(str_replace_all(indicator, "-| ", "_"))
  
  #create an empty workbook
  wb <- wb_workbook()
  
  #add the data to the workbook
  wb$add_worksheet("Data")
  wb$add_data("Data", df)
  
  #for each of the indicators assign different colours
  if (indicator == "rainfall"){#if the indicator is rainfall, use a range of blues and browns
    
    #create the cell style we want
    lowest <- create_dxfs_style(font_color = wb_colour("#8C510A"), bgFill = wb_colour("#8C510A"))
    very_much_below <- create_dxfs_style(font_color = wb_colour("#D8B365"), bgFill = wb_colour("#D8B365"))
    below <- create_dxfs_style(font_color = wb_colour("#F6E8C3"), bgFill = wb_colour("#F6E8C3"))
    average <- create_dxfs_style(font_color = wb_colour("#F5F5F5"), bgFill = wb_colour("#F5F5F5"))
    above <- create_dxfs_style(font_color = wb_colour("#C7EAE5"), bgFill = wb_colour("#C7EAE5"))
    very_much_above <- create_dxfs_style(font_color = wb_colour("#5AB4AC"), bgFill = wb_colour("#5AB4AC"))
    highest <- create_dxfs_style(font_color = wb_colour("#01665E"), bgFill = wb_colour("#01665E"))
    
  } else if (indicator == "air_temperature" | indicator == "sea_surface_temperature"){#if temp, use a range of reds and blues
    
    #create the cell style we want
    lowest <- create_dxfs_style(font_color = wb_colour("#2166AC"), bgFill = wb_colour("#2166AC"))
    very_much_below <- create_dxfs_style(font_color = wb_colour("#67A9CF"), bgFill = wb_colour("#67A9CF"))
    below <- create_dxfs_style(font_color = wb_colour("#D1E5F0"), bgFill = wb_colour("#D1E5F0"))
    average <- create_dxfs_style(font_color = wb_colour("#F7F7F7"), bgFill = wb_colour("#F7F7F7"))
    above <- create_dxfs_style(font_color = wb_colour("#FDDBC7"), bgFill = wb_colour("#FDDBC7"))
    very_much_above <- create_dxfs_style(font_color = wb_colour("#EF8A62"), bgFill = wb_colour("#EF8A62"))
    highest <- create_dxfs_style(font_color = wb_colour("#B2182B"), bgFill = wb_colour("#B2182B"))
    
  } else {print("indicator must equal either 'rainfall', 'air_temperature', or 'sea_surface_temperature'")}
  
  #put the styles into the styles manager of the workbook
  wb$styles_mgr$add(lowest, "lowest")
  wb$styles_mgr$add(very_much_below, "very_much_below")
  wb$styles_mgr$add(below, "below")
  wb$styles_mgr$add(average, "average")
  wb$styles_mgr$add(above, "above")
  wb$styles_mgr$add(very_much_above, "very_much_above")
  wb$styles_mgr$add(highest, "highest")
    
  #add each of the rules
  wb$add_conditional_formatting("Data",
                                cols = 1:ncol(df), rows = 1:nrow(df)+1,
                                type = "containsText", rule = "1", style = "lowest")
  wb$add_conditional_formatting("Data",
                                cols = 1:ncol(df), rows = 1:nrow(df)+1,
                                type = "containsText", rule = "2", style = "very_much_below")
  wb$add_conditional_formatting("Data",
                                cols = 1:ncol(df), rows = 1:nrow(df)+1,
                                type = "containsText", rule = "3", style = "below")
  wb$add_conditional_formatting("Data",
                                cols = 1:ncol(df), rows = 1:nrow(df)+1,
                                type = "containsText", rule = "4", style = "average")
  wb$add_conditional_formatting("Data",
                                cols = 1:ncol(df), rows = 1:nrow(df)+1,
                                type = "containsText", rule = "5", style = "above")
  wb$add_conditional_formatting("Data",
                                cols = 1:ncol(df), rows = 1:nrow(df)+1,
                                type = "containsText", rule = "6", style = "very_much_above")
  wb$add_conditional_formatting("Data",
                                cols = 1:ncol(df), rows = 1:nrow(df)+1,
                                type = "containsText", rule = "7", style = "highest")
    
  #save the workbook
  wb_save(wb, path = paste0(file_name, ".xlsx"), overwrite = T)

}

