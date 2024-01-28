# projects-in-R
Projects implemented in R programming language

### 1. Twitter Sentiment Analysis
The project was done as part of my BTech final semester project submission. The code essentially looks up user requested keywords on twitter using the twitter API and performs an analysis that gives an indication of what the sentiment around the topic is.

The code looked up 1000 tweets for 'UEFA Champions League', performed sentiment analysis on it using a positive and negative english lexicon file by comparing the tweets at a word level to assign a sentiment score (the greater the score, the more positive the sentiment, and vice versa). Along with that, there is also a word cloud output that showed the top things that people are talking about.

### 2. Query Scheduler
The project was about scheduling SQL queries stored in a googlesheet on MySQL workbench at a specified time.

The googlesheet stores all the SQL queries that need to be executed at a specified time during the day. The googlesheet API is used to pull the queries into the R console, a connection to MySQL workbench is established and the queries are executed one after the other.

The script is triggered to run at a specific time during the day using another script which acts as the scheduler.

### 3. Guardian News Topic Trends

Use the Guardian API to identify what is trending on the site globally related any specific topic
