library(rio)

filelocation <- data.frame(location = getwd())

export(filelocation, "data/filelocation.csv")

