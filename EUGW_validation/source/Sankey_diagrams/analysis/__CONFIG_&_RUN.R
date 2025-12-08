# EUGW Senkey diagram and stability maps

# CONFIGURATION

dir <- "G:/Gedeelde drives/Team_BioDiv/5_Projecten/2024_Biodiversa_habitatpilot/WP2_3/EUGW/stability&senkey/data"
# replace with path to directory with EUGW rasters of your locality
# example: dir <- "../Milovice_Mlada/EUGW_data/"


n2k <- "G:/Gedeelde drives/Team_BioDiv/5_Projecten/2024_Biodiversa_habitatpilot/WP2_3/EUGW/SBZSemois/Marais de la Haute-Semois.gpkg"
# polygon which represents Natura 2000 site covered by EUGW product
# example: n2k <- "../Milovice_Mlada/N2k_Milovice.gpkg"


dir_out <- "G:/Gedeelde drives/Team_BioDiv/5_Projecten/2024_Biodiversa_habitatpilot/WP2_3/EUGW/stability&senkey/output"
# where should be output saved
# example: dir_out <- "OUT_Milovice_stability"

### plotting options for senkey diagram

min_count_for_nodes <- 100
# minimal number of pixels per grassland cathegory (within whole raster) to be plotted
# drops EUNIS level2 cathegories with infrquent prediction

min_count_for_links <- 100
# minimal number of pixels in transition between years to be plotted
# drop poor transitions between grassland types between years


## -- ## -- ## -- ## -- ## -- ##

# RUN

# sad abandoned part of code
#setwd()
if (!dir.exists(dir_out)) dir.create(dir_out, recursive = TRUE)

# load libraries
source("knihovnik.R")
knihovnik(terra, dplyr, stringr, tidyr, networkD3, htmlwidgets, htmltools)

# load data
source("load_data.R")

# classification stability maps
source("stability_maps.R")

# crate senkey diagram
source("senkey.R")
