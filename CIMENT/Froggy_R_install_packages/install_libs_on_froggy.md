---
title: "Grid tricks: install R packages on Froggy (and on all ciment clusters)"
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
Because no direct data downloading from web is allowed, because available R version is never the same than yours, because of the ( sometimes huge amount of ) dependencies required,... installing R packages on a cluster should rapidly become a nightmare. 
The aim of this tutorial is to expose some tricks to install R packages on Froggy. It should be also apply to any other cluster of CIMENT grid project.
I suppose here that you have an active [PERSEUS](https://perseus.ujf-grenoble.fr/) account and you have already correctly set up all ssh connections to connect to Froggy cluster. If not please follow instructions given on [accessing to cluster](https://ciment.ujf-grenoble.fr/wiki/index.php/Accessing_to_clusters) CIMENT wiki page.
We will take here the example of `biomod2` package installation which depends on around 10 packages that depends on others packages.. At the end you have to install 27 packages to benefit from all `biomod2` functionalities. 
You will just have to replace 'biomod2' by the names of packages you want to install.

# Operating mode description
Because we can't directly use the 'magic' `install.packages(<pkg>, dep=T)` command on Froggy (no connection to repository allowed), we will have to :
  1. detect all our package dependencies
  2. download package and dependencies sources file from repositories on your own machine
  3. transfer all packages sources on froggy
  4. install the package and all associated dependencies from sources on froggy
  5. check that all work!

So let's do it!

# Indentify and download packages and dependencies sources
Open your favorite R console interface on your own computer (local).
We start by installing `gtools` package if this package is not available on your machine.

```r
if(!require(gtools)){
  install.packages('ggtools', dep = TRUE)
}
```
Define the package you want to install on Froggy...

```r
pkgs <- "biomod2" ## should be a vector of packages names e.g pkgs <- c("ggplot2","raster","ade4")
```
Get packages dependencies...
```r
deps = NULL
for (pkg in pkgs){
  deps <- c(deps,
            gtools::getDependencies( pkgs = "biomod2",
                                     dependencies = c("Depends", "Imports", "LinkingTo"),
                                     installed=TRUE,
                                     available=TRUE,
                                     base=FALSE,
                                     recommended=FALSE ) )
}

(pkgs_and_deps <- c(deps, pkgs))
```
We will have packages to install to enable `biomod2` on Froggy. 
Download all packages sources files (independent of R version) in `froggy_libs_sources` directory.
```r
dir.create("froggy_libs_sources")
download.packages(pkgs = pkgs_and_deps, 
                  destdir = "froggy_libs_sources",
                  available = available.packages(),
                  repos = "http://cran.rstudio.com/",
                  type = "source")
```
Now we have download all required packages, we have to copy all resources on Froggy.

# Copy packages sources on froggy
To do that we simply use the `scp -r` command. Open a terminal and type something like:

```bash
scp -r froggy_libs_sources froggy:
```

The whole directory will be then copy in your home froggy directory.

# Install packages on froggy
First we have to log on Froggy
```bash
ssh froggy
```
Then check that the all packages sources have been copied.
```bash
ls froggy_libs_sources
```
We now just have to do the packages installation. We can't do it directly! We have to pass throw OAR queuing system, that's the rule! I strongly recommend you then to do that in interactive mode (much easier to debug). 

note : if your project karma is not good ;) you should invoke the `test` project and have a good chance to get resources rapidly.

So we will require 1 node for 30 minutes for the test project in interactive mode.
```bash
oarsub -I -l/core=1,walltime=00:30:00 --project test
```
As soon as you are connected on a computing node, load all required modules : 

  - the ciment environment  (source /applis/ciment/v2/env.bash)
  - latest version of R software (module load R)
  - computing tools needed to build R packages (module load gnu-devel)

and optionally some modules needed for spatial libraries :

  - gdal and proj (module load gdal / module load proj)

```bash
source /applis/ciment/v2/env.bash
module load R
module load gnu-devel
module load gdal
module load proj
```

Then type `R` to open a R interactive session.
```bash
R
```
In your Froggy's R console :
```bash
## define input and output dir
input_dir <- "froggy_libs_sources" ## dir where all packages sources are
output_dir <- "froggy_libs" ## dir where packages will be installed
dir.create(output_dir, showWarnings=FALSE)
.libPaths(output_dir) ## add output dir in loacation where R sreach for libraries

## get list of packages we want to install
pkgs_sources <- list.files(input_dir, full.names = T)

## define a obj that will check packages installation avancement
pkgs_ok <- rep(F, length(pkgs_sources))
names(pkgs_ok) <- pkgs_sources
nb_pkg_ok = -1

## install all packages
while(sum(pkgs_ok)>nb_pkg_ok ){
  nb_pkg_ok <- sum(pkgs_ok)
  for(pkg_s in pkgs_sources[!pkgs_ok]){
    cat("\n > installing :", pkg_s)
    ## try to install the package
    install.packages(pkg_s,  lib = "froggy_libs") 
    ## get pkg name from file name
    pkg_name <- pkg_s
    pkg_name <- sub("froggy_libs_sources","", pkg_name) ## remove path
    pkg_name <- sub("^/","", pkg_name) ## remove first / if remians
    pkg_name <- sub("_.*$","", pkg_name) ## remove version number info
    tt <- require(pkg_name, character.only = TRUE) ## test if package can be loaded
    if( tt ){
      pkgs_ok[pkg_s] <- TRUE
    }
  }
}

## test installation statut
if(all(pkgs_ok)){
  cat("\nCongratulation! you succeed in installing all packages!\n")
} else{
  cat("\nOups! The following packages are still not installed : \n", 
  paste(names(pkgs_ok)[!pkgs_ok], sep="\n"),
  "\nYou have to retry.. checking packages installation error message should be helpful to understand what
  is going wrong! Good Luck!\n")
}

```

( If you are lucky ;) ) the package you want to install should be now available on Froggy. Just make a try :
```r
library(biomod2) ## no error = ok !
```

# Use installed packages on froggy
We installed all packages in a local directory (here : `froggy_libs`). If you want to call your package in a R script,
you will have to give to R the path to this directory. The easiest way to do it is to add a `.libPaths(<local_lib_dir>)`
within your R script. Here that would be something like :
```r
.libPaths("~/froggy_libs")
library(biomod2) ## no error = ok !
```

# Conclusion
Following this tutorial you should be able install whatever R library on Froggy or any CIMENT cluster. Much more high quality documentation on OAR, Froggy, ... is available on [ciment wiki page](https://ciment.ujf-grenoble.fr/wiki/).. To be consulted without moderation.

# Feel free to contribute
Any comment, modification, improvement, ... on this document is more than welcome! Cheers.



