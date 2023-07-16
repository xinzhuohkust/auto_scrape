#load libs
library(rvest)
library(readr)

#nse top gainers

url <- 'https://www.rforseo.com/sitemap.xml'

# extract html 

url_html <- read_html(url)

#table extraction

nbr_url <- url_html |>
  html_nodes("loc") |>
  length()

row <- data.frame(Sys.Date(), nbr_url)


write_csv(row,paste0('data/xml_url_count.csv'),append = T)    
