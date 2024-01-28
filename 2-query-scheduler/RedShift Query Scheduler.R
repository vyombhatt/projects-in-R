# Installing Task ScheduleR
#install.packages("bnosac/taskscheduleR")

#Loading Libraries needed
library(devtools)
library(taskscheduleR)
#library(miniUI)

#File to be scheduled
setwd("C:/Users/vyom/OneDrive/GitHub/query-scheduler")

rsqs <- paste0(getwd(),"/RedShift_Query_Fetcher.R")

#Schedule code to run at required time
taskcheduler_stop(taskname = "rsquery953")
taskscheduler_create(taskname = "rsquery953", 
                     rscript = rsqs, 
                     schedule = "ONCE", 
                     starttime = "15:39", 
                     startdate = format(Sys.Date , "%d/%m/%Y"))
