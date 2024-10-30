#inputs: 
#df <- any tbl or data.frame, although this works best with summary tables
#header_rows <- how many rows of headers are in the table?
#landscape <- is the target page landscape? Not that making the page landscape occurs separately

cond_form_tables <- function(df, header_rows = 1, landscape = F, score_colour = F, rain_colour = F,
                             temperature_colour = F, sst_colour = F){
  
  #convert input dataframe to a huxtable type
  df <- as_hux(df)
  
  #style the hux table into our desired look
  df <- df |> 
    set_bold(row = 1:header_rows, col = everywhere) |> #make header(s) bold
    set_top_border(row = 1, col = everywhere) |> #add border to top of row one
    set_bottom_border(row = header_rows, col = everywhere) |> #add border to bottom of header(s) row
    set_bottom_border(row = nrow(df), col = everywhere) |> #add border to very bottom of table
    set_width(if(landscape){1.63}else{1}) |> #set width depending on page orientation
    set_font_size(row = everywhere, col = everywhere, value = 9)#set the font size
  
  if (score_colour) {
    
    df <- df |> 
      map_background_color(by_ranges(breaks = c(-0.01, 21, 41, 61, 81, 100.1),
                                     values = c("#FF0000", "#FFC000",  "#FFFF00", "#92D050", "#00B050"),
                                     extend = F)) #map the background colours if desired
  } else if (rain_colour) {

    df <- df |> 
      map_background_color(by_values("1" = "#8C510A", "2" = "#D8B365", "3" = "#F6E8C3", "4" = "#F5F5F5", 
                                     "5" = "#C7EAE5", "6" = "#5AB4AC", "7" = "#01665E")) |>  #map the background colours if desired
      map_text_color(by_values("1" = "#8C510A", "2" = "#D8B365", "3" = "#F6E8C3", "4" = "#F5F5F5", 
                               "5" = "#C7EAE5", "6" = "#5AB4AC", "7" = "#01665E"))
    
    } else if (temperature_colour | sst_colour) {
    
      df <- df |> 
        map_background_color(by_values("1" = "#2166AC", "2" = "#67A9CF", "3" = "#D1E5F0", "4" = "#F7F7F7", 
                                       "5" = "#FDDBC7", "6" = "#EF8A62", "7" = "#B2182B")) |>  #map the background colours if desired
        map_text_color(by_values("1" = "#2166AC", "2" = "#67A9CF", "3" = "#D1E5F0", "4" = "#F7F7F7", 
                                 "5" = "#FDDBC7", "6" = "#EF8A62", "7" = "#B2182B"))
    }
  
  return(df)
  
}
