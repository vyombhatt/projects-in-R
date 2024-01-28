library(devtools)
#install_github("twitteR", username = "geoffjentry")
library(ROAuth)
library(twitteR)
library(plyr)
library(stringr)
library(ggplot2)
library(RColorBrewer)
library(tm)
library(wordcloud)
library(SnowballC)
library(keyring)

setwd("C:\Users\vyom\Documents\Media IQ\Documents\extra\8th sem\RCode")

#download.file(url = "http://curl.haxx.se/ca/cacert.pem", destfile = "cacert.pem")


requestURL <- "https://api.twitter.com/oauth/request_token"
accessURL <- "https://api.twitter.com/oauth/access_token"
authURL <- "https://api.twitter.com/oauth/authorize"
consumerKey = key_get("consumer_key", "a1")
consumerSecret = key_get("consumer_secret_key", "a2")
accessToken = key_get("access_token", "a3")
accessSecret = key_get("access_secret_token", "a3")

Cred<- OAuthFactory$new(consumerKey=consumerKey,
                       consumerSecret=consumerSecret,
                    requestURL=requestURL,
                   accessURL=accessURL,
                    authURL=authURL)
Cred$handshake(cainfo = system.file("CurlSSL","cacert.pem",package = "RCurl"))


save(Cred, file = "twitter authentication.Rdata")
load("twitter authentication.Rdata")
setup_twitter_oauth(consumerKey, consumerSecret, accessToken, accessSecret)

srch<- "UEFA Champions League"
myTweet<- searchTwitter(srch,n=1000, lang = "en")
myTweetdf<- twListToDF(myTweet)
write.csv(myTweetdf,file = "TweetReport.csv")

#SentimentFunction
score.sentiment = function(sentences, pos.words, neg.words, .progress='none')
{
  require(plyr)
  require(stringr)
  # we got a vector of sentences. plyr will handle a list
  # or a vector as an "l" for us
  # we want a simple array of scores back, so we use
  # "l" + "a" + "ply" = "laply":
  scores = laply(sentences, function(sentence, pos.words, neg.words){
    #remove all punctuation from the sentences
    sentence = gsub('[[:punct:]]','',sentence)
    #remove all control charatcers from  the sentences
    sentence = gsub('[[:cntrl:]]','',sentence)
    # remove retweet entities
    some_txt = gsub("(RT|via)((?:\\b\\W*@\\w+)+)", "", sentence)
    # remove @people
    some_txt = gsub("@\\w+", "", sentence)
    # remove html links
    some_txt = gsub("http\\w+", "", sentence)
    #remove digits from sentences
    sentence = gsub('\\d+','',sentence)
    #convert to lowercase
    sentence = tolower(sentence)
    #split into words
    word.list = str_split(sentence, '\\s+')
    words = unlist(word.list)
    pos.matches = match(words, pos.words)
    neg.matches = match(words, neg.words)
    #match function returns positionn of matched term
    #we require only TRUE/FALSE
    pos.matches = !is.na(pos.matches)
    neg.matches = !is.na(neg.matches)
    #sum() function will treat TRUE/FALSE as 1/0 which is what we require
    score = sum(pos.matches) - sum(neg.matches)
    return(score)
  }, pos.words, neg.words, .progress = .progress)
  scores.df = data.frame(score=scores, text=sentences)
  return(scores.df)
}

#load hu-liu's sentiment word list
hu.liu.pos = scan("positive-words.txt", what = 'character', comment.char = ';')
hu.liu.neg = scan("negative-words.txt", what = 'character', comment.char = ';')

#update the list
pos.words = c(hu.liu.pos, 'upgrade')
neg.words = c(hu.liu.neg, 'upgrade')


dstweet<- read.csv("TweetReport.csv")
dstweet$text<-as.factor(dstweet$text)

#assigning a score to every tweet
tweet.scores = score.sentiment(dstweet$text, pos.words, neg.words, .progress = 'text')
path<-"C:/Users/vyom/OneDrive/GitHub/"
write.csv(tweet.scores, file = paste(path, "TweetAnalysis.csv", sep = ""), row.names = TRUE)

#visualizing the tweets on a histogram
hist(tweet.scores$score, xlab = "Score of Tweets", col = brewer.pal(9,"Set3"), main = "Frequency of Tweets by Sentiment Score")
qplot(tweet.scores$score, xlab = "Score of Tweets")

#Wordcloud
wcld=read.csv("TweetReport.csv", stringsAsFactors = FALSE)
write.table(wcld$text,"wcld.txt", sep = "\t", row.names = FALSE)
txt<- readLines(file.choose())

k <- Corpus(VectorSource(txt))

k<-tm_map(k, content_transformer(tolower))
#k<-tm_map(k, PlainTextDocument)
k<-tm_map(k, removeNumbers)
k<-tm_map(k, stripWhitespace)
k<-tm_map(k, removePunctuation)
k<-tm_map(k, removeWords, stopwords('english'))

srchl<-tolower(srch)
nom<- sapply(gregexpr("\\W+", srch), length) + 1
for(i in 1:nom){
  k<-tm_map(k, removeWords, c(srch,srchl,"mmurraypolitics","bank","brush","says","can","fdic","hsbc","north","cant","without","free","book","pen","amp","https","via","just","ele","let","detail", word(srch,i,sep = fixed(" ")), word(srchl,i,sep = fixed(" "))))}

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
