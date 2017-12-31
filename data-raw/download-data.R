# Obtain data from https://www.madavi.de/sensor/csvfiles.php?sensor=esp8266-1190180 - my sensor
library(tidyverse)
library(lubridate)
library(XML)

## Download monthly zip files

url <- "https://www.madavi.de/sensor/data/2017/data-esp8266-1190180-"
dts <- c(paste0("2017-0", 4:9), paste0("2017-", 10:11))

urls <- paste0(url, dts, ".zip")
fl.nms <- paste0("data-raw/zip/esp8266-1190180", dts, ".zip")
#fl.nms <- paste0("data-raw/raw-files/esp8266-11901802017-05-13.csv")
if (dir.exists("data-raw/zip")==FALSE){
  dir.create("data-raw/zip")
}

# download
plyr::l_ply(seq_along(urls), function(x) download.file(urls[x], fl.nms[x]))

# unzip
plyr::l_ply(fl.nms, function(x) unzip(x, exdir = "data-raw/raw-files"))

# read files

fl.nms <- list.files("data-raw/raw-files", include.dirs = FALSE)

dat <-  plyr::ldply(fl.nms, function(x)
  read_delim(x, delim = ";", col_types = paste0("c",
                                                paste0(rep("n", 15), collapse = ""),
                                                paste0(rep("i", 4), collapse = ""),
                                                collapse = ""))) %>%
  tbl_df()

home.data.mothly.zip <- dat %>%
  mutate(Time = as.POSIXct(Time),
         Date = as.Date(Time, ts = "Europe/Berlin")) %>%
  group_by(Time, Date) %>%
  select_if(is.numeric) %>%
  ungroup()

home.data <- bind_rows(luftr::home.data, home.data.new) %>%
  distinct(.) %>%
  mutate(Date = as.Date(Time, ts = "Europe/Berlin"),
         PM_10 = SDS_P1,
         PM_2.5 = SDS_P2)



## Get only new data


# Get latest date of existing data

latest.date <- as.Date(max(luftr::home.data$Date))


# fl.nms <-
#   list.files("https://www.madavi.de/sensor/csvfiles.php?sensor=esp8266-1190180")

# url <- "https://www.madavi.de/sensor/csvfiles.php?sensor=esp8266-1190180/"
# doc <- XML::htmlParse(url)
# links <- XML::xpathSApply(doc, "//a/@href")

url <- "https://www.madavi.de/sensor/data/data-esp8266-1190180-"
dts <- seq(latest.date+1, lubridate::today(), by='days')

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
         Date = as.Date(Time, ts = "Europe/Berlin")) %>%
  group_by(Time, Date) %>%
  select_if(is.numeric) %>%
  ungroup()

## append new data

home.data <- bind_rows(home.data.mothly.zip, home.data.new) %>%
  distinct(.) %>%
  mutate(Date = as.Date(Time, ts = "Europe/Berlin"),
         PM_10 = SDS_P1,
         PM_2.5 = SDS_P2,
         Temp = ifelse(is.na(Temp), BMP_temperature, Temp))

home.data.long <- home.data %>%
  select(-SDS_P1, -SDS_P2) %>%
  gather(Variable, Value, -Time, -Date) %>%
  filter(complete.cases(Value))


devtools::use_data(home.data, home.data.long, overwrite = TRUE)

