#inputs: 
#df <- any tbl or data.frame
#file name <- whatever you want the output file to be named
#start_col <- the first column to start the formatting from
#method <- either "Numeric" or "Letter". Numeric only returns numbers, Letter will
#return numbers and the associated letter grade.

n3_conditional_formatting <- function(df, file_name, start_col, method, ignore = NA){
  
  #----- Data frame preparation
  
  library(openxlsx2)
  
  #coerce cols to numeric - ignoring any leading descriptor cols (cols may not be
  #numeric if they contain Nan, NA, or ND values)
  #df[start_col:ncol(df)] <- lapply(df[start_col:ncol(df)], function(x){as.numeric(x)})
  
  #----- Excel workbook preparation
  
  #create an empty workbook
  wb <- wb_workbook()
  
  #add the data to the workbook
  wb$add_worksheet("Data")
  wb$add_data("Data", df)
  
  #create the cell style we want
  dark_green <- create_dxfs_style(font_color = wb_colour("#000000"), 
                                  bgFill = wb_colour("#00B050"))
  light_green <- create_dxfs_style(font_color = wb_colour("#000000"), 
                                   bgFill = wb_colour("#92D050"))
  yellow <- create_dxfs_style(font_color = wb_colour("#000000"), 
                              bgFill = wb_colour("#FFFF00"))
  orange <- create_dxfs_style(font_color = wb_colour("#000000"), 
                              bgFill = wb_colour("#FFC000"))
  red <- create_dxfs_style(font_color = wb_colour("#000000"), 
                           bgFill = wb_colour("#FF0000"))
  grey <- create_dxfs_style(font_color = wb_colour("#000000"), 
                            bgFill = wb_colour("#D9D9D9"))
  neutral <- create_dxfs_style(font_color = wb_colour("#000000"),
                               bgFill = wb_colour("#FFFFFF"))
  
  #put the style into the styles manager of the workbook
  wb$styles_mgr$add(dark_green, "dark_green")
  wb$styles_mgr$add(light_green, "light_green")
  wb$styles_mgr$add(yellow, "yellow")
  wb$styles_mgr$add(orange, "orange")
  wb$styles_mgr$add(red, "red")
  wb$styles_mgr$add(grey, "grey")
  wb$styles_mgr$add(neutral, "neutral")
  
  #----- Detect the type of number range
  
  #detect if range is 0-100 or -1 to 1
  range <- any(df[start_col:ncol(df)] < 0 & all((df[start_col:ncol(df)] <= 1), na.rm = T), na.rm = T)
  
  #---- Option 1: Number range is 0-100
  
  if (range == F){
    
    #----- Method 1.1: return only original cell values with coloured backgrounds
    
    if (method == "Numeric"){
        
        #create formatting function for numeric values from 0-100 (i.e. (+)pos values)
        cond_format_pos <- function(df_in, output) {
          
          wb$add_conditional_formatting("Data",
                                        cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
                                        type = "between", rule = c(81, 100), style = "dark_green")
          wb$add_conditional_formatting("Data",
                                        cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
                                        type = "between", rule = c(61, 80), style = "light_green")
          wb$add_conditional_formatting("Data",
                                        cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
                                        type = "between", rule = c(41, 60), style = "yellow")
          wb$add_conditional_formatting("Data",
                                        cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
                                        type = "between", rule = c(21, 40), style = "orange")
          wb$add_conditional_formatting("Data",
                                        cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
                                        type = "between", rule = c(0, 20), style = "red")
          wb$add_conditional_formatting("Data",
                                        cols = 1:ncol(df_in), rows = 1:nrow(df_in),
                                        rule = "ISNA(A1)", style = "grey")
          wb$add_conditional_formatting("Data",
                                        cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
                                        type = "contains", rule = ".", style = "neutral")

          #save the workbook
          wb_save(wb, path = paste0(output,".xlsx"), overwrite = T)
          
        }
        
        #run formatting on df
        cond_format_pos(df_in = df, output = file_name)
      
  #----- End Method 1.1
      
  #----- Method 1.2: return original cell value and associated letter grade with coloured background
      
    } else if (method == "Letter"){ 
      
      #create function that determines letter and binds it to the value
      letters_on_grade <-  function(df_in, col) {
        
        #get the column name based on the column index
        col_name <- colnames(df_in[col])
      
        df_in %>% mutate("{col_name}_grade" := case_when(col_name %in% ignore ~ "",
                                                         df_in[col] < 21 ~ "(E)",
                                                         df_in[col] >= 21 & df_in[col] < 41 ~ "(D)",
                                                         df_in[col] >= 41 & df_in[col] < 61 ~ "(C)",
                                                         df_in[col] >= 61 & df_in[col] < 81 ~ "(B)",
                                                         df_in[col] >= 81 & df_in[col] < 101 ~ "(A)",
                                                         TRUE ~ ""))
        
      }
      
      #specify number of loops for the letter function to run
      n <- start_col:ncol(df)
      
      #create a counter that starts at the first col designated by the user input
      x <- start_col
      
      #determine the index of the first new column that will be created by the loop
      y <- ncol(df) + 1
      
      #run the letter function n times, joining the outputted letter col back to the inputted score col each loop
      for (i in 1:length(n)){
        
        #create new df for first loop
        if (i == 1){df2 <- df}
        
        #run the letter function starting on column x until column n
        df2 <- letters_on_grade(df2, x)
        
        #coerce inputted score col, and outputted letter col to character
        df2[x,y] <- lapply(df2[x,y], function(x){as.character(x)})
        
        #rename the inputted score col because the function creates duplicate names
        col_name <- as.character(colnames(df2[x]))
        
        #combine the inputted score col and the outputted letter col with the updated col name
        df2 <- df2 %>% unite({{col_name}},  x,y, sep = " ", remove = T)
       
        #increase the column counter so that the next col is inputted before starting again
        x = x + 1
      }
      
      #add the new data to the workbook
      wb$add_data("Data", df2)
      
      #formatting for letter grades (for both positive and negative number ranges)
      cond_format_let <- function(df_in, output) {
        
        #apply the conditional formatting rules to the data
        wb$add_conditional_formatting("Data",
                                      cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
                                      type = "contains", rule = "(A)", style = "dark_green")
        wb$add_conditional_formatting("Data",
                                      cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
                                      type = "contains", rule = "(B)", style = "light_green")
        wb$add_conditional_formatting("Data",
                                      cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
                                      type = "contains", rule = "(C)", style = "yellow")
        wb$add_conditional_formatting("Data",
                                      cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
                                      type = "contains", rule = "(D)", style = "orange")
        wb$add_conditional_formatting("Data",
                                      cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
                                      type = "contains", rule = "(E)", style = "red")
        wb$add_conditional_formatting("Data",
                                      cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
                                      type = "contains", rule = "NA", style = "grey")
        wb$add_conditional_formatting("Data",
                                      cols = 1:ncol(df_in), rows = 1:nrow(df_in),
                                      rule = "ISNA(A1)", style = "grey")
        wb$add_conditional_formatting("Data",
                                      cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
                                      type = "contains", rule = ".", style = "neutral")
        
        
        #save the workbook
        wb_save(wb, path = paste0(output,".xlsx"), overwrite = T)
      }
      
      #run letter conditional formatting function on the data
      cond_format_let(df_in = df2, output = file_name)
      
    } #----- End Method 1.2
    
  #----- End Option 1: Numeric range is 0-100
    
  #----- Start Option 2: Numeric range is -1 to +1
    
  } else {
    
    #----- Method 2.1: return only original cell values with coloured backgrounds
    
    if (method == "Numeric"){ 
      
      #create formatting function for numeric values from -1 to +1 (i.e. (+-)pos_neg values)
      cond_format_pos_neg <- function(df_in, output) {
        
        #apply the conditional formatting rules to the data
        wb$add_conditional_formatting("Data",
          cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
          type = "between", rule = c(0.51, 1), style = "dark_green")
        wb$add_conditional_formatting("Data",
          cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
          type = "between", rule = c(0, 0.5), style = "light_green")
        wb$add_conditional_formatting("Data",
          cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
          type = "between", rule = c(-0.33, -0.01), style = "yellow")
        wb$add_conditional_formatting("Data",
          cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
          type = "between", rule = c(-0.66, -0.34), style = "orange")
        wb$add_conditional_formatting("Data",
          cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
          type = "between", rule = c(-1, -0.67), style = "red")
        
        #save the workbook
        wb_save(wb, path = paste0(output,".xlsx"), overwrite = T)
      }
      
      #run formatting on df
      cond_format_pos_neg(df_in = df, output = file_name)
      
  #----- End Method 2.1
      
  #----- Method 2.2: return original cell value and associated letter grade with coloured background
      
    } else if (method == "Letter"){  
      
      #create function that determines letter and binds it to the value
      letters_on_grade <-  function(df_in, col) {
        
        #get the column name based on the column index
        col_name <- colnames(df_in[col])
        
        #mutate df using conditional rules
        df_in %>% mutate("{col_name}_grade" := case_when(df_in[col] < -0.66 ~ "(E)",
                                                         df_in[col] >= -0.66 & df_in[col] < -0.33 ~ "(D)",
                                                         df_in[col] >= -0.33 & df_in[col] < 0 ~ "(C)",
                                                         df_in[col] >= 0 & df_in[col] < 0.51 ~ "(B)",
                                                         df_in[col] >= 0.51 ~ "(A)",
                                                         TRUE ~ ""))
      }
      
      
      #specify number of loops for the letter function to run
      n <- start_col:ncol(df)
      
      #create a counter that starts at the first col designated by the user input
      x <- start_col
      
      #determine the index of the first new column that will be created by the loop
      y <- ncol(df) + 1
      
      #run the letter function n times, joining the outputted letter col back to the inputted score col each loop
      for (i in 1:length(n)){
        
        #create new df for first loop
        if (i == 1){df2 <- df}
        
        #run the letter function starting on column x until column n
        df2 <- letters_on_grade(df2, x)
        
        #coerce inputted score col, and outputted letter col to character
        df2[x,y] <- lapply(df2[x,y], function(x){as.character(x)})
        
        #rename the inputted score col because the function creates duplicate names
        col_name <- as.character(colnames(df2[x]))
        
        #combine the inputted score col and the outputted letter col with the updated col name
        df2 <- df2 %>% unite({{col_name}},  x,y, sep = " ", remove = T)
        
        #increase the column counter so that the next col is inputted before starting again
        x = x + 1
      }
      
      #add the new data to the workbook
      wb$add_data("Data", df2)
      
      #formatting for letter grades (for both positive and negative number ranges)
      cond_format_let <- function(df_in, output) {
        
        #apply the conditional formatting rules to the data
        wb$add_conditional_formatting("Data",
                                      cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
                                      type = "contains", rule = "(A)", style = "dark_green")
        wb$add_conditional_formatting("Data",
                                      cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
                                      type = "contains", rule = "(B)", style = "light_green")
        wb$add_conditional_formatting("Data",
                                      cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
                                      type = "contains", rule = "(C)", style = "yellow")
        wb$add_conditional_formatting("Data",
                                      cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
                                      type = "contains", rule = "(D)", style = "orange")
        wb$add_conditional_formatting("Data",
                                      cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
                                      type = "contains", rule = "(E)", style = "red")
        wb$add_conditional_formatting("Data",
                                      cols = 1:ncol(df_in), rows = 1:nrow(df_in)+1,
                                      type = "contains", rule = "NA", style = "grey")
        
        #save the workbook
        wb_save(wb, path = paste0(output,".xlsx"), overwrite = T)
      }
      
      #run letter conditional formatting function on the data
      cond_format_let(df_in = df2, output = file_name)
      
    } #----- End Method 1.2
  
  #----- End Option 2: Numeric range is -1 to +1
  
  }
  
}
