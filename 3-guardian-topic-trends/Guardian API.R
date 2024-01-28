#Guardian API
rm(list = ls())

# Libraries Required
library(dplyr)
library(httr)
library(jsonlite)
library(rjson)
library(RJSONIO)
library(tidyr)
library(keyring)

setwd("C:/Users/vyom/OneDrive/GitHub/guardian-topic-trends")

# API token key
apikey <- key_get("guardian", "key")

# Inputs for API call
# User prompt to identify what he wants to search
# fun <- function(msg = "What are you looking for?"){
#   search_key <- readline("What are you looking for?")  
#   return(search_key)}
# 
# search_key=fun()
# 
# apiurl <- paste0("https://content.guardianapis.com/search?q=",search_key,"&api-key=",apikey)
# 
# # Use the get verb to obtain api data. This request is sent to the API, and the API responds to it. This 
# # process is known as 'serialization'
# get_api_data <- GET(url = apiurl)
# 
# # When the response is received on the other end, the application 
# # that made the original request must deserialize the payload. The process below is known as 'deserialization'
# # The content function with a "text" parameter converts the raw data to JSON
# get_api_data_text <- content(get_api_data,as = "text")
# 
# # parse the JSON using the jsonlite package
# get_api_json <- jsonlite::fromJSON(txt = get_api_data_text, flatten = TRUE)
# 
# # store it in a dataframe
# api_final_df <- as.data.frame(get_api_json)

# the above api call can be done using the GuardianR package with predefined functions
#install.packages("GuardianR")
library(GuardianR)
results <- get_guardian("brexit",
                        from.date="2018-07-16",
                        to.date="2018-08-16",
                        api.key=key_get("guardian", "key"))

# forming a wordcloud of the section headings to identify what's being talked of
##Word Cloud
library("tm")  # for text mining
library("SnowballC") # for text stemming
library("wordcloud") # word-cloud generator 
library("RColorBrewer") # color palettes
library("stringr") # string manipulations
library("sqldf")

url_text <- as.data.frame(as.character(results$webTitle))
colnames(url_text)[1] <- "web_title"

url_text <- url_text %>% 
  mutate(web_title=str_split(web_title, pattern = " ")) %>% 
  unnest(web_title)

url_text$web_title <- tolower(url_text$web_title)

stop_words <- as.data.frame(stopwords("en"))

url_text <- sqldf("select * from url_text where web_title not in (select * from stop_words)")

url_text <- url_text %>% 
  group_by(web_title) %>%
  summarise(word_cnt=n()) %>% 
  arrange(desc(word_cnt))

url_text <- url_text %>% 
  filter(word_cnt>=2)

write.table(url_text$web_title,"wcld.txt", sep = "\t", row.names = FALSE)
txt<- readLines(file.choose())

k <- Corpus(VectorSource(txt))

k<-tm_map(k, content_transformer(tolower))
#k<-tm_map(k, PlainTextDocument)
k<-tm_map(k, removeNumbers)
k<-tm_map(k, stripWhitespace)
k<-tm_map(k, removePunctuation)
k<-tm_map(k, removeWords, stopwords('english'))

#k<-tm_map(k, stemDocument)
#wordcloud(k, max.words = 100, random.order = FALSE)
inspect(k)

tdm<-TermDocumentMatrix(k)
#tdm
m<- as.matrix(tdm)
v<-sort(rowSums(m), decreasing = TRUE)
d<- data.frame(word = names(v), freq = v)
head(d, 10)


set.seed(1234)
wordcloud(words = d$word, freq = d$freq, min.freq = 1,
          max.words=15, random.order=FALSE, rot.per=0, 
          colors=brewer.pal(4, "Dark2"), fixed.asp = 1)

