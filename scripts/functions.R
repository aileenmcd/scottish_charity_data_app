

# Function 1 - Data prep for wordcloud  -----------------------------------

prep_for_wordcloud <- function(data, text_column) {

  #remove common words which don't add much to the insights
  words_to_remove <- tibble(word = c("promoting","objects","aim","advancement","purpose", "promote", "provide", "purposes", "provision", "advance"))
 
  #force early evaluation via tidy eval framework
  #use the bang-bang operator !! to force a single object
  variable <- sym(text_column)
  
  data %>%
  select(!!variable) %>%
  unnest_tokens(word, !!variable) %>%
  group_by(word) %>%
  summarise(count = n()) %>%
  arrange(desc(count)) %>%
  anti_join(stop_words, by = "word") %>% #remove inbuilt common stop words list
  anti_join(words_to_remove, by = "word") %>% #remove user built list of words
  filter(!str_detect(word, "[0-9]+")) #remove any which has a number in the string

  }


# Function 2 - Group by and count process ---------------------------------

aggregate_count_function <- function(data, var) {
  
  data %>%
    distinct_at(vars(charity_number, {{var}} )) %>%
    group_by( {{var}} ) %>%
    summarise(count = n())
  
}

