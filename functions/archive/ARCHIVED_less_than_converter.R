#inputs: 
#dtf <- any tbl or data.frame
#column <- the column to inspect for < symbols

#start function
less_than_converter <- function(dtf, column){
  
  dtf <- dtf |> mutate(convert = str_detect(dtf[[column]], "<"), #create a new T/F column to answer: is there is a < symbol present in the targeted column?
                       new = str_replace(dtf[[column]], "<", ""), #create a duplicate of the target column with no < symbols
                       digit = str_detect(dtf[[column]], "\\d(?=\\-)|^\\D")) #create a second T/F column to answer: does col starts with letter? 
  #or contain a digit followed by"-" (i.e is the target column numeric)
  
  #if all rows start with a letter or have a digit followed by a "-" (i.e. a date) then simply remove the columns added earlier
  #note that this ignores NA values, so a missing date wont make the column get accidentally converted
  if(all(dtf$digit, na.rm = T) == T){dtf <- dtf |> select(-c(convert, new, digit))}
  
  #otherwise the column satisfies the numeric criteria and should have any < rows converted
  else {
    
    dtf <- dtf |> mutate(across(new, as.numeric), #make the duplicate of the target column numeric
                         new = case_when(convert == T ~ new/2, T ~ new)) |> #half the duplicate column when < is T
      relocate(new, .after = {{column}}) |> #move duplicate column next to original target column
      select(-c({{column}}, convert, digit)) |> #delete original target column and the "is it a digit?" col
      rename({{column}} := new) #give duplicate column the original target column's name
  }
}