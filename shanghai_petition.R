library(tidyverse)
library(rio)
library(rvest)
library(httr2)

extract <- \(link) {
    request(link) %>%
    req_timeout(100) %>%
    req_headers(
      'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.114 Safari/537.36',
    ) %>%
    req_retry(
      max_tries = 50,
      max_seconds = 600,
      backoff = ~ 5
    ) %>%
    req_perform() %>% 
    pluck("body") %>% 
    read_html("utf-8")
}

page <- "https://xfb.sh.gov.cn/xinfang/yjzj/feedback/feedbacklist?testpara=0&pageNo=1&pagesize=1000" %>% 
  extract()

links <- page %>%
  html_nodes("td>a") %>%
  html_attr("href") %>%
  sprintf("https://xfb.sh.gov.cn/xinfang/yjzj/feedback/%s", .)

table <- page %>%
  html_table(header = TRUE) %>%
  pluck(1) %>%
  add_column(links = links)

get_contents <- possibly(
  \(link) {
    contents_page <- link %>%
      extract()
    
    标题 <- contents_page %>%
      html_node("li>h6") %>%
      html_text()
    
    contents <- contents_page %>%
      html_nodes("li>p") %>%
      html_text() %>%
      str_remove_all("\\\r\\\n")
    
    names(contents) <- c("来信日期", "信件内容", "回复日期", "回复单位", "回复内容")
    
    result <- contents %>%
      as_tibble_row() %>%
      add_column(标题, .before = 1)
    
    Sys.sleep(sample(1:2, 1))
    
    return(result)
    
  },
  otherwise = tribble(
    ~标题, ~来信日期, ~信件内容, ~回复日期, ~回复单位, ~回复内容,
    "error!", "error!", "error!", "error!", "error!", "error!"
  )
)

done <- list.files("/home/runner/work/auto_scrape/auto_scrape/data", pattern = "table", full.names = TRUE) %>% 
  map_dfr(~import(., setclass = "tibble"))

table <- table %>% 
  anti_join(done, "links")

if(nrow(table) != 0) {
  table <- table %>% 
    set_names(c("title", "agency", "date", "links")) %>% 
    mutate(data = map(links, get_contents, .progress = TRUE)) %>% 
    unnest(data)
  
  export(
    table, 
    file = sprintf("data/%s_table.csv", Sys.Date()),
    bom = TRUE
  ) 
} else {
  export(
    tibble(info = "there is no new data"),
    file = sprintf("data/%s_empty.csv", Sys.Date()),
    bom = TRUE
  ) 
}
