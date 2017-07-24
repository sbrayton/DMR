setwd("~/DropBox/NYU/02_Module/08_DMR/Assignment02")


library("rmarkdown", lib.loc="/Library/Frameworks/R.framework/Versions/3.3/Resources/library")
render("sb6000_assignment02.Rmd")

install.packages('RMySQL')

library("stringi")

d <- readLines(url("https://archive.ics.uci.edu/ml/machine-learning-databases/heart-disease/heart-disease.names"))


d <- d[127:235]

head(d,2)
tail(d,2)

stri_trim(d)

d[grep("26",d)]

i<-10
d[i]
d[grep(paste0("^",i),d)[1]]

sapply(1:76,function(i) d[grep(paste0("^",i),d) [i]] ) 

tgtLines <- sapply(1:76,function(i) print(d[i:5])) 


head(tgtLines,2)

t<- readLines(url("https://archive.ics.uci.edu/ml/machine-learning-databases/breast-cancer-wisconsin/breast-cancer-wisconsin.names"))

t<- t[106:116]

x<-t[grep("[ ]",t[1])]

x<-strsplit(t, " ")[[2]]
x[5]
t<-stri_trim(t)

x<-strsplit(t[1], " ")
x[[1:2]]


head(mydat[!complete.cases(mydat),],3)

library(readr)

u<- parse_integer(mydat$bare_nuclei,na="?")

mydat$bare_nuclei<-u

head(mydat[!complete.cases(mydat),],3)

noNA.mydat <- centralImputation(mydat) 

View(noNA.mydat)

nrow(mydat[!complete.cases(mydat),])

