#inputs: 
#df <- any tbl or data.frame
#file name <- whatever you want the output file to be named
#cols <- the index number of each column that the function should be applied to

cond_form_fish_pres_abs <- function(df, file_name, cols){
  
  #----- Data frame preparation
  
  library(openxlsx2)

  #coerce cols to numeric - cols may not be numeric if they contain "weird" Nan, NA, or ND values
  df[cols] <- lapply(df[cols], function(x){suppressWarnings(as.numeric(x))})

  #----- Excel workbook preparation
  
  #create an empty workbook
  wb <- wb_workbook()
  
  #add the data to the workbook
  wb$add_worksheet("Data")
  wb$add_data("Data", df)

  #create the cell style we want
  pres <- create_dxfs_style(font_color = wb_colour("#000000"), bgFill = wb_colour("#00B0F0")) #blue
  abs <- create_dxfs_style(font_color = wb_colour("#000000"), bgFill = wb_colour("#D9D9D9")) #grey

  #put the style into the styles manager of the workbook
  wb$styles_mgr$add(pres, "blue")
  wb$styles_mgr$add(abs, "grey")

  #create formatting function for pres/absence (1 or 0)
  cond_format <- function(df_in, output) {
    wb$add_conditional_formatting("Data",
                                  cols = cols, rows = 1:nrow(df_in)+1,
                                  type = "containsText", rule = "1", style = "blue")
    wb$add_conditional_formatting("Data",
                                  cols = cols, rows = 1:nrow(df_in)+1,
                                  type = "containsText", rule = "0", style = "grey")

    #save the workbook
    wb_save(wb, file = paste0(file_name,".xlsx"), overwrite = T)
        
  }
  
  #run formatting on df
  cond_format(df_in = df, output = file_name)

}

  

