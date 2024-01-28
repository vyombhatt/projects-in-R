#Loading Libraries
library(googlesheets)
library(dplyr)
library(mailR)
library(stringr)
library(base)
library(taskscheduleR)
library(RMySQL)
library(keyring)

#Set directory location
setwd("C:/Users/vyom/OneDrive/GitHub/query-scheduler")

#Authorising Google to use my account via API
gs_auth()

#Registering the Analysis AU Redshift Query Scheduler Sheet as Google Sheet Object - for accessing via API
query_scheduler_sheet <- gs_url("https://docs.google.com/spreadsheets/d/1XEpy6yl5j29id49Q1Hepg8jIhDD6nj7yoYrHl3gFqiU/edit#gid=0")

#Reading the Main Sheet
query_scheduler <- query_scheduler_sheet %>%
  gs_read(ws = "Main")

#Deauthorising Google from using my account-Needed only if code runs on company server
gs_deauth()

#Changing the Date to Date Format
query_scheduler$Date <- as.Date(query_scheduler$Date, format = "%d/%m/%Y")

#Filtering to only have the Queries scheduled for Today
query_scheduler <- query_scheduler %>%
  filter(Date >= Sys.Date() - 1)
  
#Connecting to MySQL Workbench
mydb = dbConnect(MySQL(), user= key_get("mysql", "user"), password= key_get("mysql", "pwd"), 
                 host= key_get("mysql", "host"), port = 3306)

#Clean the data obtained from the googlesheet
abc<- subset(query_scheduler,select = c('Name', 'Query', 'Email-id', 'Email Report'))

#Converting the query data to lowercase
abc$Query <- tolower(abc$Query)

#Extracting select queries only
wxy<- as.data.frame(abc[grepl("^select", abc$Query),])

#Running Multiple Select Queries on MySQL
for (i in 1:length(wxy$Query)) {
  tryCatch({
    mydb = dbConnect(MySQL(), user= key_get("mysql", "user"), password= key_get("mysql", "pwd"), 
                     host= key_get("mysql", "host"), port = 3306)
    assign("A", (dbGetQuery(mydb, statement = wxy$Query[i])))
    write.csv(A, paste0("Select_Query_Output","_",i,"_",wxy$Name[i] ,".csv"), row.names = FALSE)
  },error=function(e){
  })}

#Extracting columns where analysts have requested email-report
dfs <- wxy %>%
  rename(email_report = `Email Report`) %>%
  filter(email_report == "Y")

#Sending the select query csv output to email-id
for (i in 1:length(dfs$Query)) {
    assign("file.loc", (paste0(getwd(),"/Select_Query_Output","_",i,"_",dfs$Name[i] ,".csv")))
    send.mail(from = key_get("email","id"),
            to = c(dfs$`Email-id`[i]),
            subject = "Select Query Output",
            body = "Please find your select query output attached",
            smtp = list(host.name = "smtp.gmail.com", port = 465,
                        ssl=TRUE, user.name = key_get("email","id"),
                        passwd = key_get("email","pwd")),
            attach.files = file.loc,
            authenticate = TRUE,
            send = TRUE)
}

#Extracting create table queries only
dfc<- as.data.frame(abc[grepl("^create", abc$Query),])


#Looping create table query with Try Catch
for (i in 1:length(dfc$Query)) {
  tryCatch({
    mydb = dbConnect(MySQL(), user= key_get("mysql", "user"), password= key_get("mysql", "pwd"), 
                     host= key_get("mysql", "host"), port = 3306)
    dbSendQuery(mydb, statement = dfc$Query[i])
  },error=function(e){
    })}

#Extracting columns where analysts have requested email-report
dat1 <- dfc %>%
  rename(email_report = `Email Report`) %>%
  filter(email_report == "Y" | is.na(email_report))

#Generating create table query output csv for those who requested Email Report
dat1$Query <- gsub("create table ", "", dat1$Query)
#dat1$Query<- gsub("\\s*\\([^\\)]+\\)","",as.character(dat1$Query))
dat1$Query <- gsub(".*as ", "", dat1$Query)

for(i in 1:length(dat1$Query)) {
    tryCatch({
        run_query <- paste0(dat1$Query[i])
        mydb = dbConnect(MySQL(), user= key_get("mysql", "user"), password= key_get("mysql", "pwd"), 
                         host= key_get("mysql", "host"), port = 3306)
        assign("B", (dbGetQuery(mydb, statement = run_query)))
        write.csv(B, paste0("CreateTable_Query_Output","_",i,"_",dat1$Name[i] ,".csv"), row.names = FALSE)
      },error=function(e){
  })}
  
#Sending the create table query csv output to email-id
for (i in 1:length(dat1$Query)) {
  assign("file.loc", (paste0(getwd(),"/CreateTable_Query_Output","_",i,"_",dat1$Name[i] ,".csv")))
  send.mail(from = key_get("email","id"),
          to = c(dat1$`Email-id`[i]),
          subject = "Create Table Query Output",
          body = paste0("Your table has been created with the name ", dat1$Query[i],"\nPlease find the attached result"),
          smtp = list(host.name = "smtp.gmail.com", port = 465,
                      ssl=TRUE, user.name = key_get("email","id"),
                      passwd = key_get("email","pwd")),
          attach.files = file.loc,
          authenticate = TRUE,
          send = TRUE)
}

#Closing Old Redshift connection
dbDisconnect(mydb)

