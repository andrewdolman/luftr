# Obtain data from https://www.madavi.de/sensor/csvfiles.php?sensor=esp8266-1190180 - my sensor
library(tidyverse)


fl.nms <-
  list.files("https://www.madavi.de/sensor/csvfiles.php?sensor=esp8266-1190180")

url <- "https://www.madavi.de/sensor/csvfiles.php?sensor=esp8266-1190180/"
doc <- XML::htmlParse(url)
links <- XML::xpathSApply(doc, "//a/@href")
free(doc)
links

url <- "https://www.madavi.de/sensor/data/data-esp8266-1190180-"
dts <- seq(ymd('2017-04-02'), today(), by='days')

urls <- paste0(url, dts, ".csv")
fl.nms <- paste0("data-raw/raw-files/esp8266-1190180", dts, ".csv")

plyr::l_ply(seq_along(urls), function(x) download.file(urls[x], fl.nms[x]))

fls <- list.files("data-raw/raw-files/", full.names = TRUE)

dat <-  plyr::ldply(fls, function(x) read_delim(x, delim = ";")) %>%
  tbl_df()

home.data <- dat %>%
  mutate(Time = as.POSIXct(Time)) %>%
  group_by(Time) %>%
  select_if(is.numeric) %>%
  ungroup()

home.data.long <- home.data %>%
  gather(Variable, Value, -Time) %>%
  filter(complete.cases(Value))

devtools::use_data(home.data, home.data.long, overwrite = TRUE)

