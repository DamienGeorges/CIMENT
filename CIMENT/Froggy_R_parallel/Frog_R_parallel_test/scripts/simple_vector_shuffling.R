##########################################################
## A Simple function to make parallel loop in R.
## Damien G. - 2014/10/28
##########################################################

## Description ###########################################
# This script has been made for purly illustrative 
# purposes. It is just a simple vector shuffling done 100 
# time in parallel. 
##########################################################


## get parameters given
## params are here :
## - a link to a file to shuffle (a numerical vector)
## - the number of randomisation you want to procced
## - the name of output .csv

## get all parameters
args <- commandArgs(trailingOnly=TRUE)
file_in <- as.character(args[1])
nb_rand <- as.numeric(args[2])
file_out <- as.character(args[3])

## read vector from input file
vect_in <- read.table(file_in)
vect_in <- as.numeric(vect_in) ## ensure vector format

## the function we want to run in parallel
shuffle_vector <- function( id, ## the id of the sampling 
                            v ## the vector to sample
){ 
  cat("\n> do", id, "e shuffling")
  return ( sample(v) ) 
}

## load packages and define parallel computation params
library(parallel)

## define the nuber of cores required
numWorkers <- detectCores(all.tests = FALSE, 
                          logical = FALSE) ## here number of available cores 
## is automatically recover
## but it can be done by hand 
## e.g. numWorkers <- 4
cat("nb of required cores = ", numWorkers)

## run the function in parallel
shuffle_vects <- mclapply( 1:nb_rand,
                           shuffle_vector,
                           v = vect_in,
                           mc.cores = numWorkers )

## because the output is a list it is sometimes usefull to convert results
## here we will stack all results in a numerical matrix
shuffle_vects  <- matrix( unlist(shuffle_vects ), 
                          nrow=nb_rand, 
                          byrow = T, 
                          dimnames = list( paste("rand_", 1:nb_rand, sep=""),
                                           NULL))

## here we have a matrix with 100 rows corresponding to our 100 shufling
head(shuffle_vects)

## save the produce matrix on hard drive
write.table(shuffle_vects, 
            file = file_out, 
            append = F, 
            row.names = TRUE, 
            col.names = FALSE)

## exit R properly
quit('no')
