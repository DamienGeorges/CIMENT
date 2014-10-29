---
title: "Little tutorial to run parallel R script on Froggy"
author: "Damien G. - damien.georges2@gmail.com"
date: "29/10/2014"
output:
  html_document:
    highlight: espresso
    number_sections: yes
    theme: readable
    toc: yes
---



# Before starting
The aim of this tutorial is to show how to set up and run a parallel loop over 16 cores on Froggy.
I suppose here that you have an active [PERSEUS](https://perseus.ujf-grenoble.fr/) account and you have already correctly set up all ssh connections to connect to Froggy cluster. If not please follow instructions given on [accessing to cluster](https://ciment.ujf-grenoble.fr/wiki/index.php/Accessing_to_clusters) CIMENT wiki page.

Because of the architecture of Froggy and the way that **R** parallel library is implemented, it is really easy to use all resources shared by a computing node (note: on Froggy, 1 node = 2 cpus = 16 cores). Build a script that intent to use more resources overcome the purpose of this tutorial. 

To make this example easy to follow and execute please download and uncompress the associated archive file : [Frog_R_parallel_test.zip](https://github.com/DamienGeorges/CIMENT/blob/master/CIMENT/Froggy_R_parallel/Frog_R_parallel_test.zip?raw=tru)



# A simple (and silly) R programme using a parallel loop
Here is a simple R script that execute a function X times in parallel. The function used here is just a vector shuffling but can be anything-else. Our script will take 3 arguments as input parameters (see below) and will produce a .txt file containing a matrix of randomized vectors as output. Here the code :

```r
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

```
This code is saved within [simple_vector_shuffling.R](scripts/simple_vector_shuffling.R)


# OAR instructions
Because Froggy is a collaborative cluster and to try to optimize resources consuming and sharing, it is **FORBIDDEN TO RUN JOBS DIRECTLY** on CIMENT clusters. All jobs have to be submitted via OAR, a queuing job software. Interested users can refer to CIMENT [OAR tutorial](https://ciment.ujf-grenoble.fr/wiki/index.php/OAR_tutorial) to benefit from all OAR functionalities.
OAR files are in fact bash scripts containing some OAR instructions. OAR instructions have to be declare after `#OAR ` flag. All common bash scripting command should be invoked.
Here is exposed a quite simple OAR script skeleton we will use to run our R script. This script is adapted to Froggy cluster. The full script is store in [simple_vector_shuffling.oar](scripts/simple_vector_shuffling.oar).

Here is described line by line our .oar file.

Because it is a bash file, the first line must be:
```bash
#!/bin/bash
```

Then come the OAR instructions.
```bash
#OAR -n simple_vector_shuffling_on_froggy
#OAR --project teembio
#OAR -l cpu=2,walltime=00:01:00
#OAR -O log_vector_shufling.%jobid%.stdout
#OAR -E log_vector_shufling.%jobid%.stderr
```
Here a brief description of this options meaning :

* `-n` : the name of oar campaign
* `--project` : the name of project you are belonging to
* `-l` : the required resources (here 2 cpus (i.e. 16 cores) during 1 minute)
* `-O` and `-E` : the name of log files produce by jobs. `-O` for console outputs and `-E` for console errors. This files will be useful in debugging code procedure.

**note** : An id will be associated to each oar job. The flag `%jobid%` is a wrapper to get this id.

**note** : If your job exceed the `walltime` it will be automatically killed. The `walltime` correspond to the maximal time all required cores are reserved.

Then we can defined some bash scripting options, make some prints,...
```bash
## define some bash options
set -e ## exit the script as soon as a function return an error

## make some prints
echo "running job is : ${0}"
hostname
echo
```

Finally, come the instructions for running our R script:

1. First we have to load CIMENT environment and all modules required
```bash
## load ciment environment and required modules
source /applis/ciment/v2/env.bash
module load R
```
2. Then we should ask Froggy to run our script with given parameters
```bash
## run our R script
R CMD BATCH "--args ${1} ${2} ${3}" simple_vector_shuffling.R /dev/stdout
```

The last line of the script is just to quit all properly.
```bash
## quit the script
exit $?
```

# Running the campain on Froggy
Now we have our R and our OAR scripts ready we just need to run the campaign.

We first have to copy all needed stuff (scripts, data, packages,...) on Froggy. It's a good habits to work in the `/scratch` directory instead than in `/home` one. Here I'm in a directory that contains the `Frog_R_parallel_test` directory where all what I need is stored (scripts and data).

```console
> scp -r Frog_R_parallel_test froggy:/scratch/dgeorges/
params_simple_vector_shuffling.txt            100%  123     0.1KB/s   00:00    
vet_in_2.txt                                  100%  400     0.4KB/s   00:00    
vet_in_1.txt                                  100%  292     0.3KB/s   00:00    
vet_in_3.txt                                  100%  400     0.4KB/s   00:00    
simple_vector_shuffling.R                     100% 2398     2.3KB/s   00:00    
simple_vector_shuffling.oar                   100%  607     0.6KB/s   00:00    
```

Then we have to log on Froggy
```console
> ssh froggy 
Last login: Mon Oct 27 17:57:39 2014 from killeen.ujf-grenoble.fr
                       _    _
                      (o)--(o)
                     /.______.\
                     \________/
                    ./        \.
                   ( .        , )
                    \ \_\\//_/ /
                     ~~  ~~  ~~ 
 _______  ______    _______  _______  _______  __   __ 
|       ||    _ |  |       ||       ||       ||  | |  |
|    ___||   | ||  |   _   ||    ___||    ___||  |_|  |
|   |___ |   |_||_ |  | |  ||   | __ |   | __ |       |
|    ___||    __  ||  |_|  ||   ||  ||   ||  ||_     _|
|   |    |   |  | ||       ||   |_| ||   |_| |  |   |  
|___|    |___|  |_||_______||_______||_______|  |___| 

            Welcome on "The Greedy Frog"

Useful commands:
 - chandler # (status of the cluster)
 - oarstat  # (current jobs list)
 - source /applis/site/env.bash # (load dev environment)
 - module avail # (list environment modules)
More help on https://ciment.ujf-grenoble.fr/wiki

You are on the "froggy1" frontend.

Quotas:
   /scratch: MB used: 163860 / 307200
   /home: MB used: 15975 / 50000
[dgeorges@froggy1 ~]$ 
```

Now we go on our `/scratch` working directory

```console
> cd /scratch/dgeorges/Frog_R_parallel_test/
```

Here we have to add execution permission of our .oar script.
```console
> chmod +x scripts/simple_vector_shuffling.oar
```

Then we just have to run our .oar script with `oarsub -S`

1. We can choose to run a single instance of the script giving to our script explicitly the parameters it needs ( here an input file / a number of randomization to do / a output file). Each param has to be separated by a blank space.
```console
> oarsub -S './scripts/simple_vector_shuffling.oar input_dat/vet_in_1.txt 100 vet_out_1.txt'
[ADMISSION RULE] Modify resource description with type constraints
[COMPUTE TYPE] Setting compute=YES
[ADMISSION RULE] Antifragmentation activated
[ADMISSION RULE] You requested 16 cores
[ADMISSION RULE] Antifrag converts query into /network_address=1
OAR_JOB_ID=4410502
```
We can access to campaign info via the `OAR_JOB_ID` and `oarstat -j` command:
```console
> oarstat -j 4410502
Job id    S User     Duration   System message
--------- - -------- ---------- ------------------------------------------------
4410502   T dgeorges 0:00:34    R=16,W=0:1:0,J=B,N=simple_vector_shuffling_on_froggy,P=teembio (Karma=0.484)
```
Here the statute `T` indicates that our campaign is over. We should ave a look at log files:

* .stderr file should be empty if no error occur
```console
> cat log_vector_shufling.4410502.stderr
```

* .stdout file should contains all R printed console outputs 
```console
> cat log_vector_shufling.4410502.stdout
```

If all goes smoothly we should have `vet_out_1.txt` (our script output) in our working directory.
```console
> ls
input_dat                           parameters
log_vector_shufling.4410502.stderr  scripts
log_vector_shufling.4410502.stdout  vet_out_1.txt
```

That works!!

2. The second way to run a campaign to construct a parameter file where each line contains parameters for one job. Here an example with the file [params_simple_vector_shuffling.txt](parameters/params_simple_vector_shuffling.txt). 
```console
> cat parameters/params_simple_vector_shuffling.txt
input_dat/vet_in_1.txt 100 vet_out_1.txt
input_dat/vet_in_2.txt 200 vet_out_2.txt
input_dat/vet_in_3.txt 150 vet_out_3.txt
```

Our job will be the executed several times with given different set of parameters. To do that we have to use `--array-param-file` flag.

```console
> oarsub -S ./scripts/simple_vector_shuffling.oar --array-param-file parameters/params_simple_vector_shuffling.txt
[ADMISSION RULE] Modify resource description with type constraints
[COMPUTE TYPE] Setting compute=YES
[ADMISSION RULE] Antifragmentation activated
[ADMISSION RULE] You requested 16 cores
[ADMISSION RULE] Antifrag converts query into /network_address=1
Simple array job submission is used
[TEST] 16 60 no comment
OAR_JOB_ID=4410513
OAR_JOB_ID=4410514
OAR_JOB_ID=4410515
OAR_ARRAY_ID=4410513
```

Here we see that our campaign as an id `OAR_ARRAY_ID` but also all individual jobs corresponding to different set of parameters `OAR_JOB_ID`. 

You should get info on each job as shown in previous point with `oarstat -j` or on the full campaign with `oarstat --array`
```console
> oarstat --array 4410513
Job id    A. id     index S User     Duration   System message
--------- --------- ----- - -------- ---------- --------------------------------
4410513   4410513   1     T dgeorges 0:26:04    R=16,W=0:1:0,J=B,N=simple_vector_shuffling_on_froggy,P=teembio (Karma=0.484)
4410514   4410513   2     T dgeorges 0:26:04    R=16,W=0:1:0,J=B,N=simple_vector_shuffling_on_froggy,P=teembio (Karma=0.484)
4410515   4410513   3     T dgeorges 0:25:50    R=16,W=0:1:0,J=B,N=simple_vector_shuffling_on_froggy,P=teembio (Karma=0.484)
```
We see that all job have been executed successfully :) .
So 2 log files and 1 output file by job have been produced.

```console
> ls
input_dat                           log_vector_shufling.4410515.stderr
log_vector_shufling.4410502.stderr  log_vector_shufling.4410515.stdout
log_vector_shufling.4410502.stdout  parameters
log_vector_shufling.4410513.stderr  scripts
log_vector_shufling.4410513.stdout  vet_out_1.txt
log_vector_shufling.4410514.stderr  vet_out_2.txt
log_vector_shufling.4410514.stdout  vet_out_3.txt
```

# Conclusion
Following this tutorial you should be able to run over 16 cores a simple function in R. Much more high quality documentation on OAR, Froggy, ... is available on [ciment wiki page](https://ciment.ujf-grenoble.fr/wiki/).. To be consulted without moderation.

# Feel free to contribute
Any comment, modification, improvement, ... on this document is more than welcome! Cheers.



