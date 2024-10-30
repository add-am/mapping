#inputs: 
#df <- any tbl or data.frame
#file name <- whatever you want the output file to be named
#cols <- the index number of each column that the function should be applied to. This function is 
#special in that it compares pairs of columns.

cond_form_wq_summary_stats <- function(df, file_name, cols){
  
  #----- Data frame preparation
  
  library(openxlsx2)
  
  #create a duplicate that doesn't get all columns converted to numeric
  df_original <- df

  #coerce cols to numeric - cols may not be numeric if they contain "weird" Nan, NA, or ND values
  df[cols] <- lapply(df[cols], function(x){suppressWarnings(as.numeric(x))})
  
  #figure out the target column to receive colouring (it should be the first of the two columns provided)
  target <- cols[1]
  
  #----- Excel workbook preparation
  
  #create an empty workbook
  wb <- wb_workbook()
  
  #add the data to the workbook
  wb$add_worksheet("Data")
  wb$add_data("Data", df)

  #create the cell style we want
  pass <- create_dxfs_style(font_color = wb_colour("#000000"), bgFill = wb_colour("#BDD7EE")) #blue
  fail <- create_dxfs_style(font_color = wb_colour("#000000"), bgFill = wb_colour("#F8CBAD")) #orange
  gry <- create_dxfs_style(font_color = wb_colour("#000000"), bgFill = wb_colour("#D9D9D9")) #grey

  #put the style into the styles manager of the workbook
  wb$styles_mgr$add(pass, "blue")
  wb$styles_mgr$add(fail, "orange")
  wb$styles_mgr$add(gry, "grey")
  
  #figure out the positions of the columns to compare and create a function/rule to apply
  pass_rule <- glue("{LETTERS[cols[1]]}2<={LETTERS[cols[2]]}2")
  fail_rule <- glue("{LETTERS[cols[1]]}2>{LETTERS[cols[2]]}2")

  #create formatting function that compares a column to its neighbour
  cond_format <- function(df_in, output) {
    wb$add_conditional_formatting("Data",
                                  cols = target, rows = 2:nrow(df_in),
                                  rule = fail_rule, style = "orange")
    wb$add_conditional_formatting("Data",
                                  cols = target, rows = 2:nrow(df_in),
                                  rule = pass_rule, style = "blue")
    wb$add_conditional_formatting("Data",
                                  cols = target, rows = 1:nrow(df_in),
                                  type = "containsErrors", style = "grey")
    
    #save the workbook
    wb_save(wb, file = paste0(file_name,".xlsx"), overwrite = T)
        
  }
  
  #run formatting on df
  cond_format(df_in = df, output = file_name)

}

  

