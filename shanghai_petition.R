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

get_contents <- possibly(
    \(link) {
        contents_page <- link %>%
            read_html()

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

getwd()

done <- list.files("~/data", pattern = "csv", full.names = TRUE) %>% 
    import(setclass = "tibble")

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
    print("There is no data!")
}

