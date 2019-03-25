library(openxlsx)
library(dplyr)

df_counts = read.xlsx("E:/412/Project 2/Final Project Data.xlsx", sheet=1)
df_location = read.xlsx("E:/412/Project 2/Final Project Data.xlsx", sheet=2)

df_temp = sub("^(\\d{2}).*$", "\\1", df_counts[,4])
df_temp = as.integer(df_temp)

df_helmet = df_counts[,18:19]
df_helmet = rowMeans(df_helmet)
df_helmet = data.frame(temp = df_temp, count = df_helmet, helmet = rep('helmet', length(df_helmet)))

df_no_helmet = df_counts[,20:21]
df_no_helmet = rowMeans(df_no_helmet)
df_no_helmet = data.frame(temp = df_temp, count = df_no_helmet, helmet = rep('no helmet', length(df_no_helmet)))

df = rbind(df_helmet, df_no_helmet)


df_sum = aggregate(df$count, by=list(Category=df$helmet, df$temp), FUN=sum)
write.csv(df_sum, file = "E:/412/Project 2/MyData.csv")