acquire_foursquare_covid_data <- function(aggregate = 'state',
                                          type = 'grouped',
                                          state_name = NA,
                                          index = FALSE) {

  if (aggregate == 'state' && !is.na(state_name))

    stop(message('Do not supply a state name if aggregate is state level'))

  if (index == TRUE)

    message('Data will be indexed based on the average traffic for the given day of the week across February. \nOnly data for all demographics will be returned.')

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

  scale_fs_data <- function(payload) {

    if(aggregate != 'state') {

      anchor <- payload %>%
        filter(demo == "All") %>%
        mutate(day_number = lubridate::wday(date)) %>%
        filter(date <= '2020-02-29') %>%
        group_by(state, county, categoryid, categoryname, day_number) %>%
        summarise(avg_traffic = mean(visits)) %>%
        ungroup()

      payload_indexed <- payload %>%
        filter(demo == "All") %>%
        mutate(day_number = lubridate::wday(date)) %>%
        left_join(anchor, by = c('state', 'day_number', 'county', 'categoryid', 'categoryname')) %>%
        mutate(index_visits = round(100 * (visits/avg_traffic))) %>%
        group_by(state, county, categoryid, categoryname) %>%
        mutate(visits_7_day_roll_ave = zoo::rollapply(index_visits, 7, mean, align = 'right', fill = NA)) %>%
        ungroup()

    } else {

      anchor <- payload %>%
        filter(demo == "All") %>%
        mutate(day_number = lubridate::wday(date)) %>%
        filter(date <= '2020-02-29') %>%
        group_by(state, categoryname, day_number) %>%
        summarise(avg_traffic = mean(visits)) %>%
        ungroup()

      payload_indexed <- payload %>%
        filter(demo == "All") %>%
        mutate(day_number = lubridate::wday(date)) %>%
        left_join(anchor, by = c('state', 'day_number', 'categoryname')) %>%
        mutate(index_visits = round(100 * (visits/avg_traffic))) %>%
        group_by(state, categoryname) %>%
        mutate(visits_7_day_roll_ave = zoo::rollapply(index_visits, 7, mean, align = 'right', fill = NA)) %>%
        ungroup()

    }

    return(payload_indexed)
  }

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

    if (index == TRUE) {

      message('Indexing data...')

      payload <- scale_fs_data(payload)

    }

  } else if (aggregate == 'state' & type == 'raw' & is.na(state_name)) {

    payload <- purrr::map(.x = fsqr_state_names,
                          ~safe_raw_fsqr(.x))

    payload <- payload %>%
      map('result') %>%
      bind_rows()

    if (index == TRUE) {

      message('Indexing data...')

      payload <- scale_fs_data(payload)

    }

  } else {

    generate_county_urls <- function(state_name = NA) {

      url <- 'https://visitdata.org/data'

      payload <- read_html(url)

      urls <- payload %>%
        html_nodes('a') %>%
        html_attr('href') %>%
        as.data.frame() %>%
        rename(url_slug = '.') %>%
        mutate(full_url = paste0('https://visitdata.org', url_slug)) %>%
        .[-c(1:2),]

      text <- payload %>%
        html_nodes('a') %>%
        html_attr('href') %>%
        as.data.frame() %>%
        rename(code_text = '.') %>%
        mutate(code_text = as.character(code_text)) %>%
        .[-c(1,2), 1]

      state <- payload %>%
        html_nodes('a') %>%
        html_attr('href') %>%
        as.data.frame() %>%
        rename(state_text = '.') %>%
        mutate(state_text = as.character(state_text)) %>%
        mutate(state_text = gsub("/data/|.csv", '', state_text)) %>%
        mutate(state_text = gsub('_(.*)', '', state_text)) %>%
        .[-c(1,2),]

      if(!is.na(state_name)) {

        if(grepl(" ", state_name)) {

          state_name <- stringr::str_to_title(state_name)
          state_name <- gsub("[[:space:]]", "", state_name)

        }

        url_payload <- tibble(url = urls$full_url,
                              text = text,
                              state = state) %>%
          filter(grepl('County', text)) %>%
          filter(state_name == state)

      } else {

        url_payload <- tibble(url = urls$full_url,
                              text = text,
                              state = state) %>%
          filter(grepl('County', text))
      }

      return(url_payload)

    }

    if(!is.na(state_name)) {

      urls <- generate_county_urls(state_name)

    } else {

      urls <- generate_county_urls()
    }

    map_county_files <- map2_df(.x = urls$url,
                                .y = urls$text,
                                ~{message('Acquiring data for ', gsub("/data/|.csv", '', .y))
                                  vroom::vroom(.x, delim = ',')})


    names(map_county_files) <- c('date', 'state', 'county', 'categoryid',
                                 'categoryname', 'demo', 'visits', 'avgDuration',
                                 'p50Duration')

    payload <- map_county_files

    payload <- scale_fs_data(payload)

  }

  if (aggregate == 'state' & !is.na(state_name)) {

    payload <- payload %>%
      dplyr::filter(state == state_name)

  }

  return(payload)
}
