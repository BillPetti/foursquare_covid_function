# foursquare_covid_function

Function for pulling public, COVID-19 related Foursquare foot traffic data in R

You can import the function into your environment by running:

`source('https://raw.githubusercontent.com/BillPetti/foursquare_covid_function/master/acquire_foursquare_covid_data.R')`

You must have the following packages installed: `vroom`, `purrr`, `stringr`, `dplyr`

This is a function for downloading foot traffic data made available by Foursquare at the state and county levels that powers the dashboard at [https://visitdata.org/index.html](https://visitdata.org/index.html). The data is indexed so that 100 = average traffic for that day of the week in February 2020. They provide data that is grouped or raw--grouped takes the more detailed location categories and groups them into roughly 25 aggregate categories. The data will also return three cuts of the data based on age: `all_ages`, `over_65`, `under_65`

There are four arguments that function takes, with their defaults:

```
aggregate = 'state'
type = 'grouped'
state_name = NA
index = FALSE
```
- `aggregate`: indicates if the data should be at the state or state-county level
- `type`: indicates whether to return 
- `state_name`: if left `NA`, all states are returned. If a state is names, only data for that state will be returned. 
- `index`: whether to add an indexed version of the visit data. Foursquare previously included this, but changed to raw visits in May.

If you want all the state-level, grouped data, you would run:

```
acquire_foursquare_covid_data(aggregate = 'state', 
                              type = 'grouped') %>%
  head()
  
# A tibble: 6 x 9
  date       state   county categoryid categoryname demo    visits avgDuration p50Duration
  <date>     <chr>   <lgl>  <chr>      <chr>        <chr>    <dbl>       <dbl>       <dbl>
1 2020-02-01 Alabama NA     Group      Airport      Above65   1828         127          NA
2 2020-02-01 Alabama NA     Group      Airport      All      34994          92          NA
3 2020-02-01 Alabama NA     Group      Airport      Below65  33166          90          NA
4 2020-02-01 Alabama NA     Group      Alcohol      Above65   1586          33          NA
5 2020-02-01 Alabama NA     Group      Alcohol      All      36445          39          NA
6 2020-02-01 Alabama NA     Group      Alcohol      Below65  34859          39          NA
```
For the same type of data, but at the county level, simply change the `aggregate` arugment and note what state to pull from. The data will return the high-level, grouped categories and the raw categories:

```
acquire_foursquare_covid_data(aggregate = 'county', 
                              type = 'grouped', 
                              state_name = 'New Jersey') %>%
  head()
  
# A tibble: 6 x 9
  date       state   county    categoryid      categoryname demo  visits avgDuration p50Duration
  <date>     <chr>   <chr>     <chr>           <chr>        <chr>  <dbl>       <dbl>       <dbl>
1 2020-02-01 New Je… Atlantic… 4bf58dd8d48988… Clothing St… Abov…    405          15          NA
2 2020-02-01 New Je… Atlantic… 4bf58dd8d48988… Clothing St… All     7565          21          14
3 2020-02-01 New Je… Atlantic… 4bf58dd8d48988… Clothing St… Belo…   7160          22          NA
4 2020-02-01 New Je… Atlantic… 4bf58dd8d48988… Banks        Abov…   1809          19          NA
5 2020-02-01 New Je… Atlantic… 4bf58dd8d48988… Banks        All     9194          20           8
6 2020-02-01 New Je… Atlantic… 4bf58dd8d48988… Banks        Belo…   7386          21          NA

```
The data will include all dates from 2020-02-01 to whatever end date you choose. This allows you do create trend plots:

```
acquire_foursquare_covid_data(aggregate = 'state', 
                              type = 'grouped', 
                              index = T) %>%
    filter(categoryname == 'Grocery')
    filter(state %in% c('New Jersey', 'New York', 'Iowa', 'Washington')) %>%
    ggplot(aes(date, visits_7_day_roll_ave)) +
    geom_line(aes(color = state)) +
    labs(title = 'Grocery Store Foot Traffic for New Jersey\n', 
         x = 'Date', 
         y = 'Foot Traffic (100 = February Average)') +
    theme_classic()
```
![sample chart](https://raw.githubusercontent.com/BillPetti/foursquare_covid_function/master/ex_chart.png "")


 
