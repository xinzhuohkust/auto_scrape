library(tidyverse)
library(rvest)
library(rio)

page <- "https://xfb.sh.gov.cn/xinfang/yjzj/feedback/feedbacklist?testpara=0&pageNo=1&pagesize=1000" %>% 
    read_html() 

links <- page %>% 
    html_nodes("td>a") %>% 
    html_attr("href") %>% 
    sprintf("https://xfb.sh.gov.cn/xinfang/yjzj/feedback/%s", .)

table <- page %>% 
    html_table(header = TRUE) %>% 
    pluck(1) %>% 
    add_column(links = links)

export(
  table, 
  file = sprintf("data/%s_table.csv", Sys.Date()),
  bom = TRUE
) 


   
