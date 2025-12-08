## load data

# load resters and sort them
files_class <- list.files(
  path = dir,
  pattern = "GTYH_sieved\\.tif$",
  full.names = TRUE
) %>% sort()

if (length(files_class) < 2) stop("ERROR: Less than 2 rasters found. At least 2 needed for transition matrix!") else cat(paste0(length(files_class), " rasters loaded.", "\n"))

# extract year from raster file name
extract_year <- function(x) {
  m <- str_match(basename(x), "_(\\d{8})_")
  if (is.na(m[1,2])) NA_character_ else substr(m[1,2], 1, 4)
}
years <- vapply(files_class, extract_year, character(1))
if (any(is.na(years))) stop("For some files year identification failed!")

# create raster stack
r_stack <- terra::rast(files_class)
names(r_stack) <- years

# load polygon
site <- terra::vect(n2k)

# check CRS
if (crs(site) != crs(r_stack)){
  site <- project(site, crs(r_stack))
  cat("Vector reprojected to raster CRS.\n")
}

# crop rasters to N2k site
r_stack <- crop(r_stack, site, snap = "in", mask = T)

# message
message("Relevant croped rasters are stored in object 'r_stack'.")