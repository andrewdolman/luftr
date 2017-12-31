# Load packages
library(tidyverse)
library(lubridate)

# Get luftdaten by sensor ID
GetLuftdata <- function(id, date){
  urls <- paste0("http://archive.luftdaten.info/", date, "//", date, "_", id, ".csv")
  pth <- paste0("data-raw/sensors/")
  fl.nms <- paste0(pth, id, date, ".csv")

  if (dir.exists(pth)==FALSE){
    dir.create(pth)
  }
  if(exists(fl.nms) == FALSE) try(download.file(urls, fl.nms))
}

earliest.date <- as.Date("2017-01-01")
latest.date <- lubridate::today()-1
# reverse order to try until failure at earliest date -1
dates <- rev(seq(earliest.date, latest.date, by='days'))

plyr::l_ply(dates, function(x) GetLuftdata(id = "sds011_sensor_2057", date = x))



# read in all files in folder

fls <- list.files("data-raw/sensors", full.names = TRUE)

dat <-  plyr::ldply(fls, function(x) read_delim(x, delim = ";")) %>%
  tbl_df()

multi.data <- dat %>%
  mutate(Time = as.POSIXct(timestamp),
         Date = as.Date(Time, ts = "Europe/Berlin")) %>%
  group_by(Time, Date) %>%
  select_if(is.numeric) %>%
  ungroup() %>%
  mutate(PM_10 = P1,
         PM_2.5 = P2)

devtools::use_data(multi.data, overwrite = TRUE)

multi.data %>%
  ggplot(aes(x = Time, y = log(PM_10), colour = as.factor(sensor_id))) +
  geom_line()

library(padr)

multi.data.hourly <- multi.data %>%
  thicken(interval = "hour", by = "Time") %>%
  group_by(Date, sensor_id, location, lat, lon, Time_hour) %>%
  summarise_if(is.numeric, mean, na.rm = T) %>%
  ungroup()

multi.data.daily <- multi.data %>%
  thicken(interval = "day", by = "Time") %>%
  group_by(Date, sensor_id, location, lat, lon, Time_day) %>%
  summarise_if(is.numeric, mean, na.rm = T) %>%
  ungroup()


multi.data.daily %>%
  ggplot(aes(x = Time_day, y = (PM_10), colour = as.factor(sensor_id))) +
  geom_line() +
  facet_grid(sensor_id~.)


multi.data.daily.wide <- multi.data.daily %>%
  select(Time_day, Date, sensor_id, PM_10) %>%
  spread(key = sensor_id, value=PM_10)

multi.data.hourly.wide <- multi.data.hourly %>%
  select(Time_hour, Date, sensor_id, PM_10) %>%
  spread(key = sensor_id, value=PM_10)


multi.data.hourly.wide %>%
# filter(Date > "2017-06-01") %>%
  ggplot(aes(x = `1444`, y = `2057`)) +
  geom_point(alpha = 0.15) +
  geom_abline(intercept = 0, slope = 1)




