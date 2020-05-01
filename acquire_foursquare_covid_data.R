acquire_foursquare_covid_data <- function(aggregate = 'state',
                                          type = 'grouped',
                                          state_name = NA) {

  if (aggregate != 'state')

    stop(message('Due to the change in the data structure, County level data cannot be pulled with this function at this time'))

  fsqr_state_names <- c("Alabama", "Alaska", "Arizona",
                        "Arkansas", "California", "Colorado", "Connecticut", "Delaware",
                        "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana",
                        "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland",
                        "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri",
                        "Montana", "Nebraska", "Nevada", "NewHampshire", "NewJersey",
                        "NewMexico", "NewYork", "NoState", "NorthCarolina", "NorthDakota",
                        "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "RhodeIsland",
                        "SouthCarolina", "SouthDakota", "Tennessee", "Texas", "Utah",
                        "Vermont", "Virginia", "Washington", "WashingtonDC", "WestVirginia",
                        "Wisconsin", "Wyoming")

  grouped_fsqr <- function(state) {

    message('Now pulling grouped Foursquare data for ', state, '...')

    payload <- vroom::vroom(paste0('https://visitdata.org/data/grouped', state, '.csv'))

    names(payload) <- c('date', 'state', 'county', 'categoryid',
                        'categoryname', 'demo', 'visits', 'avgDuration',
                        'p50Duration')

    return(payload)
  }

  safe_grouped_fsqr <- purrr::safely(grouped_fsqr)

  raw_fsqr <- function(state) {

    message('Now pulling raw Foursquare data for ', state, '...')

    payload <- vroom::vroom(paste0('https://visitdata.org/data/raw', state, '.csv'))

    names(payload) <- c('date', 'state', 'county', 'categoryid',
                        'categoryname', 'demo', 'visits', 'avgDuration',
                        'p50Duration')

    return(payload)
  }

  safe_raw_fsqr <- purrr::safely(raw_fsqr)

  if (aggregate != 'state' & is.na(state_name))

    stop(message('You must supply a value for state_name when pulling county-level data'))

  if (aggregate == 'state' & type == 'grouped' & is.na(state_name)) {

    payload <- purrr::map(.x = fsqr_state_names,
                          ~safe_grouped_fsqr(.x))

    payload <- payload %>%
      map('result') %>%
      bind_rows()

  } else if (aggregate == 'state' & type == 'raw' & is.na(state_name)) {

    payload <- purrr::map(.x = fsqr_state_names,
                          ~safe_raw_fsqr(.x))

    payload <- payload %>%
      map('result') %>%
      bind_rows()

  } else if (aggregate != 'state' & type == 'grouped') {

    state_name <- stringr::str_to_title(state_name)
    state_name <- gsub("[[:space:]]", "", state_name)

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
