library(rio)

filelocation <- data.frame(location = getwd())

export(filelocation, "filelocation.csv")

