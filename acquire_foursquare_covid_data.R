acquire_foursquare_covid_data <- function(aggregate = 'state',
                                          type = 'grouped',
                                          state_name = NA,
                                          date = Sys.Date()-2) {

  date <- gsub('-', '', as.character(date))

  if (aggregate != 'state' & is.na(state_name))

    stop(message('You must supply a value for state_name when pulling county-level data'))

  if (aggregate == 'state' & type == 'grouped') {

    #payload <- vroom::vroom(paste0('https://data.visitdata.org/processed/vendor/foursquare/asof/', date, '-v0/allstate/grouped.csv'))

    payload <- vroom::vroom(paste0('https://visitdata.org/data/allstate/grouped.csv'))

    names(payload) <- c('date', 'state', 'category', 'all_ages',
                        'under_65', 'over_65', 'cat_num')

  } else if (aggregate == 'state' & type == 'raw') {

    #payload <- vroom::vroom(paste0('https://data.visitdata.org/processed/vendor/foursquare/asof/', date, '-v0/allstate/raw.csv'))

    payload <- vroom::vroom(paste0('https://visitdata.org/data/allstate/raw.csv'))

    names(payload) <- c('date', 'state', 'cat_code', 'category', 'all_ages',
                        'under_65', 'over_65', 'cat_num')

  } else if (aggregate != 'state' & type == 'grouped') {

    state_name <- stringr::str_to_title(state_name)
    state_name <- gsub("[[:space:]]", "", state_name)

    #build_url <- paste0('https://data.visitdata.org/processed/vendor/foursquare/asof/', date, '-v0/grouped', state_name, '.csv')

    build_url <- paste0('https://visitdata.org/data/grouped', state_name, '.csv')

    payload <- vroom::vroom(build_url)

    names(payload) <- c('date', 'state', 'county', 'category', 'all_ages',
                        'under_65', 'over_65', 'cat_num')
  } else {

    state_name <- stringr::str_to_title(state_name)
    state_name <- gsub("[[:space:]]", "", state_name)

    #build_url <- paste0('https://data.visitdata.org/processed/vendor/foursquare/asof/', date, '-v0/raw', state_name, '.csv')

    build_url <- paste0('https://visitdata.org/data/raw', state_name, '.csv')

    payload <- vroom::vroom(build_url)

    names(payload) <- c('date', 'state', 'county', 'cat_code', 'category',
                        'all_ages', 'under_65', 'over_65', 'cat_num')
  }

  if (aggregate == 'state' & !is.na(state_name)) {

    payload <- payload %>%
      dplyr::filter(state == state_name)

  }

  return(payload)
}