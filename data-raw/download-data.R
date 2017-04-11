# Obtain data from https://www.madavi.de/sensor/csvfiles.php?sensor=esp8266-1190180 - my sensor
library(tidyverse)
library(lubridate)
library(XML)


## Get only new data


# Get latest date of existing data

latest.date <- as.Date(max(luftr::home.data$Time))


# fl.nms <-
#   list.files("https://www.madavi.de/sensor/csvfiles.php?sensor=esp8266-1190180")

# url <- "https://www.madavi.de/sensor/csvfiles.php?sensor=esp8266-1190180/"
# doc <- XML::htmlParse(url)
# links <- XML::xpathSApply(doc, "//a/@href")

url <- "https://www.madavi.de/sensor/data/data-esp8266-1190180-"
dts <- seq(latest.date, lubridate::today(), by='days')

urls <- paste0(url, dts, ".csv")
fl.nms <- paste0("data-raw/raw-files/esp8266-1190180", dts, ".csv")

if (dir.exists("data-raw/raw-files")==FALSE){
  dir.create("data-raw/raw-files")
}

# download new files + previous latest day
plyr::l_ply(seq_along(urls), function(x) download.file(urls[x], fl.nms[x]))

# read all new files

#fls <- list.files("data-raw/raw-files/", full.names = TRUE)

dat <-  plyr::ldply(fl.nms, function(x) read_delim(x, delim = ";")) %>%
  tbl_df()

home.data.new <- dat %>%
  mutate(Time = as.POSIXct(Time),
         Date = as.Date(Time)) %>%
  group_by(Time, Date) %>%
  select_if(is.numeric) %>%
  ungroup()

home.data.long.new <- home.data.new %>%
  gather(Variable, Value, -Time, -Date) %>%
  filter(complete.cases(Value))


## append new data

home.data <- bind_rows(home.data, home.data.new) %>% 
  distinct(.)

home.data.long <- bind_rows(home.data.long, home.data.long.new) %>% 
  distinct(.)


devtools::use_data(home.data, home.data.long, overwrite = TRUE)

