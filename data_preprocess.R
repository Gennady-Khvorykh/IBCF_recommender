### This file contains scripts to explore and preprocess datasets for bulding
### recommender system application.

library(ggplot2)
library(data.table)
library(recommenderlab)

## Downloda data sets

# Download data set from Book-Krossing community into `data/` directory
download.file("http://www2.informatik.uni-freiburg.de/~cziegler/BX/BX-CSV-Dump.zip", "data/BX-CSV-Dump.zip")

# Unpack datasets
unzip("data/BX-CSV-Dump.zip", exdir = "data")

## Explore and preprocess data

# Load dataset with ratings
ratings <- fread("data/BX-Book-Ratings.csv") # 1,149,780 obs.
colnames(ratings) <- c("user", "book", "rating")
ratings <- ratings[, rating := as.numeric(rating)]

# Check the distribution of ratings
ggplot(ratings, aes(rating)) + stat_count() # all ratings
ggplot(ratings[rating != 0,], aes(rating)) + stat_count() # non-zeros

# Leave 1000 the most active users 
top <- ratings[, .N, by = user][order(N, decreasing = T),][1:1000]
ratings <- ratings[user %in% top$user,]

# Leave 200 the most often rated books
top <- ratings[, .N, by = book][order(N, decreasing = T),][1:200]
ratings <- ratings[book %in% top$book,] # 23344 obs.

# Load dataset with book description
books <- readr::read_delim("data/BX-Books.csv", ";", escape_double = FALSE)
nrow(books) # 271379

# Exclude 19 obs. read with problems
books <- books[-readr::problems(books)$row, ]

# Subset and save books
books <- books[books$ISBN %in% ratings$book, -c(6, 7)]
colnames(books) <- c("ISBN", "title", "author", "year", "publisher", "url")
saveRDS(books[, c("ISBN", "url")], "IBCF_recommender/books.RDS")

## Build model 

# Cast 'rating' from long into wide format and convert it into matrix
m <- reshape2::acast(ratings, user ~ book, value.var = "rating")

# Convert ratings.m into realRatingMatrix object
r <- as(m, "realRatingMatrix")

# Clean environment
rm(list = c("top", "m", "ratings", "books"))

# Binarize ratings with threshold 4
r <- binarize(r, minRating = 4)
r # 964 x 200 rating matrix with 6024 ratings.

# Save rating as ‘binaryRatingMatrix’
saveRDS(r, "IBCF_recommender/rating.RDS")

# Find out about the methods available for binary data
recommenderRegistry$get_entries(dataType = "binaryRatingMatrix")

# Train IBCF recommender model. 
model <- Recommender(r, method = "IBCF")
model

# Save model 
saveRDS(model, "IBCF_recommender/IBCF_model.RDS")




