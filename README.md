# foursquare_covid_function
Function for pulling public, COVID-19 related Foursquare foot traffic data in R

You can import the function into your environment by running:

`source('https://raw.githubusercontent.com/BillPetti/foursquare_covid_function/master/acuire_foursquare_covid_data')`

You must have the following packages installed: `vroom`, `stringr`, `dplyr`

This is a function for downloading foot traffic data made available by Foursquare at the state and county levels that powers the dashboard at [https://visitdata.org/index.html](https://visitdata.org/index.html). The data is indexed so that 100 = average traffic for that day of the week in February 2020. They provide data that is grouped or raw--grouped takes the more detailed location categories and groups them into roughly 25 aggregate categories. 

There are four arguments that function takes, with their defaults:

```
aggregate = 'state'
type = 'grouped'
state_name = NA
date = Sys.Date()-2
```
- `aggregate`: indicates if the data should be at the state or state-county level
- `type`: indicates whether to return 
- `state_name`: if left `NA`, all states are returned. If a state is names, only data for that state will be returned. 
- `date`: the latest date to pull. Data appears to update in the evening, so the default is for two days prior

If you want all the state-level, grouped data, you would run:

```
foursquare_covid_data(aggregate = 'state', 
                      type = 'grouped') %>%
  head()
  
# A tibble: 6 x 7
  date       state   category              all_ages under_65 over_65 cat_num
  <date>     <chr>   <chr>                    <dbl>    <dbl>   <dbl>   <dbl>
1 2020-03-01 Alabama Food                       109      104     109       1
2 2020-03-01 Alabama Shops & Services           115      102     115       2
3 2020-03-01 Alabama Gas Stations               110      109     110       3
4 2020-03-01 Alabama Big Box Stores             108      104     108       4
5 2020-03-01 Alabama Grocery                     99       92      99       5
6 2020-03-01 Alabama Fast Food Restaurants      115      115     115       6
```
For the same type of data, but at the county level, simply change the `aggregate` arugment and note what state to pull from:

```
foursquare_covid_data(aggregate = 'county', 
                      type = 'grouped', 
                      state = 'New Jersey) %>%
  head()
  
# A tibble: 6 x 8
  date       state      county       category              all_ages under_65 over_65 cat_num
  <date>     <chr>      <chr>        <chr>                    <dbl>    <dbl>   <dbl>   <dbl>
1 2020-03-01 New Jersey Union County Food                       105      102     105       1
2 2020-03-01 New Jersey Union County Shops & Services           109      104     109       2
3 2020-03-01 New Jersey Union County Airport                     92      108      92       3
4 2020-03-01 New Jersey Union County Grocery                    102      106     102       4
5 2020-03-01 New Jersey Union County Outdoors & Recreation       92      104      92       5
6 2020-03-01 New Jersey Union County Nightlife Spots             98       NA      98       6
```
The data will include all dates from 2020-03-01 to whatever end date you choose. This allows you do create trend charts:

```
foursquare_covid_data(aggregate = 'state', 
                      type = 'grouped', 
                      state = 'New Jersey') %>%
  filter(category == 'Grocery') %>%
  gather(age_group, scaled_traffic, c(all_ages:over_65)) %>% 
  ggplot(aes(date, scaled_traffic)) +
  geom_line(aes(color = age_group)) +
  labs(title = 'Grocery Store Foot Traffic for New Jersey\n', 
       x = 'Date', 
       y = 'Foot Traffic (100 = February Average)') +
  theme_classic()
```









You can grab all the state level data at once (just leave the state_num argument blank). They didn't aggregate a county level file, but you can just map over a list of state names to get it all in one shot. Make sure you have the vroom package installed and tidyverse loaded. Let me know if you have any questions:

 
